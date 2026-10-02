module Admin::Settings
  class LeadProvidersController < AdminController
    before_action :require_super_admin
    before_action :set_lead_provider, only: %i[show edit update]

    def index
      @lead_providers = LeadProvider.all.map do |lead_provider|
        {
          lead_provider:,
          active: APIToken.where(lead_provider: lead_provider).exists?,
        }
      end
    end

    def new
      @lead_provider = LeadProvider.new
    end

    def create
      @lead_provider = LeadProvider.new(lead_provider_params)
      if @lead_provider.valid?
        @lead_provider.save!
        redirect_to admin_settings_lead_provider_path(@lead_provider)
      else
        render :new
      end
    end

    def show
      @display_api_integration_actions = Rails.env.in?(%w[development review sandbox])
      if @display_api_integration_actions
        @application_data = ValidTestDataGenerators::APITestScenariosSeeder.applications_data
      end
      @active = APIToken.where(lead_provider: @lead_provider).exists?
      @pagy, @delivery_partners = pagy(@lead_provider.delivery_partners, limit: 10)
    end

    def edit; end

    def update; end

  private

    def set_lead_provider
      @lead_provider = LeadProvider.find(params[:id])
    end

    def lead_provider_params
      params.require(:lead_provider).permit(:name)
    end
  end
end
