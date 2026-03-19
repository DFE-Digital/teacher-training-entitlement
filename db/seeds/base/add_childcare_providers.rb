return if PrivateChildcareProvider.exists?

CSV.foreach(Rails.root.join("db/seeds/data/private_childcare_providers.csv"), headers: true).each_slice(1000) do |batch|
  provider_records = batch.map { |row| row.to_h.slice(*PrivateChildcareProvider.column_names) }
  PrivateChildcareProvider.insert_all(provider_records)

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
      institution_reference_number: row["provider_urn"],
      created_at: Time.current,
      updated_at: Time.current,
    }
  end

  Institution.insert_all(institution_records)

  Rails.logger.info("Imported #{batch.size} private childcare providers")
end
