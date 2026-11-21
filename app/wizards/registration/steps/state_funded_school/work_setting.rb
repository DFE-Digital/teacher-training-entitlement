module Registration
  module Steps
    module StateFundedSchool
      class WorkSetting
        include Base

        # Answers that only make sense for the work setting they were given for.
        CLEARED_ANSWERS = { funding: nil, institution_id: nil }.freeze

        attribute :work_setting

        validates :work_setting, presence: true, inclusion: { in: Institution::ALL_SETTINGS }

        def self.permitted_params
          %i[work_setting]
        end

        # Changing the work setting clears the school and funding choice answers.
        def serializable_data
          super.merge(CLEARED_ANSWERS.stringify_keys)
        end

        def questions
          [
            QuestionTypes::RadioButtonGroup.new(
              name: :work_setting,
              options:,
              style_options: {
                hint: { text: I18n.t("helpers.hint.registration_wizard.work_setting").html_safe },
                width: "three-quarters",
              },
            ),
          ]
        end

        def options
          [
            option(Institution::STATE_FUNDED_INSTITUTION, link_errors: true),
            option(Institution::PRIVATE_INSTITUTION),
            option(Institution::OTHER, divider: true),
          ]
        end

      private

        def option(value, **attrs)
          QuestionTypes::RadioOption.new(
            value:,
            label: I18n.t(value, scope: "helpers.label.registration_wizard.work_setting_options"),
            **attrs,
          )
        end
      end
    end
  end
end
