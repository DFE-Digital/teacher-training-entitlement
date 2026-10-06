module Admin
  module Applications
    class RevertToPendingForm
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :application
      attribute :change_status_to_pending, :string

      validates :change_status_to_pending, inclusion: { in: %w[yes] }

      def status
        application&.status
      end
    end
  end
end
