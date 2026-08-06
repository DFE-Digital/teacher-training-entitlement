LeadProvider.find_each do |lead_provider|
  Course.find_each do |course|
    attr = FactoryBot.attributes_for(:contract_template, special_course: false)
    contract_template = ContractTemplate.find_or_create_by!(attr)

    Statement.where(lead_provider:).find_each do |statement|
      contract = Contract.find_or_initialize_by(
        statement:,
        course:,
      )

      next if contract.contract_template.present? || statement.paid? || statement.payable?

      contract.update!(contract_template:)
    end
  end
end
