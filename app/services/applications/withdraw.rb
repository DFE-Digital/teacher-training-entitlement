# frozen_string_literal: true

module Applications
  class Withdraw
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :application
    attribute :reason

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

    validates :reason, inclusion: { in: WITHDRAWAL_REASONS, message: :missing_reason }, allow_blank: false
    validate :not_withdrawn
    validate :has_started_declarations
    validate :has_declarations

    def call
      return if invalid?

      ApplicationRecord.transaction do
        application.application_states.create!(state: :withdrawn, reason:)
        application.withdrawn_training_status!
      end

      true
    end

  private

    def not_withdrawn
      add_error(:base, :already_withdrawn) if application.withdrawn_training_status?
    end

    def has_started_declarations
      add_error(:base, :no_started_declarations) unless application.declarations.any?(&:started_declaration_type?)
    end

    def has_declarations
      add_error(:base, :no_declarations) if application.declarations.none?
    end

    def add_error(group, key)
      message = I18n.t("activemodel.errors.models.applications/withdraw.attributes.#{group}.#{key}")
      errors.add(group, message)
    end
  end
end
