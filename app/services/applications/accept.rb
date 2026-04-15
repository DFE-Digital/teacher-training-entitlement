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

    def call
      return false unless valid?

      ApplicationRecord.transaction do
        accept_application!
        create_application_event!
      end

      application.reload

      true
    end

  private

    delegate :cohort, :user, :lead_provider, to: :application

    def not_already_accepted
      return if application.blank?

      errors.add(:application, :has_already_been_accepted) if application.accepted_status?
    end

    def cannot_change_from_rejected
      return if application.blank?

      errors.add(:application, :cannot_change_from_rejected) if application.rejected_status?
    end

    def accept_application!
      opts = {
        status: Application::ACCEPTED,
        accepted_at: Time.zone.now,
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

    def create_application_event!
      application.state_changes.create!(
        event: Application::ACCEPTED,
        lead_provider:,
      )
    end
  end
end
