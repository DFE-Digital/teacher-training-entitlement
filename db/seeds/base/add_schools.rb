import_count = 0
now = Time.current
urn_to_id = {}

CSV.foreach(Rails.root.join("db/seeds/data/schools.csv"), headers: true).each_slice(1000) do |batch|
  school_records = batch.map do |row|
    {
      urn: row["urn"],
      la_code: row["la_code"],
      la_name: row["la_name"],
      close_date: row["close_date"],
      ukprn: row["ukprn"],
      last_changed_date: row["last_changed_date"],
      establishment_type_code: row["establishment_type_code"],
      establishment_type_name: row["establishment_type_name"],
      establishment_status_code: row["establishment_status_code"],
      establishment_status_name: row["establishment_status_name"],
      high_pupil_premium: row["high_pupil_premium"] || false,
      number_of_pupils: row["number_of_pupils"],
      eyl_funding_eligible: row["eyl_funding_eligible"] || false,
      phase_type: row["phase_type"] || 0,
      phase_name: row["phase_name"] || "Not applicable",
      created_at: row["created_at"] || now,
      updated_at: now,
    }
  end

  result = School.upsert_all(school_records, unique_by: :urn, returning: %w[id urn])
  result.each { |s| urn_to_id[s["urn"]] = s["id"] }

  institution_records = batch.map do |row|
    {
      institutionable_type: "School",
      institutionable_id: urn_to_id[row["urn"]],
      name: row["name"],
      address_1: row["address_1"],
      address_2: row["address_2"],
      address_3: row["address_3"],
      town: row["town"],
      county: row["county"],
      postcode: row["postcode"],
      postcode_without_spaces: row["postcode_without_spaces"],
      region: row["region"],
      created_at: now,
      updated_at: now,
    }
  end

  Institution.upsert_all(institution_records, unique_by: %i[institutionable_type institutionable_id])

  import_count += batch.size
  Rails.logger.info("Importing #{import_count} schools")
end

Rails.logger.info("Imported #{import_count} schools")
