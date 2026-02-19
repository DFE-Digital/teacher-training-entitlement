class Admin::LeadProvidersController < AdminController
  def index
    @lead_providers = LeadProvider.all
  end

  def show
    @lead_provider = LeadProvider.find(params[:id])
    @cohort = Cohort.order_by_latest.first
    redirect_to admin_lead_provider_cohort_path(@lead_provider, @cohort)
  end
end
