module Applications
  class Reject
    include ActiveModel::Model
    include ActiveModel::Attributes
    include Validations::StatusTransitionValidation

    REJECTION_REASONS = %w[
      registration-expired
      rejected-by-provider
      other-application-in-this-cohort-accepted
    ].freeze

    attribute :application
    attribute :reason

    validates :application, presence: true
    validates :reason, presence: true, inclusion: { in: REJECTION_REASONS }
    validate :application_already_accepted, if: -> { application }
    validate :application_already_rejected, if: -> { application }
    validate :application_rejectable, if: -> { application }

    def call
      return false unless valid?

      application.transition_status!(Application::REJECTED, reason:)

      send_provider_rejected_email if reason == "rejected-by-provider"

      true
    end

    def send_provider_rejected_email
      GenericMailer.with(
        to: application.user.email,
        full_name: application.user.full_name,
        provider_name: application.lead_provider.name,
        course_name: application.course.title_embedded_course_name,
        cohort_date: application.cohort.name,
        sign_in_link: Rails.configuration.sign_in_link,
        ecf_id: application.ecf_id,
      ).provider_rejected.deliver_later
    end

  private

    def application_already_accepted
      errors.add(:application, :has_already_been_accepted) if application.has_been_accepted?
    end

    def application_already_rejected
      errors.add(:application, :has_already_been_rejected) if application.rejected_status?
    end

    def application_rejectable
      return if errors.any?

      validate_status_transition(
        application:,
        to: Application::REJECTED,
        error: :not_rejectable,
      )
      errors.add(:application, :not_rejectable) if errors.blank? && application.invalid?
    end
  end
end
