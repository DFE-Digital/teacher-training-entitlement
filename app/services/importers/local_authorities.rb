require "csv"

class Importers::LocalAuthorities
  attr_reader :path_to_csv

  def initialize(path_to_csv:)
    @path_to_csv = path_to_csv
  end

  def call
    check_headers

    rows.each do |row|
      institution = Institution.find_by(institution_reference_number: row["ukprn"])
      la = institution&.institutionable || LocalAuthority.new

      la.update!(
        high_pupil_premium: ActiveModel::Type::Boolean.new.cast(row["high_pupil_premium"]),
      )

      update_institution!(la, row)
    end
  end

private

  def update_institution!(la, row)
    institution_attrs = {
      name: row["name"],
      address_1: row["address_1"],
      address_2: row["address_2"],
      address_3: row["address_3"],
      town: row["town"],
      county: row["county"],
      postcode: row["postcode"],
      postcode_without_spaces: row["postcode"]&.gsub(" ", ""),
      institution_reference_number: row["ukprn"],
    }

    if la.institution
      la.institution.update!(institution_attrs)
    else
      la.create_institution!(institution_attrs)
    end
  end

  def rows
    @rows ||= CSV.read(path_to_csv, headers: true)
  end

  def check_headers
    unless rows.headers == %w[ukprn name address_1 address_2 address_3 town county postcode high_pupil_premium]
      raise NameError, "Invalid headers"
    end
  end
end
