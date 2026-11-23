module Admin
  class SearchController < AdminController
    def index
      @search_requested = search_requested?
      return unless @search_requested || show_all?

      @pagy_applications, @applications = pagy(applications_query,
                                               page_param: :applications_page,
                                               params: pagination_params_for(:applications))

      if search_param.present? || show_all?
        @pagy_teachers, @teachers = pagy(teachers_query,
                                         page_param: :teachers_page,
                                         params: pagination_params_for(:teachers))
      end
    end

  private

    def applications_query
      return direct_applications_query if search_param.blank? || direct_applications_query.exists?

      applications_for_matching_teachers_query
    end

    def teachers_query
      @teachers_query ||= AdminService::TeachersSearch.new(q: search_param).call
    end

    def direct_applications_query
      @direct_applications_query ||= AdminService::ApplicationsSearch.new(q: search_param, filters: application_filters).call
    end

    def applications_for_matching_teachers_query
      Application
        .includes(
          :institution,
          :teacher,
          :lead_provider,
          :current_application_lead_provider,
          application_lead_providers: %i[lead_provider],
          course_cohort: %i[course cohort],
        )
        .where(teacher_id: teachers_query.unscope(:order).select(:id))
        .merge(application_filter_scope)
        .order(created_at: :desc, teacher_id: :desc)
    end

    def application_filter_scope
      return Application.all if status_filter.blank?

      Application.where(status: status_filter)
    end

    def pagination_params_for(tab)
      ->(params) { params.merge("tab" => tab.to_s) }
    end

    def filter_params
      @filter_params ||=
        params.permit(%i[
          status
        ]).to_h.with_indifferent_access
    end

    def status_filter
      @status_filter ||= Application::STATUSES.find { |status| status == filter_params[:status] }
    end

    def application_filters
      @application_filters ||= {}.tap do |filters|
        filters[:status] = status_filter if status_filter.present?
      end
    end

    def show_all?
      return false if search_requested?

      values = filter_params.values

      filter_params.keys.any? && filter_params.keys.size == values.select(&:blank?).size
    end

    def search_requested?
      search_param.present? || filter_params.compact_blank.present?
    end

    def search_param
      params[:q]&.gsub(/[^\p{ASCII}]/, "")&.strip
    end
  end
end
