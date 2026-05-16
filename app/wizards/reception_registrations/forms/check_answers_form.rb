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
               :kind_of_nursery,
               :funding,
               :public_nursery?,
               :selected_institution,
               to: :state_store

      def answers
        array = [

          build_answer("Course start", course_start, :"course-start-date"),
          build_answer("Course", I18n.t(course.identifier, scope: "course.name"), :"choose-your-course"),
          build_answer("Provider", lead_provider.name, :choose_your_provider),
          build_answer("Workplace in England", teacher_catchment == "england" ? "Yes" : "No", :"teacher-catchment"),
          build_answer("Work setting", I18n.t(work_setting, scope: "helpers.label.registration_wizard.work_setting_options"), :"work-setting"),
        ]

        if public_nursery?
          array << build_answer("Nursery", I18n.t(kind_of_nursery, scope: "helpers.label.registration_wizard.kind_of_nursery_options"), :"kind-of-nursery")
        end

        array << build_answer("Workplace", selected_institution&.name_with_address, :"choose-school")

        if funding.present?
          array << build_answer("Course funding", I18n.t(funding, scope: "helpers.label.registration_wizard.funding_options"), :"funding-your-course")
        end

        array
      end

      def self.permitted_params
        []
      end

    private

      def build_answer(key, value, step)
        Struct.new(:key, :value, :step).new(key, value, step)
      end
    end
  end
end
