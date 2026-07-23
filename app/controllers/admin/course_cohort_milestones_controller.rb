class Admin::CourseCohortMilestonesController < AdminController
  before_action :set_course_cohort
  before_action :set_milestone, only: %i[edit update]
  before_action :ensure_super_admin

  def new
    @form = build_form(
      acceptance_window_start_date: @cohort.registration_starts_at,
      acceptance_window_end_date: @cohort.registration_ends_at,
    )
  end

  def create
    @form = build_form(form_params)
    @milestone = @course_cohort.milestones.new(@form.attributes.symbolize_keys)

    if @milestone.save
      flash[:success] = "Milestone created"
      redirect_to admin_cohort_course_path(@cohort, @course)
    else
      copy_errors_to_form
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @form = build_form(@milestone.attributes)
  end

  def update
    @form = build_form(form_params)
    @milestone.assign_attributes(@form.attributes.symbolize_keys)

    if @milestone.save
      flash[:success] = "Milestone updated"
      redirect_to admin_cohort_course_path(@cohort, @course)
    else
      copy_errors_to_form
      render :edit, status: :unprocessable_content
    end
  end

private

  def set_course_cohort
    @cohort = Cohort.find(params[:cohort_id])
    @course_cohort = @cohort.course_cohorts.includes(:course).find_by!(course_id: params[:course_id]).tap do |course_cohort|
      @course = course_cohort.course
    end
  end

  def set_milestone
    @milestone = @course_cohort.milestones.find(params[:id])
  end

  def build_form(attributes)
    Admin::CourseCohortMilestones::Form.new(
      attributes,
      taken_declaration_types: @course_cohort.taken_declaration_types(except: @milestone),
    )
  end

  def form_params
    params
      .fetch(:form, ActionController::Parameters.new)
      .permit(*Admin::CourseCohortMilestones::Form::FORM_ATTRIBUTE_KEYS)
      .to_h
  end

  def ensure_super_admin
    return if current_admin.super_admin?

    flash[:error] = "You must be a super admin to change milestones"
    redirect_to admin_cohort_course_path(@cohort, @course)
  end

  def copy_errors_to_form
    @milestone.errors.each { |error| @form.errors.add(error.attribute, error.message) }
  end
end
