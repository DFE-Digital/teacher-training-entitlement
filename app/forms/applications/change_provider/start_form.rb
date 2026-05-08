module Applications
  module ChangeProvider
    class StartForm
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :application
      attribute :confirmation, :boolean

      validates :confirmation,
                inclusion: { in: [true, false],
                             message: ->(form, _data) { form.send(:confirmation_blank_message) } }

      validate :change_provider_allowed

    private

      def change_provider_allowed
        return if application.can_change_provider?

        errors.add(:cannot_change_provider, I18n.t("applications.change_provider.start.form.cannot_change_provider"))
      end

      def confirmation_blank_message
        I18n.t(
          "applications.change_provider.start.application_#{application.status}.form.blank",
          default: I18n.t("applications.change_provider.start.form.blank"),
        )
      end
    end
  end
end
