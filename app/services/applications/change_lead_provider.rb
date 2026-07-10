module Applications
  class ChangeLeadProvider
    include ActiveModel::Model
    include ActiveModel::Validations

    validate :application_can_change_provider
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
        @application.change_provider!(to: @new_provider)
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

        if @application.previous_provider.email
          GenericMailer.with(
            to: @application.previous_provider.email,
            provider_name: @application.previous_provider.name,
            course_name: @application.course.name,
            participant_trn: @application.user.trn,
            particitpant_name: @application.user.full_name,
            change_date: @application.previous_application_lead_provider&.updated_at&.to_fs(:govuk_short),
            ecf_id: @application.ecf_id,
          ).previous_provider.deliver_later
        end
      end
    end

  private

    def reason
      "Changed lead provider from #{@old_provider.name} to #{@new_provider.name}"
    end

    def application_can_change_provider
      return if @application.can_change_provider?

      errors.add(:application, :application_cannot_change_provider)
    end

    def new_provider_is_different
      if @application.lead_provider == @new_provider
        errors.add(:base, :provider_must_be_different)
      end
    end
  end
end
