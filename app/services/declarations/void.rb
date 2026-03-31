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

    def call
      return unless valid?

      ApplicationRecord.transaction do
        @declaration.mark_voided!
        @declaration.statement_items.with_state(:eligible, :ineligible, :payable).first&.mark_voided!

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

    def declaration_not_already_voided
      errors.add(:base, :already_voided) if @declaration.voided_state?
    end
  end
end
