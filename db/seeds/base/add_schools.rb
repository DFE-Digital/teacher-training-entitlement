return if School.exists?

CSV.foreach(Rails.root.join("db/seeds/data/schools.csv"), headers: true).each_slice(1000) do |batch|
  school_records = batch.map { |row| row.to_h.slice(*School.column_names) }
  result = School.insert_all(school_records, returning: %w[id])
  school_ids = result.map { |row| row["id"] }

  institution_records = batch.each_with_index.map do |row, index|
    {
      institutionable_type: "School",
      institutionable_id: school_ids[index],
      name: row["name"],
      address_1: row["address_1"],
      address_2: row["address_2"],
      address_3: row["address_3"],
      town: row["town"],
      county: row["county"],
      postcode: row["postcode"],
      postcode_without_spaces: row["postcode_without_spaces"],
      region: row["region"],
      institution_reference_number: row["urn"],
      created_at: Time.current,
      updated_at: Time.current,
    }
  end

  Institution.insert_all(institution_records)

  Rails.logger.info("Imported #{batch.size} schools")
end
