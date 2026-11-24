module API
  module V2
    # Keyset pagination for the JSON:API cursor pagination profile
    # (https://jsonapi.org/profiles/ethanresnick/cursor-pagination/).
    #
    # `keys` is the full sort order, ending with a unique tie-breaker, as
    # [{ name:, sql:, direction: :asc | :desc, type: :time | :uuid }, ...].
    # A cursor encodes the sort order and the key values of one row, so it stays valid
    # while rows change and is rejected if used with a different sort order.
    class CursorPaginator
      Page = Struct.new(:records, :next_cursor, :prev_cursor, keyword_init: true)

      class InvalidCursor < StandardError; end

      UUID_FORMAT = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/

      def initialize(scope:, keys:, size:, after: nil, before: nil)
        @scope = scope
        @keys = keys
        @size = size
        @after_cursor = after
        @before_cursor = before
        @after = decode(after) if after
        @before = decode(before) if before
      end

      def call
        before ? page_before : page_after
      end

    private

      attr_reader :scope, :keys, :size, :after, :before, :after_cursor, :before_cursor

      # An empty page after a cursor still links back to the results before that cursor.
      def page_after
        rows = fetch(direction: :forward, values: after)
        records = rows.first(size)

        Page.new(
          records:,
          next_cursor: (encode(records.last) if rows.size > size),
          prev_cursor: (cursor_or(records.first, after_cursor) if after),
        )
      end

      # An empty page before a cursor still links on to the results after that cursor.
      def page_before
        rows = fetch(direction: :backward, values: before)
        records = rows.first(size).reverse

        Page.new(
          records:,
          next_cursor: cursor_or(records.last, before_cursor),
          prev_cursor: (encode(records.first) if rows.size > size),
        )
      end

      def cursor_or(record, request_cursor)
        record ? encode(record) : request_cursor
      end

      def fetch(direction:, values:)
        relation = scope
          .select(*keys.each_with_index.map { |key, index| "#{key[:sql]} AS #{alias_for(index)}" })
          .reorder(Arel.sql(order_sql(direction)))
          .limit(size + 1)
        relation = relation.where(*keyset_condition(direction, values)) if values
        relation.to_a
      end

      def order_sql(direction)
        keys.map { |key| "#{key[:sql]} #{sql_direction(key, direction)}" }.join(", ")
      end

      def sql_direction(key, direction)
        ascending = (key[:direction] == :asc) == (direction == :forward)
        ascending ? "ASC" : "DESC"
      end

      # Rows strictly after the cursor in the given direction:
      # (k1 > v1) OR (k1 = v1 AND k2 > v2) OR ...
      def keyset_condition(direction, values)
        clauses = []
        binds = []

        keys.each_index do |index|
          equal = keys.first(index).map { |key| "#{key[:sql]} = ?" }
          operator = sql_direction(keys[index], direction) == "ASC" ? ">" : "<"
          clauses << "(#{(equal + ["#{keys[index][:sql]} #{operator} ?"]).join(' AND ')})"
          binds.concat(values.first(index + 1))
        end

        [clauses.join(" OR "), *binds]
      end

      def alias_for(index)
        "cursor_value_#{index}"
      end

      def signature
        keys.map { |key| "#{key[:name]}:#{key[:direction]}" }.join(",")
      end

      def encode(record)
        values = keys.each_index.map do |index|
          value = record[alias_for(index)]
          value.respond_to?(:iso8601) ? value.utc.iso8601(6) : value.to_s
        end

        Base64.urlsafe_encode64(JSON.generate("sort" => signature, "values" => values), padding: false)
      end

      def decode(cursor)
        payload = JSON.parse(Base64.urlsafe_decode64(cursor.to_s))
        raise InvalidCursor unless payload.is_a?(Hash) && payload["sort"] == signature

        values = payload["values"]
        raise InvalidCursor unless values.is_a?(Array) && values.size == keys.size && values.all?(String)

        keys.zip(values).map { |key, value| decode_value(key[:type], value) }
      rescue ArgumentError, JSON::ParserError
        raise InvalidCursor
      end

      def decode_value(type, value)
        case type
        when :time then Time.iso8601(value)
        when :uuid then value.match?(UUID_FORMAT) ? value : raise(InvalidCursor)
        end
      end
    end
  end
end
