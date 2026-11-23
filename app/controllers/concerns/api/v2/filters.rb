module API
  module V2
    # Strict `filter[...]` parsing: filters must be a flat hash of the controller's
    # supported keys with string values. Invalid input raises a 400.
    module Filters
      extend ActiveSupport::Concern

      UUID_FORMAT = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/
      # Same rule as ValidTrnValidator: seven digits.
      TRN_FORMAT = /\A\d{7}\z/
      EMAIL_FORMAT = ->(value) { NotifyEmailValidator.valid?(value) }
      BOOLEAN_VALUES = { "true" => true, "false" => false }.freeze

      class_methods do
        def allowed_filters(*keys)
          const_set(:ALLOWED_FILTERS, keys.freeze)
        end
      end

    private

      def filter_params
        @filter_params ||= validated_filters(params[:filter])
      end

      def validated_filters(raw)
        return {} if raw.nil?

        raise filter_error(I18n.t(:invalid_filter_structure), "filter") unless raw.is_a?(ActionController::Parameters)

        unsupported = raw.keys.map(&:to_sym) - self.class::ALLOWED_FILTERS
        raise filter_error(I18n.t(:unsupported_filters, keys: unsupported.join(", ")), "filter") if unsupported.any?
        raise filter_error(I18n.t(:invalid_filter_structure), "filter") unless raw.values.all?(String)

        raw.to_unsafe_h.symbolize_keys
      end

      # Comma-separated list; every value must be allowed and match the format
      # (a Regexp, or a callable returning true for valid values).
      def list_filter(name, allowed: nil, format: nil)
        value = filter_params[name]
        return if value.blank?

        values = value.split(",")
        invalid = values.reject { |v| (allowed.nil? || allowed.include?(v)) && matches_format?(v, format) }
        raise filter_error(I18n.t(:invalid_filter, attribute: name), "filter[#{name}]") if invalid.any?

        values
      end

      def boolean_filter(name)
        value = filter_params[name]
        return if value.blank?

        BOOLEAN_VALUES.fetch(value) { raise filter_error(I18n.t(:invalid_filter, attribute: name), "filter[#{name}]") }
      end

      def time_filter(name)
        value = filter_params[name]
        return if value.blank?

        Time.iso8601(value)
      rescue ArgumentError
        raise filter_error(I18n.t(:invalid_timestamp_filter, attribute: name), "filter[#{name}]")
      end

      def matches_format?(value, format)
        case format
        when nil then true
        when Regexp then value.match?(format)
        else format.call(value)
        end
      end

      def filter_error(message, parameter)
        ParameterError.new(message, parameter:)
      end
    end
  end
end
