module API
  module V2
    # A 400 caused by one query parameter. Rendered as a JSON:API error object whose
    # `source.parameter` names the parameter; `type` and `meta` carry the extra members
    # required by the cursor pagination profile.
    class ParameterError < ActionController::BadRequest
      attr_reader :parameter, :type, :meta

      def initialize(message, parameter:, type: nil, meta: nil)
        super(message)
        @parameter = parameter
        @type = type
        @meta = meta
      end

      def to_error_object
        {
          status: "400",
          title: I18n.t(:bad_request),
          detail: message,
          source: { parameter: },
          links: ({ type: [type] } if type),
          meta:,
        }.compact
      end
    end
  end
end
