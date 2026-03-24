module Applications
  module ChangeProvider
    class StartForm
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :application
      attribute :confirmation, :boolean

      validates :confirmation,
                inclusion: { in: [true, false],
                             message: I18n.t("applications.change_provider.start.form.blank") }

      validate :change_provider_allowed

    private

      def change_provider_allowed
        return if application.can_change_provider?

        errors.add(:cannot_change_provider, I18n.t("applications.change_provider.start.form.cannot_change_provider"))
      end
    end
  end
end
