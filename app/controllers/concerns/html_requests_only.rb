module HtmlRequestsOnly
  extend ActiveSupport::Concern

  included do
    before_action :ensure_html_request
  end

private

  def ensure_html_request
    raise ActionController::RoutingError, "Not Found" unless request.format.html?
  end
end
