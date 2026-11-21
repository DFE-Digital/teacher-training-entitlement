module FundingEligibilities
  class StateFundedSchool
    class MissingMandatoryInstitution < StandardError; end

    def key
      STATE_FUNDED_SCHOOL
    end

    def name
      "State-funded school"
    end

    def evaluate(query_store, institution: query_store.institution)
      return NOT_IN_ENGLAND if institution && !institution.in_england?
      return PREVIOUSLY_FUNDED if previously_funded?(query_store)

      case query_store.work_setting
      when Institution::STATE_FUNDED_INSTITUTION then school_policy(institution)
      else INELIGIBLE_SETTING
      end
    end

    def funded?(query_store, institution: query_store.institution)
      evaluate(query_store, institution:) == FUNDED_ELIGIBILITY_RESULT
    end

    def previously_funded?(query_store)
      accepted_applications(query_store).any?
    end

    def submission_attributes(query_store)
      result = evaluate(query_store)

      {
        funding_eligibility: result,
        # It is possible that the applicant had chosen a non-funded path and selected a funding choice
        # before going back a few steps and choosing a funded route. We should clear the funding choice
        # to nil here to reduce confusion
        funding_choice: result == FUNDED_ELIGIBILITY_RESULT ? nil : query_store.funding,
      }
    end

  private

    def school_policy(institution)
      raise MissingMandatoryInstitution if institution.nil?
      return INELIGIBLE_SETTING unless institution.eligible_establishment?

      FUNDED_ELIGIBILITY_RESULT
    end

    def users(query_store)
      user = query_store.current_user
      return User.where(trn: user.trn) if user&.trn.present?

      User.where(one_login_id: user&.one_login_id)
    end

    def accepted_applications(query_store)
      Application
        .where(user: users(query_store))
        .has_been_accepted
        .eligible_for_funding
        .where(funded_place: [nil, true])
    end
  end
end
