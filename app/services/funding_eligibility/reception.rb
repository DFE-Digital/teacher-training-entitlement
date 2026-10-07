module FundingEligibility
  class Reception
    def initialize(query_store:)
      @query_store = query_store
    end

    def call
      return if @query_store.works_in_school? && @query_store.institution.nil?

      @query_store.store["funding_eligiblity_status_code"] = funding_eligiblity_status_code
      @query_store.store["eligible_for_funding"] = eligible_for_funding?
      @query_store.store["previously_funded"] = previously_funded?
    end

  private

    def eligible_for_funding?
      funding_eligiblity_status_code == Constants::ELIGIBLE_FOR_FUNDING
    end

    def previously_funded?
      accepted_applications.any?
    end

    def funding_eligiblity_status_code
      if @query_store.not_in_england?
        Constants::NOT_IN_ENGLAND
      elsif previously_funded?
        Constants::PREVIOUSLY_FUNDED
      elsif @query_store.works_in_school? && institution.eligible_establishment?
        Constants::ELIGIBLE_FOR_FUNDING
      else
        Constants::INELIGIBLE_SETTING
      end
    end

    def users
      return User.where(trn:) if trn.present?

      User.where(one_login_id:)
    end

    def trn
      @query_store.current_user&.trn
    end

    def one_login_id
      @query_store.current_user&.one_login_id
    end

    def accepted_applications
      @accepted_applications ||= begin
        application_ids = users.flat_map do |user|
          user.applications
              .has_been_accepted
              .eligible_for_funding
              .where(funded_place: [nil, true])
              .pluck(:id)
        end

        Application.where(id: application_ids)
      end
    end

    def institution
      raise StandardError, "Cannot find institution from store" if @query_store.institution.nil?

      @query_store.institution
    end
  end
end
