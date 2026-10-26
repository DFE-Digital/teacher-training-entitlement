# frozen_string_literal: true

module Declarations
  class Create
    include ActiveModel::Model
    include Applications::Validations::StatusTransitionValidation

    validates :application, presence: true
    validates :declaration_type, presence: true
    validate :declaration_type_out_of_order, if: -> { application }
    validates :declaration_type, inclusion: { in: ->(service) { service.allowed_declaration_types } }, if: -> { application && declaration_type }
    validates :declaration_date, presence: true
    validates :declaration_date, declaration_date: true
    validates :delivery_partner_id, presence: true
    validate :application_is_declarable, if: -> { application }
    validate :validate_has_passed_field, if: :completed_declaration?
    validates :has_passed, absence: true, unless: :completed_declaration?
    validate :no_duplicate_billable_declaration
    validate :delivery_partners_exist
    validate :declaration_valid
    validate :application_updateable

    delegate :lead_provider, :course_cohort, :contract, to: :application

    attr_reader :application,
                :declaration_type,
                :declaration_date,
                :delivery_partner_id,
                :secondary_delivery_partner_id,
                :raw_declaration_date,
                :declaration,
                :has_passed

    def initialize(application: nil,
                   declaration_type: nil,
                   declaration_date: nil,
                   has_passed: nil,
                   delivery_partner_id: nil,
                   secondary_delivery_partner_id: nil)
      @application = application
      @declaration_type = declaration_type&.to_s
      @raw_declaration_date = declaration_date
      @declaration_date = ActiveModel::Type::DateTime.new.cast(declaration_date)
      @has_passed = has_passed.to_s
      @delivery_partner_id = delivery_partner_id
      @secondary_delivery_partner_id = secondary_delivery_partner_id
    end

    def call
      return false unless valid?

      ApplicationRecord.transaction do
        @declaration = application.declarations.create!(declaration_parameters_for_create)
        @declaration.mark_eligible!

        if started_declaration?
          application_started!
        elsif completed_declaration?
          create_participant_outcome!
          application_completed!
        end
      end

      true
    end

    def completed_declaration?
      declaration_type == Milestone::COMPLETED
    end

    def started_declaration?
      declaration_type == Milestone::STARTED
    end

    def retained_1_declaration?
      declaration_type == Milestone::RETAINED_1
    end

    def milestone
      return if declaration_type.blank?
      return unless declaration_type.in?(allowed_declaration_types)

      @milestone ||= course_cohort.milestones.find_by!(declaration_type:)
    end

    def allowed_declaration_types
      @allowed_declaration_types ||= course_cohort.milestones.pluck(:declaration_type)
    end

    def value
      return unless application.funded_place # only funded application have a value

      amount = nil
      if milestone&.payment_percentage
        amount = contract.teacher_funding * milestone.payment_percentage
      end
      # for uplift incentives
      # amount += qualifying_uplfit_incentives.sum(&:value)
      amount
    end

  private

    def application_completed!
      application.transition_status!(Application::COMPLETED)
    end

    def application_started!
      application.transition_status!(Application::STARTED)
    end

    def active_declarations
      @active_declarations ||= application.declarations.billable_or_changeable
    end

    def application_updateable
      if completed_declaration?
        validate_status_transition(
          application:,
          to: Application::COMPLETED,
          error: :not_completable,
        )
      elsif started_declaration?
        validate_status_transition(
          application:,
          to: Application::STARTED,
          error: :not_startable,
        )
      elsif !application.started_status?
        errors.add(:application, :in_wrong_state)
      end
    end

    def delivery_partner
      @delivery_partner ||= DeliveryPartner.find_by(ecf_id: delivery_partner_id)
    end

    def secondary_delivery_partner
      @secondary_delivery_partner ||= DeliveryPartner.find_by(ecf_id: secondary_delivery_partner_id)
    end

    def statement
      Statement.current(lead_provider:, course_group:).first ||
        Statement.create_current!(lead_provider:, course_group:)
    end

    def course_group
      course_cohort.course.course_group
    end

    def declaration_parameters_for_create
      params = {
        declaration_date:,
        declaration_type:,
        lead_provider:,
        application:,
        milestone:,
        statement:,
        value:,
      }
      params.merge!(delivery_partner:) if delivery_partner_id
      params.merge!(secondary_delivery_partner:) if secondary_delivery_partner_id
      params
    end

    def no_duplicate_billable_declaration
      return if errors.any?
      return unless active_declarations.where(declaration_type:).exists?

      errors.add(:base, :declaration_already_exists)
    end

    def validate_has_passed_field
      return unless @has_passed.blank? || !%w[true false].include?(@has_passed)

      errors.add(:has_passed, :invalid)
    end

    def create_participant_outcome!
      return unless completed_declaration?

      service = ParticipantOutcomes::Create.new(
        application:,
        state: @has_passed == "true" ? "passed" : "failed",
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

    def delivery_partners_exist
      errors.add(:delivery_partner_id, :not_found) if delivery_partner_id.present? && delivery_partner.nil?
      errors.add(:secondary_delivery_partner_id, :not_found) if secondary_delivery_partner_id.present? && secondary_delivery_partner.nil?
    end

    def application_is_declarable
      return if application.accepted_status? || application.started_status?

      errors.add(:application, :in_wrong_state)
    end

    def declaration_type_out_of_order
      return if milestone&.declaration_in_order?(declarations: active_declarations)

      errors.add(:declaration_type, :out_of_order)
    end
  end
end
