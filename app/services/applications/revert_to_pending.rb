module Applications
  class RevertToPending
    REVERTABLE_DECLARATION_STATES = %w[voided ineligible awaiting_clawback clawed_back].freeze

    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :change_status_to_pending
    attribute :application
    attribute :admin_user
    delegate :status, to: :application

    validates :change_status_to_pending, inclusion: { in: %w[yes no] }
    validates :status, inclusion: { in: [Application::ACCEPTED, Application::REJECTED] }, if: :application
    validates :application, presence: true
    validates :admin_user, presence: true
    validate :application_has_no_unremoveable_declarations, if: :application

    def revert
      return true if change_status_to_pending == "no"
      return false if invalid?

      Application.transaction do
        application.update_columns(status: Application::PENDING, funded_place: nil)
        application.application_events.create!(
          event: ApplicationEvent::STATE_CHANGE_EVENTS[Application::PENDING],
          lead_provider: application.lead_provider,
          metadata: { reason: "reverted_to_pending" },
        )
      end

      true
    end

  private

    def application_has_no_unremoveable_declarations
      if application.declarations.where.not(state: REVERTABLE_DECLARATION_STATES).any?
        errors.add :base, :pending_unremoveable_declarations
      end
    end
  end
end
