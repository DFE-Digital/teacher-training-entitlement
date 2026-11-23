module API
  module V2
    # JSON:API cursor pagination profile
    # (https://jsonapi.org/profiles/ethanresnick/cursor-pagination/): `page[size]`,
    # `page[after]` and `page[before]`, with `self`/`prev`/`next` links that keep every
    # other query parameter (filters, include, sort). No totals are computed.
    module Pagination
      extend ActiveSupport::Concern

      PAGE_PARAMETERS = %w[size after before].freeze
      DEFAULT_PAGE_SIZE = 100
      MAX_PAGE_SIZE = 3000
      PROFILE_URL = "https://jsonapi.org/profiles/ethanresnick/cursor-pagination".freeze
      MAX_SIZE_EXCEEDED_TYPE = "#{PROFILE_URL}/max-size-exceeded".freeze
      RANGE_NOT_SUPPORTED_TYPE = "#{PROFILE_URL}/range-pagination-not-supported".freeze

    private

      # keys: the full sort order, ending with a unique tie-breaker (see CursorPaginator).
      def paginate(scope, keys:)
        @page = CursorPaginator.new(scope:, keys:, size: page_size, after: page_params["after"], before: page_params["before"]).call
        @page.records
      rescue CursorPaginator::InvalidCursor
        cursor = page_params.key?("before") ? "page[before]" : "page[after]"
        raise ParameterError.new(I18n.t(:invalid_cursor, parameter: cursor), parameter: cursor)
      end

      def pagination_links
        {
          self: page_url(page_params),
          prev: (page_url(page_params.except("after").merge("before" => @page.prev_cursor)) if @page.prev_cursor),
          next: (page_url(page_params.except("before").merge("after" => @page.next_cursor)) if @page.next_cursor),
        }
      end

      def page_params
        @page_params ||= validated_page_params(params[:page])
      end

      def validated_page_params(raw)
        return {} if raw.nil?

        raise page_error(I18n.t(:invalid_page_structure), "page") unless raw.is_a?(ActionController::Parameters)

        unsupported = raw.keys - PAGE_PARAMETERS
        raise page_error(I18n.t(:unsupported_page_parameters, keys: unsupported.join(", ")), "page") if unsupported.any?
        raise page_error(I18n.t(:invalid_page_structure), "page") unless raw.values.all?(String)
        raise ParameterError.new(I18n.t(:range_pagination_not_supported), parameter: "page[before]", type: RANGE_NOT_SUPPORTED_TYPE) if raw.key?("after") && raw.key?("before")

        raw.to_unsafe_h
      end

      def page_size
        value = page_params["size"]
        return DEFAULT_PAGE_SIZE if value.nil?

        size = value.match?(/\A[0-9]+\z/) ? value.to_i : 0
        raise page_error(I18n.t(:invalid_page_size), "page[size]") unless size.positive?

        if size > MAX_PAGE_SIZE
          raise ParameterError.new(
            I18n.t(:page_size_exceeded, size:, max: MAX_PAGE_SIZE),
            parameter: "page[size]",
            type: MAX_SIZE_EXCEEDED_TYPE,
            meta: { page: { maxSize: MAX_PAGE_SIZE } },
          )
        end

        size
      end

      def page_url(page)
        query = request.query_parameters.except("page")
        query["page"] = page if page.any?

        "#{request.base_url}#{request.path}?#{Rack::Utils.build_nested_query(query)}".delete_suffix("?")
      end

      def page_error(message, parameter)
        ParameterError.new(message, parameter:)
      end
    end
  end
end
