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
      cohort_id
      work_setting
    ]
  end

  def filter_scope
    filters = filter_params.except(:cohort_id)
    scope = Application
              .where(filters.compact_blank)

    if filter_params[:cohort_id].present?
      scope.merge!(
        Application
          .joins(:course_cohort)
          .includes(course_cohort: %i[course cohort])
          .where(course_cohorts: { cohort_id: filter_params[:cohort_id] }),
      )
    end

    scope
  end

  def search_scope
    Applications::Search.search(params[:q])
  end
end
