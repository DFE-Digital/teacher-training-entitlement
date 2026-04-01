# frozen_string_literal: true

module Declarations
  class Clawback
    include ActiveModel::Model
    include ActiveModel::Validations

    def initialize(declaration:)
      @declaration = declaration
      @application = declaration.application
    end

    validate :declaration_not_already_refunded
    validate :output_fee_statement_available
    validate :declaration_is_paid
    validate :application_status_not_completed

    def call
      return unless valid?

      ApplicationRecord.transaction do
        @declaration.mark_awaiting_clawback!
        statement_attacher.attach

        ParticipantOutcomes::Void.new(declaration: @declaration).void_outcome

        if @declaration.started_declaration_type?
          @application.accepted_status!
          @application.application_states.create!(status: Application::ACCEPTED,
                                                  reason: "started declaration voided")
        elsif @declaration.completed_declaration_type?
          @application.started_status!
          @application.application_states.create!(status: Application::STARTED,
                                                  reason: "completed declaration voided")
        end
      end
    end

  private

    def statement_attacher
      @statement_attacher ||= StatementAttacher.new(declaration: @declaration)
    end

    def application_status_not_completed
      if @declaration.started_declaration_type? && @application.completed_status?

        errors.add(:base, :application_status_completed)
      end
    end

    def declaration_not_already_refunded
      return unless @declaration.statement_items.refundable.exists?

      errors.add(:base, :not_already_refunded)
    end

    def output_fee_statement_available
      return if statement_attacher.valid?

      statement_attacher.errors.each do |error|
        errors.add(:base, error.type, **error.options)
      end
    end

    def declaration_is_paid
      return if errors.any? || @declaration.paid_state?

      errors.add(:base, :must_be_paid)
    end
  end
end
