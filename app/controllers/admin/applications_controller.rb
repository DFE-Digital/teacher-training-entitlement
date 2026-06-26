module Admin
  class ApplicationsController < AdminController
    include Cohortable

    before_action :set_application

    def index
      applications = Application
                       .includes(:current_application_lead_provider, :cohort,
                                 :institution, :user, :lead_provider, :course,
                                 application_lead_providers: %i[lead_provider])
                       .merge(filter_scope)
                       .merge(search_scope)
                       .order("applications.created_at ASC")
      @pagy, @applications = pagy(applications)
    end

    def show; end

  private

    def set_application
      return if params[:id].nil?

      @application = Application
                   .includes(:institution, :user, :course, :cohort,
                             application_lead_providers: :lead_provider)
                   .find(params[:id])
    end

    def filter_params
      params.permit %i[
        status
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
            .joins(:cohort)
            .includes(:course, :cohort)
            .where(cohort_id: filter_params[:cohort_id]),
        )
      end

      scope
    end

    def search_scope
      ::Applications::Search.search(params[:q])
    end
  end
end
