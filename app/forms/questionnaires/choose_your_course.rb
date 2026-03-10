module Questionnaires
  class ChooseYourCourse < Base
    def initialize(*args)
      # Remove this once we have more than one course, but for now we want to default to the TTE Early Years course as it's the only one available
      self.course_identifier = "tte-early-years"
      super
    end

    QUESTION_NAME = :course_identifier

    attr_accessor QUESTION_NAME

    validates QUESTION_NAME, presence: true
    validate :validate_course_exists

    def self.permitted_params
      [QUESTION_NAME]
    end

    def questions
      # When we have more than one course, this should be changed to a RadioButtonGroup
      [
        QuestionTypes::HiddenField.new(name: :course_identifier),
      ]
      # [
      #   QuestionTypes::RadioButtonGroup.new(
      #     name: :course_identifier,
      #     options:,
      #     style_options: { legend: { size: "m", tag: "h2" } },
      #   ),
      # ]
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
      wizard.store["course_identifier"] = course_identifier
    end

    def next_step
      :choose_your_provider
    end

    def previous_step
      :course_start_date
    end

    def course
      @course ||= Course.find_by(identifier: course_identifier)
    end

  private

    def courses
      @courses ||= Course.displayable
    end

    def validate_course_exists
      if course.blank?
        errors.add(:course_identifier, :invalid)
      end
    end
  end
end
