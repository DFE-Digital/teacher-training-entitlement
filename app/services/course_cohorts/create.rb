# frozen_string_literal: true

module CourseCohorts
  class Create
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :cohort
    attribute :course_id
    attribute :course_cohort
    attribute :training_starts_at, :datetime
    attribute :training_ends_at, :datetime
    attribute :lead_providers

    validates :cohort, presence: true
    validate :course_present
    validates :training_starts_at, presence: true
    validates :lead_providers, presence: true

    def call
      return if invalid?

      term_identifier = CourseCohort.school_term(training_starts_at)
      academic_year = cohort.start_year
      course_cohort = cohort.course_cohorts.create!(course:, academic_year:, term_identifier:)

      # add milestones
      course_cohort.milestones.started.create!(acceptance_window_start_date: training_starts_at)
      course_cohort.milestones.completed.create!(acceptance_window_end_date: training_ends_at) if training_ends_at

      # add lead_provider
      lead_providers.each do |lead_provider|
        course_cohort.course_cohort_providers.create(lead_provider:)

        # add delivery partners
      end
    end

    def course
      @course ||= Course.find(course_id)
    end

  private

    def course_present
      errors.add(:missing_course) unless course
    end
  end
end
