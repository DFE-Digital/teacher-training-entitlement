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
      course_cohorts = CourseCohort.registrable.order(:training_starts_at).to_a
      closest_option = course_cohorts[0..0].map do |course_cohort|
        build_option_struct(
          value: course_cohort.ecf_id,
          label: course_cohort.cohort.name,
          link_errors: true,
          hint: "You can also select this option if you've already started",
        )
      end

      future_options = course_cohorts[1..].map do |course_cohort|
        build_option_struct(
          value: course_cohort.ecf_id,
          label: course_cohort.cohort.name,
        )
      end
      later_date_option = [build_option_struct(value: "later", label: "I want to start at a later date")]

      closest_option + future_options + later_date_option
    end

    def requirements_met?
      query_store.current_user
    end

    def after_save
      wizard.store["course_cohort_ecf_id"] = course_start_date
    end

    def next_step
      if course_start_date == "later"
        wizard.current_user.update!(notify_user_for_future_reg: true)
        :cannot_register_yet
      else
        wizard.current_user.update!(notify_user_for_future_reg: false)
        :choose_your_provider
      end
    end

    def previous_step
      :start
    end

    def application_course_start_date
      @application_course_start_date ||= query_store.course_cohort&.name || "Registration closed"
    end
  end
end
