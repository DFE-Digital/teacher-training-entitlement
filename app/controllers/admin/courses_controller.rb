module Admin
  class CoursesController < AdminController
    include Cohortable

    before_action :set_course, only: %i[show edit update]
    before_action :require_super_admin, only: %i[edit update]
    before_action :set_course_cohort, only: %i[show], if: -> { params[:cohort_id].present? }

    def index
      @unassigned_courses = Course.left_outer_joins(:course_cohorts).where(course_cohorts: { id: nil }).order(:name) if using_default_academic_year?
      @pagy, @resources = pagy(resources)
    end

    def show
      if @course_cohort
        @cohort = @course_cohort.cohort
        @course_cohorts = @course.course_cohorts.includes(:cohort).joins(:cohort).order("cohorts.registration_starts_at DESC")
        @contract_years = @course.contract_years.generic.includes(:lead_provider)
        @contract_financials = @course.contract_years.year(@course_cohort.academic_year).includes(:lead_provider)
        @contract_financials = @contract_years if @contract_financials.blank?
        @course_cohort_providers = @course_cohort
                                   .course_cohort_providers
                                   .joins(:lead_provider)
                                   .order(lead_provider: { name: :asc })
        @delivery_partner_counts = DeliveryPartnership
          .where(course_cohort: @course_cohort, lead_provider_id: @course_cohort.lead_provider_ids)
          .group(:lead_provider_id)
          .count
        render "admin/cohort_courses/show"
        return
      end

      @contract_years = @course.contract_years.includes(:lead_provider).order(:academic_year)
      @available_cohorts = Cohort.where.not(id: @course.course_cohorts.select(:cohort_id)).order(registration_starts_at: :desc)
    end

    def edit; end

    def update
      if @course.update(course_params)
        redirect_to admin_course_path(@course), flash: { success: "Course updated" }
      else
        render :edit, status: :unprocessable_content
      end
    end

  private

    def set_course
      @course = Course.find(params[:id])
    end

    def default_academic_year_actions
      %i[index]
    end

    def set_course_cohort
      @course_cohort = CourseCohort
                         .includes(:course, :cohort, course_cohort_providers: :lead_provider)
                         .find_by(course_id: params[:id], cohort_id: params[:cohort_id])

      redirect_to admin_courses_path unless @course_cohort
    end

    def course_params
      params.require(:course).permit(:name, :description)
    end

    def resources
      scope = Course
                .includes(:applications, course_cohorts: :cohort)
                .order(name: :asc)
      scope.merge!(Course.where(course_cohorts: { cohort: @current_cohort })) if @current_cohort
      scope.merge!(Course.where(course_cohorts: { academic_year: @current_academic_year })) if @current_academic_year
      scope
    end
  end
end
