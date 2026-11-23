module API
  module V2
    # Strict `filter[...]` parsing: filters must be a flat hash of the controller's
    # supported keys with string values. Invalid input raises a 400.
    module Filters
      extend ActiveSupport::Concern

      UUID_FORMAT = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/
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

        raise ActionController::BadRequest, I18n.t(:invalid_filter_structure) unless raw.is_a?(ActionController::Parameters)

        unsupported = raw.keys.map(&:to_sym) - self.class::ALLOWED_FILTERS
        raise ActionController::BadRequest, I18n.t(:unsupported_filters, keys: unsupported.join(", ")) if unsupported.any?
        raise ActionController::BadRequest, I18n.t(:invalid_filter_structure) unless raw.values.all?(String)

        raw.to_unsafe_h.symbolize_keys
      end

      # Comma-separated list; every value must be allowed and match the format.
      def list_filter(name, allowed: nil, format: nil)
        value = filter_params[name]
        return if value.blank?

        values = value.split(",")
        invalid = values.reject { |v| (allowed.nil? || allowed.include?(v)) && (format.nil? || v.match?(format)) }
        raise ActionController::BadRequest, I18n.t(:invalid_filter, attribute: name) if invalid.any?

        values
      end

      def boolean_filter(name)
        value = filter_params[name]
        return if value.blank?

        BOOLEAN_VALUES.fetch(value) { raise ActionController::BadRequest, I18n.t(:invalid_filter, attribute: name) }
      end

      def time_filter(name)
        value = filter_params[name]
        return if value.blank?

        Time.iso8601(value)
      rescue ArgumentError
        raise ActionController::BadRequest, I18n.t(:invalid_date_filter, parameterized_attribute: name)
      end
    end
  end
end
