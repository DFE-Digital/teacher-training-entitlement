module Questionnaires
  class CourseStartDate < Base
    class Form < QuestionTypes::RadioButtonGroup
      def type
        "radio_button_group"
      end

      def question_text
        "When do you want to start the course?"
      end
    end

    include ApplicationHelper

    QUESTION_NAME = :course_start_date

    attr_accessor QUESTION_NAME

    validates QUESTION_NAME, presence: true

    def self.permitted_params
      [QUESTION_NAME]
    end

    def questions
      [
        Form.new(
          name: :course_start_date,
          options:,
          style_options: { legend: { size: "m", tag: "h2" } },
        ),
      ]
    end

    def options
      [
        build_option_struct(
          value: "yes",
          label: application_course_start_date,
          link_errors: true,
          hint: "You can also select this option if you've already started",
        ),
        build_option_struct(value: "later", label: "I want to start at a later date"),
      ]
    end

    def requirements_met?
      query_store.current_user
    end

    def next_step
      if course_start_date == "yes"
        wizard.store["course_start"] = application_course_start_date
        wizard.current_user.update!(notify_user_for_future_reg: false)
        :choose_your_provider
      else
        wizard.current_user.update!(notify_user_for_future_reg: true)
        :cannot_register_yet
      end
    end

    def previous_step
      :start
    end

    def application_course_start_date
      @application_course_start_date ||= query_store.cohort&.name || "Registration closed"
    end
  end
end
