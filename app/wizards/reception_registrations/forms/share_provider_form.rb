module ReceptionRegistrations
  module Forms
    class ShareProviderForm < StepForm
      attribute :can_share_choices, :string
      validates :can_share_choices, acceptance: true

      def self.permitted_params
        %i[can_share_choices]
      end
    end
  end
end
