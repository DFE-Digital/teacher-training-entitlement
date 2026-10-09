module Questionnaires
  class WorkSetting < Base
    attr_accessor :work_setting

    validates :work_setting, presence: true, inclusion: { in: Institution::ALL_SETTINGS }

    def self.permitted_params
      %i[work_setting]
    end

    def after_save
      wizard.store.delete("funding")
      wizard.store.delete("institution_id")
    end

    def requirements_met?
      true
    end

    def return_to_regular_flow_on_change?
      true
    end

    def next_step
      state_funded_instition? ? :choose_school : :ineligible_for_funding
    end

    def previous_step
      :teacher_catchment
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
        build_option_struct(value: Institution::STATE_FUNDED_INSTITUTION, link_errors: true),
        build_option_struct(value: Institution::PRIVATE_INSTITUTION),
        build_option_struct(value: Institution::OTHER, divider: true),
      ]
    end

  private

    def state_funded_instition?
      work_setting == Institution::STATE_FUNDED_INSTITUTION
    end

    def private_institution?
      work_setting == Institution::PRIVATE_INSTITUTION
    end

    def other?
      work_setting == Institution::OTHER
    end
  end
end
