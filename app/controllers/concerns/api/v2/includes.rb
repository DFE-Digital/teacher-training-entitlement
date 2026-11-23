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
          raise ActionController::BadRequest, I18n.t(:unsupported_include, paths: "include") unless raw.nil? || raw.is_a?(String)

          requested = raw.to_s.split(",").map(&:strip).uniq
          unsupported = requested - self.class::ALLOWED_INCLUDES
          raise ActionController::BadRequest, I18n.t(:unsupported_include, paths: unsupported.join(", ")) if unsupported.any?

          requested.map(&:to_sym)
        end
      end
    end
  end
end
