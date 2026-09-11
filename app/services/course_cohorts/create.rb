# frozen_string_literal: true

module CourseCohorts
  class Create
    include ActiveModel::Model

    validates :cohort, presence: true
    validates :course, presence: true

    attr_reader :course_cohort, :cohort, :course, :training_dates

    def initialize(cohort:, course:, training_dates:)
      @cohort = cohort
      @course = course
      @training_dates = training_dates
    end

    def call
      return if invalid?

      training_starts_at = training_dates[:start]
      training_ends_at = training_dates[:end]

      CourseCohort.transaction do
        @course_cohort = cohort.course_cohorts.find_or_create_by!(course:)

        create_milestones!(training_starts_at:, training_ends_at:)
        preload_delivery_partners

        contract_years.each do |contract_year|
          lead_provider = contract_year.lead_provider

          course_cohort_provider = @course_cohort.course_cohort_providers.find_or_initialize_by(lead_provider:)
          course_cohort_provider.assign_attributes(
            lead_provider:,
            teacher_funding: contract_year.teacher_funding,
            recruitment_target: contract_year.recruitment_target,
          )
          course_cohort_provider.save!

          lead_provider.delivery_partners.each do |delivery_partner|
            @course_cohort.delivery_partnerships.find_or_create_by!(
              lead_provider:,
              delivery_partner:,
            )
          end
        end
      end
    end

  private

    def contract_years
      @contract_years ||= @course.contract_years.includes(:lead_provider).generic
    end

    def preload_delivery_partners
      ActiveRecord::Associations::Preloader.new(
        records: contract_years.map(&:lead_provider),
        associations: :delivery_partners,
      ).call
    end

    def create_milestones!(training_starts_at:, training_ends_at:)
      course.milestones.each do |milestone_template|
        milestone = @course_cohort.milestones.find_or_initialize_by(declaration_type: milestone_template.declaration_type)
        milestone.assign_attributes(milestone_attributes(milestone_template, training_starts_at:, training_ends_at:))
        milestone.save!
      end
    end

    def milestone_attributes(milestone_template, training_starts_at:, training_ends_at:)
      attributes = {
        declaration_type: milestone_template.declaration_type,
        payment_amount: milestone_template.payment_amount,
        acceptance_window_start_date: training_starts_at,
      }

      if milestone_template.declaration_type == Milestone::COMPLETED && training_ends_at
        attributes.merge!(
          acceptance_window_start_date: training_ends_at - 2.months,
          acceptance_window_end_date: training_ends_at,
        )
      end

      attributes
    end
  end
end
