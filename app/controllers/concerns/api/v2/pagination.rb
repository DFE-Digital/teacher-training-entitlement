module API
  module V2
    # Countless Pagy pagination with JSON:API `links` and `meta`. No totals are
    # computed; navigation links keep every other query parameter (filters, include).
    module Pagination
      extend ActiveSupport::Concern
      include API::Pagination

    private

      def pagination_links
        {
          self: page_url(@pagy.page),
          prev: (page_url(@pagy.prev) if @pagy.prev),
          next: (page_url(@pagy.next) if @pagy.next),
        }
      end

      def pagination_meta
        { page: @pagy.page, per_page: @pagy.limit }
      end

      def page_url(page_number)
        query = request.query_parameters.deep_merge("page" => { "page" => page_number, "per_page" => per_page })

        "#{request.base_url}#{request.path}?#{Rack::Utils.build_nested_query(query)}"
      end

      def invalid_pagination_response(_exception)
        render_errors(status: :bad_request, title: I18n.t(:bad_request), details: I18n.t(:invalid_page_parameters))
      end
    end
  end
end
