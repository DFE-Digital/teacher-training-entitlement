# frozen_string_literal: true

module Declarations
  class Clawback
    include ActiveModel::Model
    include ActiveModel::Validations
    include Applications::Validations::StatusTransitionValidation

    def initialize(declaration:)
      @declaration = declaration
      @application = declaration.application
    end

    validate :declaration_not_clawbacked
    validate :declaration_is_paid
    validate :application_status_not_completed
    validate :application_updateable

    def call
      return unless valid?

      ApplicationRecord.transaction do
        @declaration.clawback!
        ParticipantOutcomes::Void.new(declaration: @declaration).void_outcome

        if @declaration.started_declaration_type?
          @application.transition_status!(Application::ACCEPTED, reason: "started declaration voided")
        elsif @declaration.completed_declaration_type?
          @application.transition_status!(Application::STARTED, reason: "completed declaration voided")
        end
      end
    end

  private

    def application_status_not_completed
      if @declaration.started_declaration_type? && @application.completed_status?

        errors.add(:base, :application_status_completed)
      end
    end

    def declaration_not_clawbacked
      return if @declaration.clawback_declaration.nil?

      errors.add(:base, :not_already_refunded)
    end

    def declaration_is_paid
      return if errors.any? || @declaration.paid_state?

      errors.add(:base, :must_be_paid)
    end

    def application_updateable
      if @declaration.started_declaration_type?
        validate_status_transition(
          application: @application,
          to: Application::ACCEPTED,
          attribute: :base,
          error: :not_voidable_to_accepted_status,
        )
      else
        validate_status_transition(
          application: @application,
          to: Application::STARTED,
          attribute: :base,
          error: :not_voidable_to_started_status,
        )
      end
    end
  end
end
