# frozen_string_literal: true

module Applications
  class ChangeCohort
    include ActiveModel::Validations

    validate :declarations_present
    validate :different_cohort
    validate :new_course_cohort

    def initialize(application:, new_cohort:, override_declarations_check: false)
      @application = application
      @new_cohort = new_cohort
      @override_declarations_check = override_declarations_check
    end

    def call
      return if invalid?

      @application.update!(course_cohort:)
    end

    def course_cohort
      @course_cohort ||= CourseCohort.find_by(cohort: @new_cohort, course: @application.course)
    end

  private

    def different_cohort
      add_error(:base, :must_be_different) if @new_cohort.id == @application.cohort.id
    end

    def declarations_present
      return if @override_declarations_check

      add_error(:base, :declarations_present) if @application.declarations.any?
    end

    def new_course_cohort
      return if course_cohort

      add_error(:course_cohort, :not_found)
    end

    def add_error(group, key)
      message = I18n.t("activemodel.errors.models.applications/change_cohort.attributes.#{group}.#{key}")
      errors.add(group, message)
    end
  end
end
