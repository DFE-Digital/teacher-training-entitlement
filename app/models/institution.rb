class Institution < ApplicationRecord
  include PgSearch::Model

  REDACTED_DATA_STRING = "REDACTED".freeze

  delegated_type :institutionable, types: %w[School PrivateChildcareProvider LocalAuthority], dependent: :destroy

  NAME_SYNONYMS = { "saint" => "st", "st" => "saint" }.freeze
  SEARCH_LIMIT = 100

  validates :institution_reference_number, presence: true

  pg_search_scope :base_search_by_name,
                  against: %i[name address_1 address_2 address_3 town county postcode postcode_without_spaces region],
                  using: {
                    tsearch: {
                      prefix: true,
                      dictionary: "english",
                    },
                  }

  scope :open_school_or_non_school, lambda {
    open_school_institution_ids = School.open.joins(:institution).select("institutions.id")
    where.not(institutionable_type: "School").or(where(id: open_school_institution_ids))
  }

  delegate :in_england?, :identifier, :eligible_establishment?, to: :institutionable

  def self.search_all_fields(search_term)
    name_address_matches = base_search_by_name(search_term)
    la_name_matches = joins(
      "LEFT JOIN schools ON institutions.institutionable_type = 'School' AND institutions.institutionable_id = schools.id",
    ).where("schools.la_name ILIKE ?", "%#{search_term}%")
    urn_matches = where("institution_reference_number ILIKE ?", "%#{search_term}%")

    where(id: name_address_matches.select(:id))
      .or(where(id: la_name_matches.select(:id)))
      .or(where(id: urn_matches.select(:id)))
  end

  def self.search_by_name(search_term)
    scope = search_all_fields(search_term).limit(SEARCH_LIMIT)
    NAME_SYNONYMS.each do |key, value|
      next unless search_term&.downcase&.match?(/\b#{key}\b/i)

      synonym_term = search_term.downcase.gsub(key, value)
      synonym_scope = search_all_fields(synonym_term).limit(SEARCH_LIMIT)
      return where(id: scope.select(:id)).or(where(id: synonym_scope.select(:id))).limit(SEARCH_LIMIT)
    end
    scope
  end

  def urn
    institution_reference_number
  end

  def ukprn
    return institution_reference_number if local_authority?

    school&.ukprn
  end

  def name
    raw_name = self[:name]
    raw_name unless raw_name == REDACTED_DATA_STRING
  end

  def address
    [address_1, address_2, address_3, town, county, region, postcode].reject(&:blank?) - [REDACTED_DATA_STRING]
  end

  def address_string
    address.join(", ")
  end

  def display_name
    name
  end

  def name_with_address
    [name, address_string].join(" – ")
  end
end
