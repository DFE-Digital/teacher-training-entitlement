CSV.read(Rails.root.join("db/seeds/data/private_childcare_providers.csv"), headers: true).tap do |data|
  import_count = 0

  data.each do |row|
    provider = PrivateChildcareProvider.find_or_initialize_by(id: row["id"])
    provider.assign_attributes(
      provider_urn: row["provider_urn"],
      local_authority: row["local_authority"],
      early_years_individual_registers: row["early_years_individual_registers"],
      provider_early_years_register_flag: row["provider_early_years_register_flag"],
      provider_compulsory_childcare_register_flag: row["provider_compulsory_childcare_register_flag"],
      created_at: row["created_at"],
      updated_at: row["updated_at"],
    )
    provider.save!

    provider.institution || provider.create_institution!(
      name: row["provider_name"],
      address_1: row["address_1"],
      address_2: row["address_2"],
      address_3: row["address_3"],
      town: row["town"],
      postcode: row["postcode"],
      postcode_without_spaces: row["postcode_without_spaces"],
      region: row["region"],
    )

    import_count += 1
    Rails.logger.info("Importing #{import_count} private childcare providers") if (import_count % 1000).zero?
  end

  Rails.logger.info("Importing #{import_count} private childcare providers")
end
