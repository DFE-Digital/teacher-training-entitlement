module Questionnaires
  class WorkSetting < Base
    attr_accessor :work_setting

    validates :work_setting, presence: true, inclusion: { in: Institution::ALL_SETTINGS }

    def self.permitted_params
      %i[work_setting]
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
            hint: { text: I18n.t("helpers.hint.registration_wizard.work_setting") },
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

    def build_option_struct(**kwargs)
      super(**kwargs.deep_merge(label: { size: "s" }))
    end

    def private_instition?
      work_setting == Institution::PRIVATE_INSTITUTION
    end

    def state_funded_instition?
      work_setting == Institution::STATE_FUNDED_INSTITUTION
    end

    def other?
      work_setting == Institution::OTHER
    end
  end
end
