module Courses
  class Create
    include ActiveModel::Model

    attr_reader :course

    def initialize(state_store:)
      @state_store = state_store
    end

    def call
      Course.transaction do
        create_course!
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

    def course_details
      @course_details ||= state_store.course_details
    end
  end
end
