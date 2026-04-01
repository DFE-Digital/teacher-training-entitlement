module Admin
  module Applications
    class ChangeStatusForm
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :id, :integer
      attribute :status, :string
      attribute :reason, :string

      REASON_OPTIONS = {
        ::Application::DEFERRED => ::Applications::Defer::DEFERRAL_REASONS,
        ::Application::WITHDRAWN => ::Applications::Withdraw::WITHDRAWAL_REASONS,
      }.freeze

      OPTIONS = [Application::ACCEPTED, Application::DEFERRED, Application::WITHDRAWN].freeze

      validates :status, inclusion: { in: Application::STATUSES, message: "Choose a valid status" }
      validates :reason, inclusion: { in: :valid_reasons, message: "Choose a valid reason for the status change" }, if: :reason_required?
      validate :ensure_status_is_changing

      def ensure_status_is_changing
        if status.to_s == application&.status.to_s
          errors.add(:status, :unchanged)
        end
      end

      def status_options
        OPTIONS.without(application&.status)
      end

      def reason_options
        REASON_OPTIONS
      end

      def valid_reasons
        reason_options[status] || []
      end

      def reason_required?
        status.present? && status != ::Application::ACCEPTED
      end

      def application
        @application ||= Application.find(id)
      end
    end
  end
end
