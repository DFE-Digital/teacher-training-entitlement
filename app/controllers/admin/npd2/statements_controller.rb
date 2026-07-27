class Admin::Npd2::StatementsController < AdminController
  def index
    @lead_providers = LeadProvider.order(:name)
    @lead_provider = @lead_providers.find_by(id: params[:lead_provider_id])
    @contracts = contracts_for(@lead_provider)
  end

  def create
    @contract = Contract.includes(course_cohorts: %i[course cohort]).find(params[:contract_id])
    @course_cohorts = @contract.course_cohorts
    @milestones = Milestone.where(course_cohort: @course_cohorts).includes(course_cohort: %i[course cohort])
    @declarations = Declaration
      .where(milestone: @milestones)
      .includes(:lead_provider, :delivery_partner, { milestone: { course_cohort: %i[course cohort] } }, application: :user)
      .order(:declaration_date, :id)
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
