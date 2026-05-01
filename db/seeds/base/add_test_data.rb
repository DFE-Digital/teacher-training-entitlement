LeadProvider.find_each do |lead_provider|
  ValidTestDataGenerators::APITestScenariosSeeder.new(lead_provider:).call
  ValidTestDataGenerators::APITestScenariosSeeder.new(
    lead_provider:,
    cohort_year: Time.zone.now.year - 2,
  ).custom_data(
    nb_cohort: 6,
    nb_app_per_state: 5,
  )
end
