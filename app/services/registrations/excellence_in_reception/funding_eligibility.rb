module Registrations
  module ExcellenceInReception
    class FundingEligibility
      INELIGIBLE_SETTING = "ineligible_setting".freeze
      NOT_IN_ENGLAND = "not_in_england".freeze
      FUNDED = "funded".freeze
      PREVIOUSLY_FUNDED = "previously_funded".freeze

      def initialize(router_step:)
        @router_step = router_step
      end

      attr_reader :router_step

      def call
        router_step.state_store.write(funding_eligibility_result:)
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
        return NOT_IN_ENGLAND if router_step.state_store["teacher_catchment"] == Institution::OTHER
        return PREVIOUSLY_FUNDED if previously_funded?
        return INELIGIBLE_SETTING if router_step.state_store["institution_id"].blank?

        institution = Institution.find(router_step.state_store["institution_id"])
        institution.eligible_establishment? ? FUNDED : INELIGIBLE_SETTING
      end

      def trn
        router_step.current_user&.trn
      end

      def one_login_id
        router_step.current_user&.one_login_id
      end
    end
  end
end
