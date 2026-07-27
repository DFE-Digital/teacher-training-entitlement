LeadProvider.find_each do |lead_provider|
  Cohort.find_each do |cohort|
    Course.find_each do |course|
      attr = FactoryBot.attributes_for(:contract_template, special_course: false)
      contract_template = ContractTemplate.find_or_create_by!(attr)

      Statement.where(lead_provider:, cohort:).find_each do |statement|
        contract = Contract.find_or_initialize_by(
          statement:,
          course:,
        )
        contract.lead_provider = statement.lead_provider

        next if contract.contract_template.present? || statement.paid? || statement.payable?

        contract.update!(contract_template:)
      end
    end
  end
end
