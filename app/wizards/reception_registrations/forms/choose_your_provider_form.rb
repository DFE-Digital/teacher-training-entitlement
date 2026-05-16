module ReceptionRegistrations
  module Forms
    class ChooseYourProviderForm < StepForm
      attribute :lead_provider_id, :string

      validates :lead_provider_id, presence: true
      validate :validate_lead_provider_exists, unless: -> { lead_provider_id.blank? || not_chosen_provider? }

      delegate :state_store, to: :wizard

      def not_chosen?
        lead_provider_id == not_chosen_option
      end

      def not_chosen_option
        @not_chosen_option ||= "not_chosen".freeze
      end

      def lead_providers
        @lead_providers ||= LeadProvider.for(course: state_store.course).alphabetical
      end

      def lead_provider
        @lead_provider ||= lead_providers.find_by(id: lead_provider_id)
      end

      def not_chosen_provider?
        lead_provider_id == not_chosen_option
      end

      def self.permitted_params
        %i[lead_provider_id]
      end

    private

      def validate_lead_provider_exists
        if lead_provider.blank?
          errors.add(:lead_provider_id, :invalid)
        end
      end
    end
  end
end
