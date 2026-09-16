# frozen_string_literal: true

module CourseCohorts
  class Create
    include ActiveModel::Model

    validates :cohort, presence: true
    validates :course, presence: true

    attr_reader :course_cohort, :cohort, :course, :lead_providers, :training_starts_at

    def initialize(cohort:, course:, lead_providers:, training_starts_at:)
      @cohort = cohort
      @course = course
      @lead_providers = lead_providers
      @training_starts_at = training_starts_at
    end

    def call
      return if invalid?

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

  private

    def months_between(start_date, end_date)
      (end_date.year * 12 + end_date.month) - (start_date.year * 12 + start_date.month)
    end
  end
end
