module Registrations
  module ExcellenceInReception
    class FundingEligibility
      def initialize(wizard_step:)
        @wizard_step = wizard_step
      end

      attr_reader :wizard_step

      def call
        wizard_step.wizard.state_store.write("funding_eligibility_result" => funding_eligibility_result)
      end

    private

      def users
        return User.where(trn:) if trn.present?

        User.where(one_login_id:)
      end

      def previously_funded?
        accepted_applications.any?
      end

      def accepted_applications
        users.flat_map do |user|
          user.applications
              .has_been_accepted
              .eligible_for_funding
              .where(funded_place: [nil, true])
        end
      end

      def funding_eligibility_result
        state_store = wizard_step.wizard.state_store
        return Registrations::FundingEligibilityConstants::NOT_IN_ENGLAND if state_store["teacher_catchment"] == Institution::OTHER
        return Registrations::FundingEligibilityConstants::PREVIOUSLY_FUNDED if previously_funded?
        return Registrations::FundingEligibilityConstants::INELIGIBLE_SETTING if state_store["institution_id"].blank?

        institution = Institution.find(state_store["institution_id"])
        institution.eligible_establishment? ? Registrations::FundingEligibilityConstants::FUNDED : Registrations::FundingEligibilityConstants::INELIGIBLE_SETTING
      end

      def trn
        wizard_step.wizard.current_user&.trn
      end

      def one_login_id
        wizard_step.wizard.current_user&.one_login_id
      end
    end
  end
end
