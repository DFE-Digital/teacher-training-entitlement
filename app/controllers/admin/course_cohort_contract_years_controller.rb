class Admin::CourseCohortContractYearsController < AdminController
  before_action :set_course_cohort
  before_action :set_contract_year, only: %i[edit update]
  before_action :set_lead_providers
  before_action :ensure_super_admin

  def new
    @contract_year = @course.contract_years.new(academic_year: @course_cohort.academic_year)
  end

  def create
    @contract_year = @course.contract_years.new(contract_year_params)

    if @contract_year.save
      flash[:success] = "Contract year created"
      redirect_to admin_cohort_course_path(@cohort, @course)
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @contract_year.update(contract_year_params)
      flash[:success] = "Contract year updated"
      redirect_to admin_cohort_course_path(@cohort, @course)
    else
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

  def set_contract_year
    @contract_year = @course.contract_years.find(params[:id])
  end

  def set_lead_providers
    @lead_providers = LeadProvider.order(:name)
  end

  def contract_year_params
    params
      .require(:contract_year)
      .permit(:lead_provider_id, :academic_year, :recruitment_target, :teacher_funding, :service_fee)
  end

  def ensure_super_admin
    return if current_admin.super_admin?

    flash[:error] = "You must be a super admin to change contract years"
    redirect_to admin_cohort_course_path(@cohort, @course)
  end
end
