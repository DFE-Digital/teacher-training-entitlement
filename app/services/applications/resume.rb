# frozen_string_literal: true

module Applications
  class Resume
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :application
    attribute :course_cohort

    validates :application, presence: true
    validates :course_cohort, presence: true
    validate :not_already_active, if: -> { application }
    validate :incompatible_course, if: -> { application && course_cohort }
    validate :cohort_not_in_training, if: -> { course_cohort }

    def call
      return if invalid?

      application.application_states.create!
      application.update!(training_status: "active", course_cohort:)
    end

  private

    def not_already_active
      add_error(:base, :already_active) if application.active_training_status?
    end

    def incompatible_course
      return if course_cohort.course == application.course

      add_error(:application, :incompatible_schedule)
    end

    def cohort_not_in_training
      return if course_cohort.schedule.training_live?

      add_error(:base, :cohort_not_in_training)
    end

    def add_error(group, key)
      message = I18n.t("activemodel.errors.models.applications/resume.attributes.#{group}.#{key}")
      errors.add(group, message)
    end
  end
end
