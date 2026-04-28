require_relative "call_api"

class ShowApplication
  include CallApi
  include Rails.application.routes.url_helpers

  def initialize(application: nil, lead_provider: nil)
    @application = application || Application.last
    @lead_provider = lead_provider || @application&.lead_provider
  end

  def call
    if @lead_provider.nil?
      raise "[ShowApplication] Could not find a lead provider"
    end

    if @application.nil?
      raise "[ShowApplication] Could not find an application"
    end

    api_get(lead_provider: @lead_provider, url: api_v1_application_path(@application.ecf_id))
  end
end
