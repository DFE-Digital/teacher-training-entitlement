module ReceptionRegistrations
  module Forms
    class WorkSettingForm < StepForm
      SCHOOL_SETTINGS = [
        A_SCHOOL = "a_school".freeze,
        AN_ACADEMY_TRUST = "an_academy_trust".freeze,
        A_16_TO_19_EDUCATIONAL_SETTING = "a_16_to_19_educational_setting".freeze,
      ].freeze

      CHILDCARE_SETTINGS = [
        EARLY_YEARS_OR_CHILDCARE = "early_years_or_childcare".freeze,
      ].freeze

      ANOTHER_SETTING_SETTINGS = [
        ANOTHER_SETTING = "another_setting".freeze,
      ].freeze

      OTHER_SETTINGS = [
        OTHER = "other".freeze,
      ].freeze

      attribute :work_setting, :string

      validates_presence_of :work_setting

      def work_settings_options
        [
          EARLY_YEARS_OR_CHILDCARE,
          A_SCHOOL,
          A_16_TO_19_EDUCATIONAL_SETTING,
          OTHER,
        ]
      end

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

      def self.permitted_params
        %i[work_setting]
      end
    end
  end
end
