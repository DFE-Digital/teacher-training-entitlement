# frozen_string_literal: true

module Applications
  class ChangeFundingEligibility
    include ActiveModel::Validations
    include Validations::ApplicationNotSuperceded

    attr_reader :application

    def initialize(application:, eligible_for_funding:)
      @application = application
      @eligible_for_funding = eligible_for_funding
    end

    validate  :validate_funding_eligiblity_status_code_change
    validate  :validate_funding_eligiblity_status_with_funded_place

    def call
      return if invalid?

      @application.update!(eligible_for_funding: @eligible_for_funding,
                           funding_eligiblity_status_code:)

      send_eligible_for_funding_email if @application.eligible_for_funding?
    end

  private

    def funding_eligiblity_status_code
      @eligible_for_funding ? :marked_funded_by_policy : :marked_ineligible_by_policy
    end

    def validate_funding_eligiblity_status_code_change
      declared_as_billable_or_changeable = @application.declarations.billable_or_changeable.count.positive?

      if declared_as_billable_or_changeable && @eligible_for_funding == false
        errors.add(:base, :declaration_exists)
      end
    end

    def validate_funding_eligiblity_status_with_funded_place
      if !@eligible_for_funding && @application.funded_place
        errors.add(:base, :funded_application)
      end
    end

    def send_eligible_for_funding_email
      GenericMailer.with(
        to: @application.user.email,
        full_name: @application.user.full_name,
        provider_name: @application.lead_provider.name,
        course_name: @application.course.name,
        ecf_id: @application.ecf_id,
      ).eligible_for_funding.deliver_later
    end
  end
end
