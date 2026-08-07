# frozen_string_literal: true

class Admin::APITestScenariosController < AdminController
  before_action :require_super_admin
  before_action :check_environment

  def index
    @application_data = ValidTestDataGenerators::APITestScenariosSeeder.applications_data
    @lead_providers = LeadProvider.order(:name).map do |provider|
      applications_count = test_applications_count(provider)
      {
        provider: provider,
        seeded: applications_count.positive?,
        applications_count:,
      }
    end
  end

  def create
    lead_provider = LeadProvider.find(params[:lead_provider_id])

    outcome = ValidTestDataGenerators::APITestScenariosSeeder.new(lead_provider:).call

    if outcome.success
      flash[:success] = "API test scenarios seeded successfully for #{lead_provider.name}. Created #{outcome.applications_count} applications."
    else
      flash[:error] = "Failed to seed data"
    end

    redirect_to admin_api_test_scenarios_path
  end

  def create_custom_data
    # this job will create 2 cohorts (autumn, spring) per year; starting from 2 year ago
    CustomDataSeederJob.perform_later(
      lead_provider: LeadProvider.find_by!(id: params[:lead_provider_id]),
      academic_year: params[:start_year] || Time.zone.now.year - 2,
      nb_cohort: params[:nb_cohort] || 6,
      nb_app_per_state: params[:nb_app_per_state] || 20,
    )
    redirect_to admin_api_test_scenarios_path
  end

private

  def check_environment
    unless Rails.env.in?(%w[development review sandbox])
      flash[:alert] = {
        title: "Unauthorized",
        message: "API test scenarios seeding is only available in development, review, and sandbox environments",
      }
      redirect_to admin_path
    end
  end

  def test_applications_count(lead_provider)
    seeder = ValidTestDataGenerators::APITestScenariosSeeder.new(lead_provider:)
    lead_provider
      .applications
      .joins(:user)
      .merge(ApplicationLeadProvider.current)
      .where(users: { ecf_id: seeder.test_user_ecf_ids })
      .count
  end
end
