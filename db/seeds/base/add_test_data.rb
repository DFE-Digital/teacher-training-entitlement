LeadProvider.find_each do |lead_provider|
  seeder = ValidTestDataGenerators::APITestScenariosSeeder.new(
    lead_provider:,
    cohort_year: Time.zone.now.year - 2,
  )

  seeder.call

  seeder.custom_data(
    nb_cohort: 6,
    nb_app_per_state: 20,
  )
end
