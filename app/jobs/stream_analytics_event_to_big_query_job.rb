class StreamAnalyticsEventToBigQueryJob < ApplicationJob
  EVENT_NAMESPACE = "tte".freeze
  VERSION_EVENT_NAMESPACE = "npq".freeze

  self.log_arguments = false

  queue_as :low_priority

  def self.send_event(type:, request: nil, user: nil, data: {})
    event = DfE::Analytics::Event.new
      .with_type(type)
      .with_namespace(type == :version ? VERSION_EVENT_NAMESPACE : EVENT_NAMESPACE)
      .with_data(data:)

    event.with_user(user) if user
    event.with_request_details(request) if request

    perform_later(event.as_json)
  end

  def perform(event)
    DfE::Analytics::SendEvents.do([event])
  end
end
