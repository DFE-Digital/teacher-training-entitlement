class Admin::DashboardsController < AdminController
  def show
    @dashboard = params[:name]
    if params[:cohort_id].present?
      @cohort = Cohort.find_by(id: params[:cohort_id])
      @applications = Application.joins(:course_cohort).where(course_cohorts: { cohort: @cohort })
    else
      @applications = Application
    end
  end
end
