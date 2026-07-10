class Admin::CohortsController < AdminController
  before_action :ensure_super_admin, except: %i[index show]
  before_action :cohort, only: %i[show edit update destroy]

  def index
    @pagy, @cohorts = pagy(Cohort.order_by_latest)
  end

  def show; end

  def new
    @cohort = Cohort.new(course: Course.find_by(id: params[:course_id]))
    render :form
  end

  def create
    @cohort = Cohort.new(cohort_params)

    if @cohort.save
      Cohorts::CopyDeliveryPartnersJob.perform_later(@cohort.id)
      flash[:success] = "Cohort created"
      redirect_to admin_course_cohort_path(@cohort.course, @cohort)
    else
      render :form, status: :unprocessable_content
    end
  end

  def edit
    render :form
  end

  def update
    if @cohort.update(cohort_params)
      flash[:success] = "Cohort updated"
      redirect_to admin_course_cohort_path(cohort.course, cohort)
    else
      render :form, status: :unprocessable_content
    end
  end

  def destroy
    if params[:confirm].present?
      @cohort.destroy!
      flash[:success] = "Cohort deleted"
      redirect_to admin_course_path(@course)
    else
      render :destroy
    end
  end

  def download_contracts
    send_data Exporters::Contracts.new(cohort:).call, filename: "#{cohort.identifier}_cohort_contracts.csv", type: :csv
  end

private

  def cohort_params
    params.require(:cohort).permit(
      :registration_starts_at,
      :registration_ends_at,
      :training_starts_at,
      :training_ends_at,
      :funding_cap,
      :description,
      :course_id,
    )
  end

  def cohort
    @cohort ||= course.cohorts.find(params[:id])
  end

  def course
    @course ||= Course.find(params[:course_id])
  end

  def ensure_super_admin
    unless current_admin.super_admin?
      action = action_name == "download_contracts" ? "download contracts" : "change cohorts"
      flash[:error] = "You must be a super admin to #{action}"
      redirect_to admin_path
    end
  end
end
