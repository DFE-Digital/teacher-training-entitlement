# frozen_string_literal: true

module ParticipantOutcomes
  class Create
    include ActiveModel::Model
    include ActiveModel::Attributes

    STATES = %w[passed failed].freeze
    COMPLETION_DATE_FORMAT = /\d{4}-\d{2}-\d{2}/
    PERMITTED_COURSES = Course::IDENTIFIERS

    attr_reader :created_outcome

    attribute :application
    attribute :state
    attribute :completion_date

    validates :application, presence: true
    validates :state, inclusion: { in: STATES }, presence: true
    validates :completion_date, presence: true, format: { with: COMPLETION_DATE_FORMAT }
    validate :application_has_no_completed_declarations, if: -> { application }
    validate :completion_date_not_in_the_future

    def create_outcome
      return false unless valid?

      ApplicationRecord.transaction do
        @created_outcome = if outcome_already_exists?
                             latest_existing_outcome
                           else
                             new_outcome = build_outcome.tap(&:save!)
                             new_outcome.declaration.touch(time: new_outcome.updated_at)
                             application.application_states.create!(status: :completed)
                             application.completed_status!

                             new_outcome
                           end
      end

      true
    end

  private

    def outcome_already_exists?
      return unless latest_existing_outcome

      latest_existing_outcome.slice(:state, :completion_date) == build_outcome.slice(:state, :completion_date)
    end

    def build_outcome
      @build_outcome ||= ParticipantOutcome.new(declaration: latest_completed_declaration, state:, completion_date:)
    end

    def completed_declarations
      @completed_declarations ||= application
                                    .declarations
                                    .completed
                                    .billable_or_voidable
                                    .latest_first
    end

    def latest_completed_declaration
      @latest_completed_declaration ||= completed_declarations.first
    end

    def latest_existing_outcome
      @latest_existing_outcome ||= application
                                     .declarations
                                     .billable_or_voidable
                                     .latest_first
                                     .first
                                     &.participant_outcomes
                                     &.latest
    end

    def application_has_no_completed_declarations
      errors.add(:base, :no_completed_declarations) unless completed_declarations.exists?
    end

    def completion_date_not_in_the_future
      return if errors.key?(:completion_date)

      errors.add(:completion_date, :future_date) if completion_date&.to_date&.future?
    end
  end
end
