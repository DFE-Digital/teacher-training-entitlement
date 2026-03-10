CSV.read(Rails.root.join("db/seeds/data/schools.csv"), headers: true).tap do |data|
  import_count = 0

  data.each do |row|
    school = School.find_or_initialize_by(urn: row["urn"])
    school.assign_attributes(
      la_code: row["la_code"],
      la_name: row["la_name"],
      close_date: row["close_date"],
      ukprn: row["ukprn"],
      last_changed_date: row["last_changed_date"],
      establishment_type_code: row["establishment_type_code"],
      establishment_type_name: row["establishment_type_name"],
      establishment_status_code: row["establishment_status_code"],
      establishment_status_name: row["establishment_status_name"],
      high_pupil_premium: row["high_pupil_premium"],
      number_of_pupils: row["number_of_pupils"],
      eyl_funding_eligible: row["eyl_funding_eligible"],
      phase_type: row["phase_type"],
      phase_name: row["phase_name"],
      created_at: row["created_at"],
      updated_at: row["updated_at"],
    )
    school.save!

    school.institution || school.create_institution!(
      name: row["name"],
      address_1: row["address_1"],
      address_2: row["address_2"],
      address_3: row["address_3"],
      town: row["town"],
      county: row["county"],
      postcode: row["postcode"],
      postcode_without_spaces: row["postcode_without_spaces"],
      region: row["region"],
    )

    import_count += 1
    Rails.logger.info("Importing #{import_count} schools") if (import_count % 1000).zero?
  end

  Rails.logger.info("Importing #{import_count} schools")
end
