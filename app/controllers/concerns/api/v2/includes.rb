module API
  module V2
    # Opt-in JSON:API `include` handling. Each controller declares its allow-list
    # with `allowed_includes`; nested paths are only accepted if listed in full.
    # Call `requested_includes` before loading or traversing any association.
    module Includes
      extend ActiveSupport::Concern

      class_methods do
        def allowed_includes(*paths)
          const_set(:ALLOWED_INCLUDES, paths.map(&:to_s).freeze)
        end
      end

    private

      def requested_includes
        @requested_includes ||= begin
          raw = params[:include]
          raise include_error(I18n.t(:invalid_include_format)) unless raw.nil? || raw.is_a?(String)

          requested = raw.to_s.split(",", -1).map(&:strip)
          raise include_error(I18n.t(:blank_include_path)) if requested.any?(&:blank?)

          unsupported = requested.uniq - self.class::ALLOWED_INCLUDES
          raise include_error(I18n.t(:unsupported_include, paths: unsupported.join(", "))) if unsupported.any?

          requested.uniq.map(&:to_sym)
        end
      end

      def include_error(message)
        ParameterError.new(message, parameter: "include")
      end
    end
  end
end
