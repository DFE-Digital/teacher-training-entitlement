# frozen_string_literal: true

module Declarations
  class Create
    include ActiveModel::Model
    include ActiveModel::Attributes
    include Applications::Validations::StatusTransitionValidation

    attribute :application
    attribute :declaration_type, :string
    attribute :declaration_date, :datetime
    attribute :has_passed
    attribute :delivery_partner_id
    attribute :secondary_delivery_partner_id

    validates :application, presence: true
    validates :declaration_type, presence: true
    validates :declaration_type, inclusion: { in: ->(service) { service.allowed_declaration_types } }, if: -> { application && declaration_type }
    validates :declaration_date, presence: true
    validates :declaration_date, declaration_date: true
    validates :delivery_partner_id, presence: true
    validate :application_is_declarable, if: -> { application }
    validate :declaration_type_out_of_order
    validate :validate_has_passed_field, if: :completed_declaration?
    validate :no_duplicate_billable_declaration
    validate :delivery_partner_exists, if: :delivery_partner_id
    validate :secondary_delivery_partner_exists, if: :secondary_delivery_partner_id
    validate :declaration_valid
    validate :application_updateable

    delegate :lead_provider, :schedule, to: :application

    attr_reader :raw_declaration_date, :declaration

    delegate :course_cohort, to: :application
    delegate :cohort, to: :course_cohort

    def call
      return false unless valid?

      ApplicationRecord.transaction do
        @declaration = application.declarations.create!(declaration_parameters_for_create)
        @declaration.mark_eligible!

        if started_declaration?
          application_started!
        elsif completed_declaration?
          # [TODO]: Define when to raise statement for TTE
          # StatementAttacher.new(@declaration:).attach
          create_participant_outcome!
          application_completed!
        end
      end

      true
    end

    def application_completed!
      application.transition_status!(Application::COMPLETED)
    end

    def application_started!
      application.transition_status!(Application::STARTED)
    end

    def declaration_date=(raw_declaration_date)
      self.raw_declaration_date = raw_declaration_date
      super
    end

    def active_declarations
      @active_declarations ||= application.declarations.billable_or_changeable
    end

    def completed_declaration?
      declaration_type == Milestone::COMPLETED
    end

    def started_declaration?
      declaration_type == Milestone::STARTED
    end

    def milestone
      return if declaration_type.blank?

      @milestone ||= course_cohort.milestones.find_by!(declaration_type:)
    end

    def allowed_declaration_types
      course_cohort.milestones.pluck(:declaration_type)
    end

  private

    def application_updateable
      if completed_declaration?
        validate_status_transition(
          application:,
          to: Application::COMPLETED,
          error: :not_completable,
        )
      else
        validate_status_transition(
          application:,
          to: Application::STARTED,
          error: :not_startable,
        )
      end
    end

    attr_writer :raw_declaration_date

    def delivery_partner
      @delivery_partner ||= DeliveryPartner.find_by!(ecf_id: delivery_partner_id)
    end

    def secondary_delivery_partner
      @secondary_delivery_partner ||= DeliveryPartner.find_by!(ecf_id: secondary_delivery_partner_id)
    end

    def declaration_parameters_for_create
      params = {
        declaration_date:,
        declaration_type:,
        lead_provider:,
        application:,
        milestone:,
        delivery_partner:,
      }
      params.merge!(secondary_delivery_partner:) if secondary_delivery_partner_id
      params
    end

    def output_fee_statement_available
      return if errors.any?
      return if existing_declaration&.submitted_state?
      return if existing_declaration.nil? && !application.fundable?
      return if lead_provider.next_output_fee_statement(cohort).present?

      errors.add(:cohort, :no_output_fee_statement, cohort: cohort.start_year)
    end

    def validate_declaration_type_for_schedule
      return if errors.any?
      return if allowed_declaration_types.include?(declaration_type)

      errors.add(:declaration_type, :mismatch_declaration_type_for_schedule)
    end

    def no_duplicate_billable_declaration
      return if errors.any?
      return unless active_declarations.where(declaration_type:).exists?

      errors.add(:base, :declaration_already_exists)
    end

    def validate_has_passed_field
      self.has_passed = has_passed.to_s

      return unless has_passed.blank? || !%w[true false].include?(has_passed)

      errors.add(:has_passed, :invalid)
    end

    def create_participant_outcome!
      return unless completed_declaration?

      service = ParticipantOutcomes::Create.new(
        application:,
        state: has_passed.to_s == "true" ? "passed" : "failed",
        completion_date: declaration_date.rfc3339,
      )

      if service.valid?
        service.create_outcome
      else
        raise ArgumentError, I18n.t(:cannot_create_completed_declaration)
      end
    end

    def declaration_valid
      return if errors.any?

      declaration = Declaration.new(declaration_parameters_for_create)
      errors.merge!(declaration.errors) unless declaration.valid?
    end

    def delivery_partner_exists
      delivery_partner
    rescue ActiveRecord::RecordNotFound
      errors.add(:delivery_partner_id, :not_found)
    end

    def secondary_delivery_partner_exists
      secondary_delivery_partner
    rescue ActiveRecord::RecordNotFound
      errors.add(:secondary_delivery_partner_id, :not_found)
    end

    def application_is_declarable
      return if application.accepted_status? || application.started_status?

      errors.add(:application, :in_wrong_state)
    end

    def declaration_type_out_of_order
      return if started_declaration?
      return if completed_declaration? && active_declarations.started.exists?

      errors.add(:declaration_type, :out_of_order)
    end

    def started_declaration_milestone
      active_declarations
        .started_declaration_type
        .first
        .milestone
    end
  end
end
