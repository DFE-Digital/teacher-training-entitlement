module ReceptionRegistrations
  class StepStrategy
    attr_reader :wizard

    delegate :current_step_name, :current_step, :state_store, to: :wizard

    def initialize(wizard:, action_type:, funding_eligibility_service:)
      @wizard = wizard
      @action_type = action_type
      @funding_eligibility_service = funding_eligibility_service
    end

    def resolve
      if @action_type == :update
        resolve_on_update
      else
        resolve_on_show
      end
    end

  private

    def resolve_on_update
      if current_step_name == :"course-start-date" && current_step.confirmation == "no"
        :"cannot-register-yet"
      elsif current_step_name == :"choose-your-provider" && current_step.not_chosen?
        :"choose-a-tte-and-provider"
      elsif current_step_name == :"work-setting"
        return :"ineligible-for-funding" unless state_store.inside_catchment?
        return :"choose-school" if current_step.works_in_school?
        return :"kind-of-nursery" if current_step.works_in_childcare?

        :"ineligible-for-funding"
      elsif current_step_name == :"kind-of-nursery"
        if state_store.public_nursery?
          :"choose-school"
        else
          :"ineligible-for-funding"
        end
      elsif current_step_name == :"choose-school"

        if state_store.no_institution_selected?
          :"choose-school"
        elsif @funding_eligibility_service.eligible_for_funding?
          :"possible-funding"
        else
          :"ineligible-for-funding"
        end
      elsif current_step_name == :"possible-funding"
        :"share-provider"
      end
    end

    def resolve_on_show; end
  end
end
