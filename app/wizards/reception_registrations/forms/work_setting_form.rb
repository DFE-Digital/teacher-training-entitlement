module ReceptionRegistrations
  module Forms
    class WorkSettingForm < StepForm
      attribute :work_setting, :string

      validates :work_setting, presence: true, inclusion: { in: Institution::ALL_SETTINGS }

      def work_settings_options
        [
          Institution::STATE_FUNDED_INSTITUTION,
          Institution::PRIVATE_INSTITUTION,
          Institution::OTHER,
        ]
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

      def self.permitted_params
        %i[work_setting]
      end
    end
  end
end
