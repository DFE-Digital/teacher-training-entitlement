module Admin
  class CourseCohortProvidersController < AdminController
    before_action :set_course_cohort_models
    before_action :ensure_super_admin

    def edit; end

    def update
      if @course_cohort_provider.update(course_cohort_provider_params)
        flash[:success] = "Course provider updated"
        redirect_to admin_cohort_course_path(@course_cohort.cohort, @course)
      else
        render :edit, status: :unprocessable_content
      end
    end

  private

    def set_course_cohort_models
      @course = Course.find(params[:course_id])
      @course_cohort_provider = @course.course_cohort_providers.find(params[:id])
      @course_cohort = @course_cohort_provider.course_cohort
    end

    def course_cohort_provider_params
      params.require(:course_cohort_provider).permit(:recruitment_target, :teacher_funding)
    end

    def ensure_super_admin
      return if current_admin.super_admin?

      flash[:error] = "You must be a super admin to change course cohort providers"
      redirect_to admin_cohort_course_path(@course_cohort.cohort, @course)
    end
  end
end
