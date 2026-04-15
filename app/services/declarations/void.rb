# frozen_string_literal: true

module Declarations
  class Void
    include ActiveModel::Model
    include ActiveModel::Validations

    def initialize(declaration:)
      @declaration = declaration
      @application = declaration.application
    end

    validate :declaration_not_already_voided
    validate :application_status_not_completed

    def call
      return unless valid?

      ApplicationRecord.transaction do
        @declaration.mark_voided!
        @declaration.statement_items.with_state(:eligible, :ineligible, :payable).first&.mark_voided!

        ParticipantOutcomes::Void.new(declaration: @declaration).void_outcome

        if @declaration.started_declaration_type?
          @application.update!(status: Application::ACCEPTED)
          @application.state_changes.create!(
            event: Application::ACCEPTED,
            metadata: { reason: "started declaration voided" },
          )
        elsif @declaration.completed_declaration_type?
          @application.update!(status: Application::STARTED)
          @application.state_changes.create!(
            event: Application::STARTED,
            metadata: { reason: "completed declaration voided" },
          )
        end
      end
    end

  private

    def application_status_not_completed
      if @declaration.started_declaration_type? && @application.completed_status?

        errors.add(:base, :application_status_completed)
      end
    end

    def declaration_not_already_voided
      errors.add(:base, :already_voided) if @declaration.voided_state?
    end
  end
end
