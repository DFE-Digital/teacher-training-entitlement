module Admin
  class LeadProvidersController < AdminController
    include Cohortable

    def index
      service = LeadProvidersQuery.new(cohort: @current_cohort, academic_year: @current_academic_year)
      service.call
      @resources = service.resources
    end

    def show
      @lead_provider = LeadProvider.find(params[:id])
      service = LeadProviderShowQuery.new(
        lead_provider: @lead_provider,
        cohort: @current_cohort,
        academic_year: @current_academic_year,
      )
      service.call
      @pagy_applications, @applications = pagy(service.details[:applications], items: 25)
      @pagy_delivery_partners, @delivery_partners = pagy(service.details[:delivery_partners])
      @pagy_statements, @statements = pagy(service.details[:statements])
    end

    def edit
      @lead_provider = LeadProvider.find(params[:id])
    end

    def update
      @lead_provider = LeadProvider.find(params[:id])

      if @lead_provider.update(lead_provider_params)
        redirect_to admin_lead_provider_path(@lead_provider), flash: { success: "Provider updated" }
      else
        render :edit, status: :unprocessable_content
      end
    end

  private

    def lead_provider_params
      params.require(:lead_provider).permit(:name, :email, :hint, :url)
    end

    def default_academic_year_actions
      %i[index show]
    end
  end
end
