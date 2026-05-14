module ChangeProvider
  module Forms
    class CheckAnswersForm
      include DfE::Wizard::Step

      delegate :application, :state_store, to: :wizard

      validate :new_provider_must_be_valid

      def new_provider
        return nil if state_store.provider_id.blank?

        @new_provider ||= available_providers.find { |provider| provider.id == state_store.provider_id.to_i }
      end

    private

      def available_providers
        @available_providers ||= LeadProvider
          .for(course: application.course)
          .alphabetical
          .reject { |provider| provider.id.in?(application.application_lead_providers.map(&:lead_provider_id)) }
      end

      def new_provider_must_be_valid
        if new_provider.nil?
          errors.add(:base, I18n.t("applications.change_provider.providers.form.invalid"))
        end
      end
    end
  end
end
