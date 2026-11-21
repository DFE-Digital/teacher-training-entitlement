module Registration
  class StepsController < PublicPagesController
    include HtmlRequestsOnly

    before_action :ensure_feature_enabled
    before_action :redirect_to_closed_if_registration_closed
    before_action :set_course
    before_action :set_wizard
    before_action :ensure_known_step
    before_action :redirect_to_first_incomplete_step, unless: -> { @wizard.valid_path_to_current_step? }

    def show
      render @wizard.current_step_name
    end

    def update
      if @wizard.save_current_step && @wizard.next_step
        redirect_to @wizard.next_step_path
      elsif @wizard.current_step.errors.any?
        render @wizard.current_step_name, status: :unprocessable_content
      else
        redirect_to root_path
      end
    end

  private

    def ensure_feature_enabled
      raise ActionController::RoutingError, "Not Found" unless Feature.registration_dfe_wizard?
    end

    def redirect_to_closed_if_registration_closed
      redirect_to registration_wizard_show_path(:closed) if Feature.registration_closed?(current_user)
    end

    def set_course
      @course = Course.find_by!(identifier: params[:course_identifier])
    end

    def set_wizard
      raise ActionController::RoutingError, "Not Found" unless params[:step] == params[:step].underscore.dasherize

      @wizard = Registration::Wizard.for_session(
        course: @course,
        session:,
        current_user:,
        current_step: params[:step].underscore.to_sym,
        current_step_params: request.get? ? {} : params,
      )
    end

    def ensure_known_step
      raise ActionController::RoutingError, "Not Found" unless @wizard.step_names.include?(@wizard.current_step_name)
    end

    def redirect_to_first_incomplete_step
      redirect_to @wizard.resolve_step_path(@wizard.first_incomplete_step)
    end
  end
end
