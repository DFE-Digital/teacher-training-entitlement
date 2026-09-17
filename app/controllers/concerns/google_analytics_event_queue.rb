module GoogleAnalyticsEventQueue
  extend ActiveSupport::Concern

private

  def queue_google_analytics_event(event_name:, page_path:)
    session[:google_analytics_events] ||= []
    session[:google_analytics_events] << { event_name:, params: { page_path: } }
  end
end
