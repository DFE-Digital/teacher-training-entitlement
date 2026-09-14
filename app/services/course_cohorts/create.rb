# frozen_string_literal: true

module CourseCohorts
  class Create
    include ActiveModel::Model

    validates :cohort, presence: true
    validates :course, presence: true

    attr_reader :course_cohort, :cohort, :course, :lead_providers, :training_dates

    def initialize(cohort:, course:, lead_providers:, training_dates:)
      @cohort = cohort
      @course = course
      @lead_providers = lead_providers
      @training_dates = training_dates
    end

    def call
      return if invalid?

      training_starts_at = training_dates[:start]
      training_ends_at = training_dates[:end]
      term_identifier = CourseCohort.school_term(training_starts_at)
      academic_year = cohort.start_year

      CourseCohort.transaction do
        @course_cohort = cohort.course_cohorts.create!(
          course:,
          academic_year:,
          term_identifier:,
          training_starts_at:,
        )

        course.milestones.started.find_or_create_by!(declaration_type: Milestone::STARTED) do |milestone|
          milestone.acceptance_window_start_offset = 0
        end

        if training_ends_at
          course.milestones.completed.find_or_create_by!(declaration_type: Milestone::COMPLETED) do |milestone|
            milestone.acceptance_window_start_offset = (training_ends_at - 2.months - training_starts_at).to_i
            milestone.acceptance_window_end_offset = (training_ends_at - training_starts_at).to_i
          end
        end

        lead_providers.each do |lead_provider, contract|
          @course_cohort.course_cohort_providers.create!(
            lead_provider:,
            teacher_funding: contract["teacher_funding"].presence,
            recruitment_target: contract["recruitment_target"].presence,
          )

          lead_provider.delivery_partners.each do |delivery_partner|
            @course_cohort.delivery_partnerships.create!(
              lead_provider:,
              delivery_partner:,
            )
          end
        end
      end
    end
  end
end
