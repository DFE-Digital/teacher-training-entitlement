module Registration
  module Steps
    module StateFundedSchool
      class TeacherCatchment
        include Base

        OPTIONS = [
          ENGLAND = Institution::ENGLAND_SUBDIVISION_CODE,
          NOT_ENGLAND = Institution::OTHER,
        ].freeze

        # Answers that depend on the catchment: they are asked again after a change.
        CLEARED_ANSWERS = { work_setting: nil, institution_id: nil, funding: nil }.freeze

        attribute :teacher_catchment

        validates :teacher_catchment, presence: true, inclusion: { in: OPTIONS }

        def self.permitted_params
          %i[teacher_catchment]
        end

        # Keeping the same answer keeps the answers that depend on it.
        def serializable_data
          return super if state_store.read[:teacher_catchment] == teacher_catchment

          super.merge(CLEARED_ANSWERS.stringify_keys)
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
