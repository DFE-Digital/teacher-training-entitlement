module ChangeProvider
  module Forms
    class ChooseProviderForm
      include DfE::Wizard::Step

      attribute :provider_id, :integer

      validates :provider_id,
                presence: { message: I18n.t("applications.change_provider.providers.form.blank") }
      validate :different_provider
      validate :provider_is_available

      delegate :application, to: :wizard

      def different_provider
        if provider_id == application.lead_provider.id
          errors.add(:provider_id, I18n.t("applications.change_provider.providers.form.different_provider"))
        end
      end

      def providers
        @providers ||= LeadProvider
          .for(course: application.course)
          .alphabetical
          .reject { |p| p.id.in?(application.application_lead_providers.map(&:lead_provider_id)) }
      end

      def self.permitted_params
        %i[provider_id]
      end

    private

      def provider_is_available
        return if provider_id.blank?
        return if provider_id == application.lead_provider.id
        return if providers.map(&:id).include?(provider_id)

        errors.add(:provider_id, I18n.t("applications.change_provider.providers.form.invalid"))
      end
    end
  end
end
