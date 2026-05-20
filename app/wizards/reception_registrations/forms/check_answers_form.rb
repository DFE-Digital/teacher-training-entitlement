module ReceptionRegistrations
  module Forms
    class CheckAnswersForm
      include DfE::Wizard::Step

      delegate :state_store, to: :wizard
      delegate :course_start,
               :lead_provider,
               :course,
               :work_setting,
               :teacher_catchment,
               :funding,
               :selected_institution,
               to: :state_store

      def answers
        array = [

          build_answer("Course start", course_start, :"course-start-date"),
          build_answer("Course", I18n.t(course.identifier, scope: "course.name")),
          build_answer("Provider", lead_provider.name, :choose_your_provider),
          build_answer("Workplace in England", teacher_catchment == "england" ? "Yes" : "No", :"teacher-catchment"),
          build_answer("Work setting", I18n.t(work_setting, scope: "helpers.label.registration_wizard.work_setting_options"), :"work-setting"),
        ]

        array << build_answer("Workplace", selected_institution&.name_with_address, :"choose-school") if selected_institution

        if funding.present?
          array << build_answer("Course funding", I18n.t(funding, scope: "helpers.label.registration_wizard.funding_options"), :"funding-your-course")
        end

        array
      end

      def self.permitted_params
        []
      end

    private

      def build_answer(key, value, step = nil)
        Struct.new(:key, :value, :step).new(key, value, step)
      end
    end
  end
end
