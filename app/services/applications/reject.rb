module Applications
  class Reject
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :application
    attribute :reason_for_rejection

    validates :application, presence: true
    validates :reason_for_rejection, presence: true
    validate :application_already_accepted, if: -> { application }
    validate :application_already_rejected, if: -> { application }
    validate :application_rejectable, if: -> { application }

    def reject
      return false unless valid?

      application.update!(status: Application::REJECTED, reason_for_rejection:)
      application.reload

      true
    end

  private

    def application_already_accepted
      errors.add(:application, :has_already_been_accepted) if application.has_been_accepted?
    end

    def application_already_rejected
      errors.add(:application, :has_already_been_rejected) if application.rejected_status?
    end

    def application_rejectable
      old_status = application.status
      application.status = Application::REJECTED
      errors.add(:application, :not_rejectable) if application.invalid?
      application.status = old_status
    end
  end
end
