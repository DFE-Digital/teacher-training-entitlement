module API
  module V2
    # `sort` parameter in the V1 syntax: a comma-separated list of fields, each optionally
    # prefixed with + (ascending, the default) or - (descending). Each controller declares
    # its sortable fields and default; anything else is rejected with a 400.
    module Sorting
      extend ActiveSupport::Concern

      SORT_DIRECTIONS = { "+" => :asc, "-" => :desc }.freeze
      UNSUPPORTED_SORT_TYPE = "https://jsonapi.org/profiles/ethanresnick/cursor-pagination/unsupported-sort".freeze

      class_methods do
        def allowed_sorts(*fields, default:)
          const_set(:ALLOWED_SORTS, fields.map(&:to_s).freeze)
          const_set(:DEFAULT_SORT, default)
        end
      end

    private

      # => [["updated_at", :asc], ...]
      def requested_sort
        @requested_sort ||= parse_sort(params.fetch(:sort, self.class::DEFAULT_SORT))
      end

      def parse_sort(raw)
        raise sort_error unless raw.is_a?(String)

        sort = raw.split(",", -1).map { |part| parse_sort_part(part.strip) }
        raise sort_error if sort.empty? || sort.map(&:first).uniq.size != sort.size

        sort
      end

      def parse_sort_part(part)
        direction = SORT_DIRECTIONS.fetch(part[0], nil)
        field = direction ? part[1..] : part
        raise sort_error unless self.class::ALLOWED_SORTS.include?(field)

        [field, direction || :asc]
      end

      def sort_error
        ParameterError.new(
          I18n.t(:invalid_sort, fields: self.class::ALLOWED_SORTS.join(", ")),
          parameter: "sort",
          type: UNSUPPORTED_SORT_TYPE,
        )
      end
    end
  end
end
