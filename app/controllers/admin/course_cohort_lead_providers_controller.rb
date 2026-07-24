module Admin
  class CourseCohortLeadProvidersController < AdminController
    before_action :set_course_cohort
    before_action :ensure_super_admin
    before_action :set_lead_providers, only: %i[show update]

    def show; end

    def update
      if @course_cohort.update(course_cohort_params)
        flash[:success] = "Course providers updated"
        redirect_to admin_cohort_course_path(@course_cohort.cohort, @course)
      else
        render :show, status: :unprocessable_content
      end
    end

  private

    def set_course_cohort
      @course = Course.find(params[:course_id])
      @course_cohort = @course.course_cohorts.find(params[:id])
    end

    def set_lead_providers
      @lead_providers = LeadProvider.order(:name)
    end

    def course_cohort_params
      params.require(:course_cohort).permit(lead_provider_ids: [])
    end

    def ensure_super_admin
      return if current_admin.super_admin?

      flash[:error] = "You must be a super admin to change course cohort providers"
      redirect_to admin_cohort_course_path(@course_cohort.cohort, @course)
    end
  end
end
