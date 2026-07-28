class Admin::Npd2::StatementsController < AdminController
  def index
    @lead_providers = LeadProvider.order(:name)
    @lead_provider = @lead_providers.find_by(id: params[:lead_provider_id])
    @contracts = contracts_for(@lead_provider)
  end

  def create
    @from_date = date_param(:from_date)
    @to_date = date_param(:to_date)
    @contract = Contract.includes(course_cohorts: %i[course cohort]).find(params[:contract_id])
    @course_cohorts = filter_course_cohorts(@contract.course_cohorts.includes(:course, :cohort))
    @milestones = Milestone.where(course_cohort: @course_cohorts).includes(course_cohort: %i[course cohort])
    @declarations = filter_declarations(
      Declaration
      .where(milestone: @milestones)
      .includes(:lead_provider, :delivery_partner, { milestone: { course_cohort: %i[course cohort] } }, application: :user),
    ).order(:declaration_date, :id)
  end

private

  def contracts_for(lead_provider)
    return Contract.none unless lead_provider

    lead_provider
      .contracts
      .includes(course_cohorts: %i[course cohort])
      .order(:id)
  end

  def filter_declarations(scope)
    scope = scope.where(declaration_date: @from_date.beginning_of_day..) if @from_date
    scope = scope.where(declaration_date: ..@to_date.end_of_day) if @to_date
    scope
  end

  def filter_course_cohorts(scope)
    scope = scope.where(training_ends_at: @from_date.beginning_of_day..) if @from_date
    scope = scope.where(training_starts_at: ..@to_date.end_of_day) if @to_date
    scope
  end

  def date_param(name)
    direct_date_param(name)
  rescue Date::Error
    nil
  end

  def direct_date_param(name)
    value = params[name]
    return if value.blank?

    Date.parse(value)
  end
end
