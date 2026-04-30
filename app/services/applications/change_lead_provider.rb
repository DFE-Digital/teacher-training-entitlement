module Applications
  class ChangeLeadProvider
    include ActiveModel::Model
    include ActiveModel::Validations

    validate :application_status_is_pending
    validate :not_previously_changed_to_provider
    validate :new_provider_is_different

    attr_reader :application

    def initialize(application:, new_provider:)
      @application = application
      @new_provider = new_provider
      @old_provider = application.lead_provider
    end

    def call
      return unless valid?

      Application.transaction do
        @application.update!(lead_provider: @new_provider)
        @application.application_events.create!(
          event: :changed_provider,
          metadata: { reason: }.compact,
        )

        GenericMailer.with(
          to: @application.user.email,
          full_name: @application.user.full_name,
          provider_name: @new_provider.name,
          course_name: @application.course.name,
          cohort_date: @application.cohort.name,
          ecf_id: @application.ecf_id,
          sign_in_link: Rails.configuration.sign_in_link,
          feedback_link: Rails.configuration.feedback_link,
        ).change_provider.deliver_later
      end
    end

  private

    def reason
      "Changed lead provider from #{@old_provider.name} to #{@new_provider.name}"
    end

    def application_status_is_pending
      return if @application.pending_status?

      errors.add(:application, :application_must_be_pending_status)
    end

    def not_previously_changed_to_provider
      if @application.application_lead_providers.pluck(:lead_provider_id).include?(@new_provider.id)
        errors.add(:base, :previously_changed_to_provider)
      end
    end

    def new_provider_is_different
      if @application.lead_provider == @new_provider
        errors.add(:base, :provider_must_be_different)
      end
    end
  end
end
