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

    outcome = ValidTestDataGenerators::APITestScenariosSeeder.new(lead_provider: lead_provider).call

    if outcome.success
      flash[:success] = "API test scenarios seeded successfully for #{lead_provider.name}. Created #{outcome.applications_count} applications."
    else
      flash[:error] = "Failed to seed data"
    end

    redirect_to admin_api_test_scenarios_path
  end

private

  def check_environment
    unless Rails.env.in?(%w[development review sandbox])
      flash[:negative] = {
        title: "Unauthorized",
        text: "API test scenarios seeding is only available in development, review, and sandbox environments",
      }
      redirect_to admin_path
    end
  end

  def test_applications_count(lead_provider)
    seeder = ValidTestDataGenerators::APITestScenariosSeeder.new(lead_provider:)
    Application.joins(:user)
      .where(lead_provider:)
      .where(users: { email: seeder.test_emails })
      .count
  end
end
