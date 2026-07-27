class Admin::Npd2::StatementsController < AdminController
  def index
    @lead_providers = LeadProvider.order(:name)
    @lead_provider = @lead_providers.find_by(id: params[:lead_provider_id])
    @contracts = contracts_for(@lead_provider)
  end

private

  def contracts_for(lead_provider)
    return Contract.none unless lead_provider

    lead_provider
      .contracts
      .includes(course_cohorts: %i[course cohort])
      .order(:id)
  end
end
