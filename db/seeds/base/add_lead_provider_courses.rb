LeadProvider.find_each do |lead_provider|
  Course.find_each do |course|
    # setup lead_provider_course details
    contract_year = ContractYear.find_by(lead_provider:, course:, academic_year: nil)
    recruitment_target = [].sample
    teacher_funding = [].sample
    service_fee = [].sample
    lp_domain = ValidTestDataGenerators::APITestScenariosSeeder.to_dns_name(lead_provider.name)
    course_url = "https://#{lp_domain}.com/#{course.identifier}"
    email = "#{course.identifier}@#{lp_domain}.com"
    if contract_year
      contract_year.update!(
        course_url:,
        email:,
        recruitment_target:,
        teacher_funding:,
        service_fee:,
      )
    else
      ContractYear.create!(
        lead_provider:,
        course:,
        academic_year: nil,
        course_url:,
        email:,
        recruitment_target:,
        teacher_funding:,
        service_fee:,
      )
    end
  end
end
