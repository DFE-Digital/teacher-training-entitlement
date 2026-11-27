module Registrations
  module Steps
    module ExcellenceInReception
      class CourseStartDate < Shared::RadioButtons
        with_title "Course start"
        with_attribute :course_cohort_ecf_id
        with_answer_display_name "Course start"
        REQUIRED_ANSWER_MESSAGE = "Choose your course start date".freeze

        attribute ATTRIBUTE, :string
        validates ATTRIBUTE, presence: { message: REQUIRED_ANSWER_MESSAGE }

        def self.permitted_params = [ATTRIBUTE]

        def answer_options
          course_cohorts = wizard.course.course_cohorts.registerable
                                   .includes(:cohort)
                                   .order(:training_starts_at).to_a

          options = course_cohorts[1..].map do |course_cohort|
            {
              value: course_cohort.ecf_id,
              name: course_cohort.cohort.name,
            }
          end
          options << {
            value: "later",
            name: "I want to start at a later date",
          }

          options
        end

        def after_update
          options = answer_options
          selected_option = options.find { |option| option[:value].to_s == course_cohort_ecf_id.to_s }
          store_display_value(selected_option&.dig(:name))
        end

      private

        def store_display_value(display_value)
          state = wizard.state_store.read
          display_values = state["_display_values"] || {}
          display_values.delete(ATTRIBUTE.to_s)
          if display_value.present? && display_value.to_s != course_cohort_ecf_id.to_s
            display_values[ATTRIBUTE.to_s] = { course_cohort_ecf_id.to_s => display_value }
          end
          state["_display_values"] = display_values
          state.delete("_display_values") if display_values.empty?
          wizard.state_store.clear
          wizard.state_store.write(state)
        end
      end
    end
  end
end
