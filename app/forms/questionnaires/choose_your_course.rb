module Questionnaires
  class ChooseYourCourse < Base
    include Helpers::Institution

    QUESTION_NAME = :course_identifier

    attr_accessor QUESTION_NAME

    # Disabled these validations as we only have one course which is
    # automatically assigned
    # validates QUESTION_NAME, presence: true
    # validate :validate_course_exists

    def self.permitted_params
      [QUESTION_NAME]
    end

    def questions
      [
        QuestionTypes::RadioButtonGroup.new(
          name: :course_identifier,
          options:,
          style_options: { legend: { size: "m", tag: "h2" } },
        ),
      ]
    end

    def options
      divider_index = courses.length - 1 # Place the "Or" divider before the last course
      courses
        .each_with_index.map do |course, index|
          build_option_struct(
            value: course.identifier,
            link_errors: index.zero?,
            divider: divider_index == index,
            label: I18n.t("course.name.#{course.identifier}", default: course.name),
          )
        end
    end

    def after_save
      wizard.store["course_identifier"] = "tte-early-years"
    end

    def next_step
      :choose_your_provider
    end

    def previous_step
      :course_start_date
    end

    def course
      # Early years auto-selected because we only have 1 course at this point
      course_identifier = "tte-early-years"
      Course.find_by(identifier: course_identifier)
    end

  private

    def courses
      # Course.where(display: true).order(:position)
      # Early years auto-selected because we only have 1 course at this point
      Course.none
    end

    def validate_course_exists
      if course.blank?
        errors.add(:course_identifier, :invalid)
      end
    end
  end
end
