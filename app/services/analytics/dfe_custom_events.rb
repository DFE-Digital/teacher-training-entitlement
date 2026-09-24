module Analytics
  class DfeCustomEvents
    NAMESPACE = "tte".freeze

    def initialize(type:, request:, user: nil, data: {})
      @type = type
      @request = request
      @user = user
      @data = data
    end

    def send_event
      event = DfE::Analytics::Event.new
        .with_type(type)
        .with_namespace(NAMESPACE)
        .with_request_details(request)
        .with_data(data: data)

      event.with_user(user) if user

      DfE::Analytics::SendEvents.do([event])
    rescue StandardError => e
      Rails.logger.warn("Failed to send DfE custom analytics event: #{e.class}: #{e.message}")
    end

  private

    attr_reader :type, :request, :user, :data
  end
end
