class CustomDataSeederJob < ApplicationJob
  queue_as :default

  def perform(lead_provider:, academic_year:, nb_cohort:, nb_app_per_state:)
    course = Course.find_by!(identifier: Course::TTE_EARLY_YEARS)
    seeder = ValidTestDataGenerators::APITestScenariosSeeder.new(lead_provider:, course:, academic_year:)

    seeder.custom_data(nb_cohort:, nb_app_per_state:)
  end
end
