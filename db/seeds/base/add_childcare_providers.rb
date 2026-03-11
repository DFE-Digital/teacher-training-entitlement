import_count = 0
now = Time.current

CSV.foreach(Rails.root.join("db/seeds/data/private_childcare_providers.csv"), headers: true).each_slice(1000) do |batch|
  provider_records = batch.map do |row|
    {
      id: row["id"],
      provider_urn: row["provider_urn"],
      local_authority: row["local_authority"],
      early_years_individual_registers: row["early_years_individual_registers"],
      provider_early_years_register_flag: row["provider_early_years_register_flag"],
      provider_compulsory_childcare_register_flag: row["provider_compulsory_childcare_register_flag"],
      created_at: row["created_at"] || now,
      updated_at: now,
    }
  end

  institution_records = batch.map do |row|
    {
      institutionable_type: "PrivateChildcareProvider",
      institutionable_id: row["id"],
      name: row["provider_name"],
      address_1: row["address_1"],
      address_2: row["address_2"],
      address_3: row["address_3"],
      town: row["town"],
      postcode: row["postcode"],
      postcode_without_spaces: row["postcode_without_spaces"],
      region: row["region"],
      created_at: now,
      updated_at: now,
    }
  end

  PrivateChildcareProvider.upsert_all(provider_records, unique_by: :id)
  Institution.upsert_all(institution_records, unique_by: %i[institutionable_type institutionable_id])

  import_count += batch.size
  Rails.logger.info("Importing #{import_count} private childcare providers")
end

Rails.logger.info("Imported #{import_count} private childcare providers")
