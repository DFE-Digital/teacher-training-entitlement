module Admin
  class SearchController < AdminController
    def index
      @search_requested = search_requested?
      return unless @search_requested || show_all?

      @pagy_applications, @applications = pagy(applications_query,
                                               page_param: :applications_page,
                                               params: pagination_params_for(:applications))

      if search_param.present? || show_all?
        @pagy_users, @users = pagy(users_query,
                                   page_param: :users_page,
                                   params: pagination_params_for(:users))
      end
    end

  private

    def applications_query
      AdminService::ApplicationsSearch.new(q: search_param, filters: filter_params).call
    end

    def users_query
      AdminService::UsersSearch.new(q: search_param).call
    end

    def pagination_params_for(tab)
      ->(params) { params.merge("tab" => tab.to_s) }
    end

    def filter_params
      @filter_params ||=
        params.permit(%i[
          status
        ]).to_h
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
