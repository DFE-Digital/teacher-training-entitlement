require_relative "call_api"

class ListApplications
  include CallApi
  include Rails.application.routes.url_helpers

  def initialize(lead_provider: nil, filters: {})
    @lead_provider = lead_provider || LeadProvider.last
    @filters = filters
  end

  def call
    if @lead_provider.nil?
      raise "[ListApplications] Could not find a lead provider"
    end

    api_get(lead_provider: @lead_provider, url: api_v1_applications_path(filter: @filters))
  end
end
