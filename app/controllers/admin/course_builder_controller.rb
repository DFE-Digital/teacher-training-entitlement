class Admin::CourseBuilderController < AdminController
  before_action :require_super_admin
  before_action :assign_wizard
  before_action :load_options

  def show
    render current_step_template
  end

  def update
    return finish if current_step == :check_answers
    return redirect_to_check_answers if continuing_to_check_answers? && blank_milestone_submission?

    if @wizard.save_current_step
      redirect_to_next_step
    else
      render current_step_template, status: :unprocessable_content
    end
  end

private

  def finish
    course_cohort = create_records

    @wizard.clear_state

    flash[:success] = "Course cohort created"
    redirect_to admin_cohort_course_path(course_cohort.cohort, course_cohort.course)
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:error] = e.record.errors.full_messages.to_sentence
    render current_step_template, status: :unprocessable_content
  end

  def assign_wizard
    state_store = Admin::CourseBuilder::StateStore.new(
      repository: DfE::Wizard::Repository::Session.new(session:, key: :admin_course_builder),
    )

    @wizard = Admin::CourseBuilder::Wizard.new(
      current_step:,
      current_step_params: params,
      state_store:,
    )

    render_not_found unless @wizard.find_step(current_step)
  end

  def current_step
    @current_step ||= params.fetch(:step, "create-cohort").underscore.to_sym
  end

  def current_step_template
    "admin/course_builder/#{@wizard.current_step_name}"
  end

  def load_options
    @courses = Course.order(:name)
  end

  def redirect_to_next_step
    persist_milestone_step

    if adding_another_milestone?
      redirect_to @wizard.current_step_path
    elsif @wizard.next_step
      redirect_to @wizard.next_step_path
    else
      flash[:success] = "Course builder saved"
      redirect_to admin_courses_path
    end
  end

  def adding_another_milestone?
    current_step == :create_milestone && params[:next_step] == "create_another"
  end

  def continuing_to_check_answers?
    current_step == :create_milestone && params[:next_step] == "check_answers"
  end

  def blank_milestone_submission?
    milestone_params.values.all?(&:blank?)
  end

  def milestone_params
    params.fetch(:create_milestone, {}).permit(
      :declaration_type,
      :acceptance_window_start_date,
      :acceptance_window_end_date,
      :payment_amount,
    )
  end

  def redirect_to_check_answers
    redirect_to @wizard.resolve_step_path(:check_answers)
  end

  def persist_milestone_step
    return unless current_step == :create_milestone

    @wizard.write_state(milestones: @wizard.milestones + [@wizard.current_step.serializable_data.compact])
    reset_milestone_step
  end

  def reset_milestone_step
    @wizard.write_state(
      declaration_type: nil,
      acceptance_window_start_date: nil,
      acceptance_window_end_date: nil,
      payment_amount: nil,
    )
  end

  def render_not_found
    render status: :not_found, formats: [:html], template: "errors/not_found"
  end

  def create_records
    ActiveRecord::Base.transaction do
      cohort = Cohort.create!(cohort_attributes)
      course = Course.find(course_id)
      course_cohort = CourseCohort.create!(course:, cohort:, **course_cohort_attributes)

      milestone_attributes.each do |attributes|
        course_cohort.milestones.create!(attributes)
      end

      course_cohort
    end
  end

  def cohort_attributes
    step_data(:create_cohort).slice(
      :description,
      :registration_starts_at,
      :registration_ends_at,
      :funding_cap,
    )
  end

  def course_id
    step_data(:choose_course).fetch(:course_id)
  end

  def course_cohort_attributes
    step_data(:create_course_cohort).slice(
      :participant_funding,
      :service_fee,
      :registration_starts_at,
      :registration_ends_at,
      :training_starts_at,
      :training_ends_at,
    )
  end

  def milestone_attributes
    @wizard.milestones.map do |milestone|
      milestone.slice(
        :declaration_type,
        :acceptance_window_start_date,
        :acceptance_window_end_date,
        :payment_amount,
      )
    end
  end

  def step_data(step_name)
    @wizard.raw_data.fetch(:steps, {}).fetch(step_name, {}).with_indifferent_access
  end
end
