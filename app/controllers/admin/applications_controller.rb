class Admin::ApplicationsController < AdminController
  def index
    applications = Application
                     .includes(:institution, :user, course_cohort: %i[course cohort])
                     .merge(filter_scope)
                     .merge(search_scope)
                     .order("applications.created_at ASC")

    @pagy, @applications = pagy(applications)
  end

  def show
    @application = Application
                     .includes(:institution, :user, :lead_provider, course_cohort: %i[course cohort schedule])
                     .find(params[:id])
  end

private

  def filter_params
    params.permit %i[
      training_status
      lead_provider_approval_status
      course_cohort_id
      work_setting
    ]
  end

  def filter_scope
    Application
      .includes(course_cohort: %i[course cohort])
      .where(filter_params.compact_blank)
  end

  def search_scope
    Applications::Search.search(params[:q])
  end
end
