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

    def call
      return unless valid?

      ApplicationRecord.transaction do
        @declaration.mark_awaiting_clawback!
        statement_attacher.attach

        ParticipantOutcomes::Void.new(declaration: @declaration).void_outcome

        if @declaration.started_declaration_type?
          @application.update!(status: Application::ACCEPTED)
        elsif @declaration.completed_declaration_type?
          @application.application_states.reject(&:started_status?).each(&:destroy)
          @application.update!(status: Application::STARTED)
        end
      end
    end

  private

    def statement_attacher
      @statement_attacher ||= StatementAttacher.new(declaration: @declaration)
    end

    def declaration_not_already_refunded
      return unless @declaration.statement_items.refundable.exists?

      errors.add(:base, :not_already_refunded)
    end

    def output_fee_statement_available
      return if statement_attacher.valid?

      errors.add(:base, :no_output_fee_statement, cohort: @declaration.cohort.start_year)
    end

    def declaration_is_paid
      return if errors.any? || @declaration.paid_state?

      errors.add(:base, :must_be_paid)
    end
  end
end
