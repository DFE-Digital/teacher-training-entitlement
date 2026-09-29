module Applications
  class RevertToPending
    include ActiveModel::Model
    include Validations::StatusTransitionValidation

    attr_reader :application, :admin_user

    def initialize(application:, admin_user: nil)
      @application = application
      @application.admin_user = admin_user if admin_user && @application
      @admin_user = admin_user
    end

    validates :application, presence: true
    validate :application_revertable, if: -> { application }
    validate :application_can_transition_to_pending, if: -> { application }
    validate :application_has_no_unremoveable_declarations, if: :application

    def call = revert

    def status
      application&.status
    end

    def revert
      return false if invalid?

      application.transition_status!(Application::PENDING, reason:, funded_place: nil)
      application.reload

      true
    end

  private

    def reason
      if @admin_user
        "Admin #{@admin_user.email} reverted application"
      else
        "Reverted by lead provider API call"
      end
    end

    def application_revertable
      return if application.accepted_status?
      return if admin_user && application.rejected_status?

      errors.add(:status, :inclusion)
    end

    def application_can_transition_to_pending
      return if errors.any?

      validate_status_transition(
        application:,
        to: Application::PENDING,
        error: :invalid_status_transition,
        attribute: :status,
      )
    end

    def application_has_no_unremoveable_declarations
      if application.declarations.where.not(state: Declaration::REVERTABLE_STATES).any?
        errors.add :base, :pending_unremoveable_declarations
      end
    end
  end
end
