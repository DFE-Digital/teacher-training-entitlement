module Applications
  class ChangeLeadProvider
    include ActiveModel::Model
    include ActiveModel::Validations
    include Validations::ApplicationNotSuperceded

    validate :application_status_is_pending

    def initialize(current_application:, new_provider:)
      @current_application = current_application
      @new_provider = new_provider
      @superceded_application = @current_application.dup
    end

    def call
      return unless valid?

      Application.transaction do
        @current_application.update!(lead_provider: @new_provider)

        @superceded_application.update!(
          status: Application::SUPERCEDED,
          ecf_id: @current_application.ecf_id,
          superceding_application: @current_application,
        )

        Rails.logger.info "!!!!!!!!!!!!!!!!!! @superceded_application: #{@superceded_application.id}"

        @current_application.application_states.create!(
          status: Application::SUPERCEDED,
          reason:,
        )
      end
    end

  private

    def application
      @current_application
    end

    def application_status_is_pending
      return if @current_application.pending_status?

      errors.add(:application, :application_must_be_pending_status)
    end

    def reason
      "Changed lead provider from #{@current_application.lead_provider.name} to #{@new_provider.name}"
    end
  end
end
