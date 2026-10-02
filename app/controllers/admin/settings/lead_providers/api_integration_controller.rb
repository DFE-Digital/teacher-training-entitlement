# frozen_string_literal: true

class Admin::Settings::LeadProviders::APIIntegrationController < AdminController
  before_action :check_environment
  before_action :require_super_admin
  before_action :set_lead_provider, only: %i[create_test_data create_development_data]

  def create_test_data
    service = ValidTestDataGenerators::APITestScenariosSeeder.new(lead_provider: @lead_provider)
    outcome = service.call

    if outcome.success
      flash[:success] = "API test scenarios seeded successfully for #{@lead_provider.name}. Created #{outcome.applications_count} applications."
    else
      flash[:error] = "Failed to seed data"
    end

    redirect_to admin_settings_lead_provider_path(@lead_provider)
  end

  def create_development_data
    # this job will create 2 cohorts (autumn, spring) per year; starting from 2 year ago
    CustomDataSeederJob.perform_later(
      lead_provider: @lead_provider,
      academic_year: params[:start_year] || Time.zone.now.year - 2,
      nb_cohort: params[:nb_cohort] || 6,
      nb_app_per_state: params[:nb_app_per_state] || 20,
    )
    flash[:success] = "Development dataset will be created"
    redirect_to admin_settings_lead_provider_path(@lead_provider)
  end

private

  def set_lead_provider
    @lead_provider = LeadProvider.find(params[:id])
  end

  def check_environment
    unless Rails.env.in?(%w[development review sandbox])
      flash[:alert] = {
        title: "Unauthorized",
        message: "API test scenarios seeding is only available in development, review, and sandbox environments",
      }
      redirect_to admin_path
    end
  end
end
