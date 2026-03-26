module Applications
  module ChangeProvider
    class ProvidersForm
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :application
      attribute :provider_id, :integer

      validates :provider_id,
                presence: { message: I18n.t("applications.change_provider.providers.form.blank") }
      validate :different_provider

      def different_provider
        if provider_id == application.lead_provider.id
          errors.add(:provider_id, I18n.t("applications.change_provider.providers.form.different_provider"))
        end
      end
    end
  end
end
