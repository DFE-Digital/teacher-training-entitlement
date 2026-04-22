# frozen_string_literal: true

module Applications
  class Withdraw
    include ActiveModel::Model
    include ActiveModel::Validations

    WITHDRAWAL_REASONS = %w[
      insufficient-capacity-to-undertake-programme
      personal-reason-health-or-pregnancy-related
      personal-reason-moving-school
      personal-reason-other
      insufficient-capacity
      change-in-developmental-or-personal-priorities
      change-in-school-circumstances
      change-in-school-leadership
      quality-of-programme-structure-not-suitable
      quality-of-programme-content-not-suitable
      quality-of-programme-facilitation-not-effective
      quality-of-programme-accessibility
      quality-of-programme-other
      programme-not-appropriate-for-role-and-cpd-needs
      started-in-error
      expected-commitment-unclear
      assessment-requirements-not-met
      change-in-career
      disengaged-and-unresponsive
      non-payment-of-invoice
      deferred-for-over-12-months
      other
    ].freeze

    validate :not_withdrawn
    validate :not_missing_reason
    validate :application_withdrawable, if: -> { application }

    attr_reader :application

    def initialize(application:, reason:, admin_user: nil)
      @application = application
      @application.admin_user = admin_user
      @reason = reason
    end

    def call
      return if invalid?

      Application.transaction do
        @application.state_changes.create!(
          event: Application::WITHDRAWN,
          metadata: { reason: @reason },
        )
        @application.withdrawn_status!
      end
    end

  private

    def not_missing_reason
      return if WITHDRAWAL_REASONS.include?(@reason)

      add_error(:reason, :missing_reason)
    end

    def not_withdrawn
      add_error(:base, :already_withdrawn) if @application.withdrawn_status?
    end

    def application_withdrawable
      old_status = @application.status
      @application.status = Application::WITHDRAWN
      errors.add(:application, :not_withdrawable) if @application.invalid?
      @application.status = old_status
    end

    def add_error(group, key)
      message = I18n.t("activemodel.errors.models.applications/withdraw.attributes.#{group}.#{key}")
      errors.add(group, message)
    end
  end
end
