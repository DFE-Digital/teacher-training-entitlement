module Registration
  module Steps
    module StateFundedSchool
      class TeacherCatchment
        include Base

        OPTIONS = [
          ENGLAND = Institution::ENGLAND_SUBDIVISION_CODE,
          NOT_ENGLAND = Institution::OTHER,
        ].freeze

        attribute :teacher_catchment

        validates :teacher_catchment, presence: true, inclusion: { in: OPTIONS }

        def self.permitted_params
          %i[teacher_catchment]
        end

        def questions
          [
            QuestionTypes::RadioButtonGroup.new(
              name: :teacher_catchment,
              options: [
                QuestionTypes::RadioOption.new(value: ENGLAND, label: "Yes", link_errors: true),
                QuestionTypes::RadioOption.new(value: NOT_ENGLAND, label: "No"),
              ],
            ),
          ]
        end
      end
    end
  end
end
