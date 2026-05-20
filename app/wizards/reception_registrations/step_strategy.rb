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
      elsif current_step_name == :"work-setting"
        return :"ineligible-for-funding" unless state_store.inside_catchment?

        return :"choose-school" if state_store.state_funded_institution?

        :"ineligible-for-funding"
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

    def resolve_on_show
      return if step_available? # current step ok

      :start
    end

    def step_available?
      case current_step_name
      when :start, :closed, :"course-start-date"
        true
      when :"cannot-register-yet"
        state_store.confirmation == "no"
      when :"choose-your-provider"
        course_selected?
      when :"teacher-catchment"
        provider_selected?
      when :"work-setting"
        teacher_catchment_selected?
      when :"choose-school"
        school_required?
      when :"possible-funding"
        possible_funding_step_available?
      when :"ineligible-for-funding"
        ineligible_funding_step_available?
      when :"funding-your-course"
        funding_your_course_step_available?
      when :"share-provider"
        share_provider_step_available?
      when :"check-answers"
        check_answers_step_available?
      else
        false
      end
    end

    def course_start_date_confirmed?
      state_store.confirmation == "yes"
    end

    def course_selected?
      course_start_date_confirmed? && state_store.course.present?
    end

    def provider_selected?
      course_selected? && state_store.lead_provider.present?
    end

    def teacher_catchment_selected?
      provider_selected? && state_store.teacher_catchment.present?
    end

    def work_setting_selected?
      teacher_catchment_selected? && state_store.work_setting.present?
    end

    def childcare_work_setting_selected?
      work_setting_selected? && state_store.work_setting.in?(ReceptionRegistrations::Forms::WorkSettingForm::CHILDCARE_SETTINGS)
    end

    def school_work_setting_selected?
      work_setting_selected? && state_store.work_setting.in?(ReceptionRegistrations::Forms::WorkSettingForm::SCHOOL_SETTINGS)
    end

    def school_required?
      return false unless teacher_catchment_selected?

      state_store.inside_catchment?
    end

    def funding_eligibility_known?
      state_store.funding_eligibility_status_code.present?
    end

    def possible_funding_step_available?
      return true if funding_eligibility_known? && state_store.eligible_for_funding

      funding_eligibility_can_be_calculated? && @funding_eligibility_service.eligible_for_funding?
    end

    def ineligible_funding_step_available?
      return false unless work_setting_selected?
      return true unless state_store.inside_catchment?
      return true unless state_store.state_funded_institution?
      return true if funding_eligibility_known? && !state_store.eligible_for_funding

      funding_eligibility_can_be_calculated? && !@funding_eligibility_service.eligible_for_funding?
    end

    def funding_eligibility_can_be_calculated?
      work_setting_selected? &&
        state_store.inside_catchment? &&
        school_required? &&
        !state_store.no_institution_selected?
    end

    def funding_your_course_step_available?
      ineligible_funding_step_available?
    end

    def share_provider_step_available?
      return false unless work_setting_selected?
      return true if state_store.eligible_for_funding

      funding_your_course_step_available? && state_store.funding.present?
    end

    def check_answers_step_available?
      share_provider_step_available? && state_store.can_share_choices.present?
    end
  end
end
