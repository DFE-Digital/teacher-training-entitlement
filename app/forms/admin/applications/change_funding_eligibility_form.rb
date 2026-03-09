# frozen_string_literal: true

module Admin
  module Applications
    class ChangeFundingEligibilityForm
      include ActiveModel::Model
      include ActiveModel::Attributes

      OPTIONS = {
        true => I18n.t("shared.yes"),
        false => I18n.t("shared.no"),
      }.freeze

      attribute :application
      attribute :eligible_for_funding, :boolean

      validates :eligible_for_funding, inclusion: OPTIONS.keys
      validates_presence_of :application
      validate :flag_changed

      def eligible_for_funding_options
        OPTIONS
      end

    private

      def flag_changed
        if application && application.eligible_for_funding == eligible_for_funding
          errors.add(:eligible_for_funding, :unchanged)
        end
      end
    end
  end
end
