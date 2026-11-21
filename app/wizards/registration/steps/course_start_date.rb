module Registration
  module Steps
    class CourseStartDate
      include Base

      LATER = "later".freeze

      class Question < QuestionTypes::RadioButtonGroup
        def type
          "radio_button_group"
        end

        def question_text
          "When do you want to start a course?"
        end
      end

      attribute :course_start_date

      validates :course_start_date, presence: true
      validates :course_start_date, inclusion: { in: ->(step) { step.permitted_values } }, allow_blank: true

      def self.permitted_params
        %i[course_start_date]
      end

      def questions
        [
          Question.new(
            name: :course_start_date,
            options:,
            style_options: { legend: { size: "m", tag: "h2" } },
          ),
        ]
      end

      def options
        course_options = course_cohorts.each_with_index.map do |course_cohort, index|
          QuestionTypes::RadioOption.new(
            value: course_cohort.ecf_id,
            label: course_cohort.cohort.name,
            hint: started_hint(course_cohort),
            link_errors: index.zero? || nil,
          )
        end

        course_options + [QuestionTypes::RadioOption.new(value: LATER, label: "I want to start at a later date")]
      end

      def permitted_values
        course_cohorts.map(&:ecf_id) + [LATER]
      end

    private

      def course_cohorts
        @course_cohorts ||= state_store.registerable_course_cohorts
      end

      def started_hint(course_cohort)
        return unless course_cohort.training_starts_at&.before?(Time.zone.today)

        I18n.t("helpers.hint.registration_wizard.course_start_date_already_started")
      end
    end
  end
end
