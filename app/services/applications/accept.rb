# frozen_string_literal: true

module Applications
  class Accept
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :application
    attribute :funded_place

    validates :application, presence: true
    validates :funded_place, inclusion: { in: [true, false], if: :validate_funded_place? }
    validate :not_already_accepted
    validate :cannot_change_from_rejected
    validate :eligible_for_funded_place

    def accept
      return false unless valid?

      ApplicationRecord.transaction do
        accept_application!
        create_application_state!
      end

      application.reload

      true
    end

  private

    delegate :cohort, :user, :lead_provider, to: :application

    def not_already_accepted
      return if application.blank?

      errors.add(:application, :has_already_been_accepted) if application.accepted_lead_provider_approval_status?
    end

    def cannot_change_from_rejected
      return if application.blank?

      errors.add(:application, :cannot_change_from_rejected) if application.rejected_lead_provider_approval_status?
    end

    def accept_application!
      opts = {
        lead_provider_approval_status: "accepted",
        accepted_at: Time.zone.now,
        training_status: :active,
      }

      if cohort.funding_cap?
        opts[:funded_place] = funded_place
      end

      application.update!(opts)
    end

    def eligible_for_funded_place
      return if errors.any?
      return unless cohort.funding_cap?

      if funded_place && !application.eligible_for_funding
        errors.add(:application, :not_eligible_for_funded_place)
      end
    end

    def validate_funded_place?
      errors.blank? && cohort.funding_cap?
    end

    def create_application_state!
      ApplicationState.create!(
        application:,
        lead_provider:,
        state: "active",
      )
    end
  end
end
