# frozen_string_literal: true

module Applications
  class Resume
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_reader :application

    validate :not_already_started
    validate :not_already_accepted
    validate :incompatible_course
    validate :cohort_not_in_training
    validate :cohort_exists
    validate :application_resumable

    attr_reader :application

    def initialize(application:, course_cohort:, admin_user: nil)
      @application = application
      @application.admin_user = admin_user
      @course_cohort = course_cohort
      @admin_user = admin_user
    end

    def call
      return if invalid?

      Application.transaction do
        @application.state_changes.create!(
          event: Application::STARTED,
          metadata: { reason: @reason }.compact,
        )
        @application.update!(status: Application::STARTED,
                             course_cohort: @course_cohort)
      end
    end

  private

    def not_already_started
      add_error(:base, :already_started) if @application.started_status?
    end

    def not_already_accepted
      add_error(:base, :already_accepted) if @application.accepted_status?
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
      old_status = @application.status
      @application.status = Application::STARTED
      errors.add(:application, :not_resumable) if @application.invalid?
      @application.status = old_status
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
