module Questionnaires
  class WorkSetting < Base
    A_SCHOOL = "a_school".freeze
    AN_ACADEMY_TRUST = "an_academy_trust".freeze
    A_16_TO_19_EDUCATIONAL_SETTING = "a_16_to_19_educational_setting".freeze

    SCHOOL_SETTINGS = [
      A_SCHOOL,
      AN_ACADEMY_TRUST,
      A_16_TO_19_EDUCATIONAL_SETTING,
    ].freeze

    CHILDCARE_SETTINGS = %w[
      early_years_or_childcare
    ].freeze

    ANOTHER_SETTING_SETTINGS = %w[
      another_setting
    ].freeze

    OTHER_SETTINGS = %w[
      other
    ].freeze

    ALL_SETTINGS = [SCHOOL_SETTINGS, CHILDCARE_SETTINGS, ANOTHER_SETTING_SETTINGS, OTHER_SETTINGS].flatten

    attr_accessor :work_setting

    validates :work_setting, presence: true, inclusion: { in: Institution::ALL_SETTINGS }

    def self.permitted_params
      %i[work_setting]
    end

    def after_save
      if other?
        wizard.store.delete("funding")
        wizard.store.delete("institution_id")
        return
      end

      return if state_funded_instition? || private_institution?

      # we are inferring `works_in_school` and `works_in_childcare` to maintain
      # consistency with older records

      case work_setting
      when *SCHOOL_SETTINGS
        wizard.store["works_in_school"] = "yes"
        wizard.store["works_in_childcare"] = "no"

        %w[kind_of_nursery has_ofsted_urn institution_id].each { |field| wizard.store.delete(field) }
      when *CHILDCARE_SETTINGS
        wizard.store["works_in_childcare"] = "yes"
        wizard.store["works_in_school"] = "no"

        wizard.store.delete("institution_id")
      when *OTHER_SETTINGS, *ANOTHER_SETTING_SETTINGS
        wizard.store["works_in_school"] = "no"
        wizard.store["works_in_childcare"] = "no"

        %w[funding kind_of_nursery has_ofsted_urn institution_id].each do |field|
          wizard.store.delete(field)
        end
      else
        raise(ArgumentError, "invalid work setting #{work_setting}")
      end
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

    def works_in_school?
      SCHOOL_SETTINGS.include?(work_setting)
    end

    def works_in_childcare?
      CHILDCARE_SETTINGS.include?(work_setting)
    end

    def works_in_another_setting?
      ANOTHER_SETTING_SETTINGS.include?(work_setting)
    end

    def works_in_other?
      OTHER_SETTINGS.include?(work_setting)
    end

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
