LeadProvider.find_each do |lead_provider|
  ValidTestDataGenerators::APITestScenariosSeeder.new(lead_provider: lead_provider).call
end
