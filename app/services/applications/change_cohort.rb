# frozen_string_literal: true

module Applications
  class ChangeCohort
    include ActiveModel::Validations

    validate :declarations_present
    validate :different_cohort
    validate :schedule_exists_in_new_cohort

    def initialize(application:, new_cohort:, override_declarations_check: false)
      @application = application
      @new_cohort = new_cohort
      @override_declarations_check = override_declarations_check
    end

    def call
      return if invalid?

      if @application.schedule.present?
        @application.update!(cohort: @new_cohort, schedule: new_schedule)
      else
        @application.update!(cohort: @new_cohort)
      end
    end

  private

    def different_cohort
      add_error(:base, :must_be_different) if @new_cohort.id == @application.cohort.id
    end

    def schedule_exists_in_new_cohort
      return unless @application.schedule

      add_error(:base, :schedule_not_found) unless @new_cohort.schedules.exists?(course_group: @application.course.course_group, identifier: @application.schedule.identifier)
    end

    def declarations_present
      return if @override_declarations_check

      add_error(:base, :declarations_present) if @application.declarations.any?
    end

    def new_schedule
      Schedule.find_by(
        course_group: @application.course.course_group,
        cohort_id: @new_cohort.id,
        identifier: @application.schedule.identifier,
      )
    end

    def add_error(group, key)
      message = I18n.t("activemodel.errors.models.applications/change_cohort.attributes.#{group}.#{key}")
      errors.add(group, message)
    end
  end
end
