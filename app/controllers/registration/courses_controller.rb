module Registration
  # Course selection before the registration wizard starts. Open to everyone:
  # whether a teacher can continue is decided by the wizard steps.
  class CoursesController < PublicPagesController
    include HtmlRequestsOnly

    before_action :ensure_feature_enabled
    before_action :redirect_to_closed_if_registration_closed
    before_action :set_open_courses, only: %i[index create]

    def index
      return redirect_to registration_wizard_show_path(:closed) if @courses.empty?

      flash.keep if @courses.one?
      return redirect_to_course(@courses.first) if @courses.one?

      @selection = CourseSelection.new
    end

    def create
      @selection = CourseSelection.new(course_identifier: params.dig(:course_selection, :course_identifier))
      course = @courses.find { _1.identifier == @selection.course_identifier }
      return redirect_to_course(course) if course

      @selection.course_identifier = nil
      @selection.validate
      render :index, status: :unprocessable_content
    end

    # Deep link from landing pages on other services.
    def show
      course = Course.open_for_registration.find_by(identifier: params[:course_identifier])
      return redirect_to_course(course) if course

      flash[:error] = "That course is not available for registration. Choose from the courses that are open."
      redirect_to registration_courses_path
    end

  private

    def ensure_feature_enabled
      raise ActionController::RoutingError, "Not Found" unless Feature.registration_dfe_wizard?
    end

    def redirect_to_closed_if_registration_closed
      redirect_to registration_wizard_show_path(:closed) if Feature.registration_closed?(current_user)
    end

    def set_open_courses
      @courses = Course.open_for_registration.to_a
    end

    # The teacher starts at the root step of the course's journey, wherever sign in sits.
    def redirect_to_course(course)
      wizard = Registration::Wizard.for_session(course:, session:, current_user:, current_step: :sign_in)
      redirect_to wizard.resolve_step_path(wizard.root_step)
    end
  end
end
