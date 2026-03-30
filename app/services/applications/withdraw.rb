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
      quality-of-programme-structure-not-suitable.
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
      other
    ].freeze

    validate :not_withdrawn
    validate :not_missing_reason
    validate :has_started_declarations
    validate :has_declarations

    def initialize(application:, reason:, admin_user: nil)
      @application = application
      @reason = reason
      @admin_user = admin_user
    end

    def call
      return if invalid?

      Application.transaction do
        @application.application_states.create!(status: Application::WITHDRAWN,
                                                reason: @reason)
        @application.status = Application::WITHDRAWN
        @application.save!(validate: @admin_user.nil?)
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

    def has_started_declarations
      add_error(:base, :no_started_declarations) unless @application.declarations.any?(&:started_declaration_type?)
    end

    def has_declarations
      add_error(:base, :no_declarations) if @application.declarations.none?
    end

    def add_error(group, key)
      message = I18n.t("activemodel.errors.models.applications/withdraw.attributes.#{group}.#{key}")
      errors.add(group, message)
    end
  end
end
