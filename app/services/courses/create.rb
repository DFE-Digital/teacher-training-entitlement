# frozen_string_literal: true

module Courses
  class Create
    include ActiveModel::Model

    attr_reader :course, :course_cohort, :cohort

    def initialize(state_store:)
      @state_store = state_store
    end

    def call
      Course.transaction do
        create_course!
        find_or_create_cohort!
        create_course_cohort!
        create_generic_contract_years!
        create_contract_financials!
      end
    rescue ActiveRecord::RecordInvalid => e
      errors.add(:base, "#{e.record.class.model_name.human}: #{e.record.errors.full_messages.to_sentence}")
    end

  private

    attr_reader :state_store

    def create_course!
      @course = Course.create!(
        name: course_details.name,
        identifier: course_details.identifier,
        short_code: course_details.short_code,
        course_group: course_details.course_group,
        description: course_details.description,
      )
    end

    def create_course_cohort!
      course_cohort_service = CourseCohorts::Create.new(
        cohort:,
        course:,
        lead_providers: lead_provider_contracts,
        training_dates: {
          start: Time.zone.today,
          end: Time.zone.today,
        },
        milestone_types: state_store.milestone_types,
      )

      course_cohort_service.call

      if course_cohort_service.errors.any?
        errors.copy!(course_cohort_service.errors)
        raise ActiveRecord::Rollback
      end

      @course_cohort = course_cohort_service.course_cohort
    end

    def lead_provider_contracts
      state_store.selected_lead_providers.each_with_object({}) do |selected_provider, contracts|
        contract_financial = selected_contract_financial_for(selected_provider.lead_provider)

        contracts[selected_provider.lead_provider] = {
          "teacher_funding" => contract_financial&.teacher_funding,
          "recruitment_target" => contract_financial&.recruitment_target,
        }
      end
    end

    def create_contract_financials!
      state_store.selected_contract_financials.each do |contract_financial|
        contract_year = ContractYear.find_or_initialize_by(
          lead_provider: contract_financial.lead_provider,
          course:,
          academic_year: contract_financial.academic_year.presence,
        )
        contract_year.assign_attributes(
          teacher_funding: contract_financial.teacher_funding.presence,
          recruitment_target: contract_financial.recruitment_target.presence,
        )
        contract_year.save!
      end
    end

    def create_generic_contract_years!
      state_store.selected_lead_providers.each do |selected_provider|
        contract_year = ContractYear.find_or_initialize_by(
          lead_provider: selected_provider.lead_provider,
          course:,
          academic_year: nil,
        )
        contract_year.assign_attributes(
          course_url: selected_provider.url.presence,
          email: selected_provider.email.presence,
        )
        contract_year.save!
      end
    end

    def find_or_create_cohort!
      registration_starts_at = Time.zone.today
      registration_ends_at = Time.zone.today

      @cohort = Cohort.find_or_create_by!(identifier: registration_starts_at.strftime("%Y-%B")) do |cohort|
        cohort.registration_starts_at = registration_starts_at
        cohort.registration_ends_at = registration_ends_at
        cohort.funding_cap = true
      end
    end

    def selected_contract_financial_for(lead_provider)
      state_store.selected_contract_financials.find do |contract_financial|
        contract_financial.lead_provider == lead_provider
      end
    end

    def selected_lead_provider_for(lead_provider)
      state_store.selected_lead_providers.find do |selected_lead_provider|
        selected_lead_provider.lead_provider == lead_provider
      end
    end

    def course_details
      state_store.course_details
    end
  end
end
