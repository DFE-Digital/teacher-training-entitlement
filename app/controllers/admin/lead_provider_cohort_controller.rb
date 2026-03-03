class Admin::LeadProviderCohortController < AdminController
  def show
    @lead_provider = LeadProvider.find(params[:lead_provider_id])
    @cohort = Cohort.find(params[:id])
    @pagy, @delivery_partners = pagy(@lead_provider.delivery_partners_for_cohort(@cohort))
  end
end
