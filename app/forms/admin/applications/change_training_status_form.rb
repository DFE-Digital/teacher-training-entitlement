module Admin
  module Applications
    class ChangeTrainingStatusForm
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :id, :integer
      attribute :training_status, :string
      attribute :reason, :string

      REASON_OPTIONS = {
        ::Applications::Strategy::DEFERRED => ::Applications::Defer::DEFERRAL_REASONS,
        ::Applications::Strategy::WITHDRAWN => ::Applications::Withdraw::WITHDRAWAL_REASONS,
      }.freeze

      validates :training_status, inclusion: { in: Application.training_statuses.values, message: "Choose a valid training status" }
      validates :reason, inclusion: { in: :valid_reasons, message: "Choose a valid reason for the training status change" }, if: :reason_required?
      validate :ensure_training_status_is_changing

      def ensure_training_status_is_changing
        if training_status.to_s == application&.training_status.to_s
          errors.add(:training_status, :unchanged)
        end
      end

      def training_status_options
        Application.training_statuses.values.without(application&.training_status)
      end

      def reason_options
        REASON_OPTIONS
      end

      def valid_reasons
        reason_options[training_status] || []
      end

      def reason_required?
        training_status.present? && training_status != ::Applications::Strategy::ACTIVE
      end

      def application
        @application ||= Application.find(id)
      end
    end
  end
end
