# frozen_string_literal: true

module Applications
  class Resume
    include ActiveModel::Model
    include ActiveModel::Validations
    include Validations::StatusTransitionValidation

    attr_reader :application

    validate :application_status
    validate :incompatible_course
    validate :cohort_not_in_training
    validate :cohort_exists
    validate :application_resumable

    def initialize(application:, course_cohort:, admin_user: nil)
      @application = application
      @application.admin_user = admin_user
      @course_cohort = course_cohort
      @admin_user = admin_user
    end

    def call
      return if invalid?

      @application.transition_status!(Application::STARTED, course_cohort: @course_cohort)
    end

  private

    def application_status
      return if @application.deferred_status?

      add_error(:base, :application_status)
    end

    def incompatible_course
      return if @course_cohort.nil? || @course_cohort.course == @application.course

      add_error(:base, :incompatible_schedule)
    end

    def cohort_not_in_training
      return if @course_cohort.nil? || @course_cohort.schedule.training_live?

      add_error(:base, :cohort_not_in_training)
    end

    def application_resumable
      return if errors.any?

      validate_status_transition(
        application: @application,
        to: Application::STARTED,
        error: :not_resumable,
      )
    end

    def cohort_exists
      return if @course_cohort

      add_error(:base, :cohort_missing)
    end

    def add_error(group, key)
      message = I18n.t("activemodel.errors.models.applications/resume.attributes.#{group}.#{key}")
      errors.add(group, message)
    end
  end
end
