class Institution < ApplicationRecord
  include PgSearch::Model

  PRIVATE_INSTITUTION = "private_institution".freeze
  STATE_FUNDED_INSTITUTION = "state_funded_institution".freeze
  OTHER = "other".freeze
  ALL_SETTINGS = [PRIVATE_INSTITUTION, STATE_FUNDED_INSTITUTION, OTHER].freeze

  REDACTED_DATA_STRING = "REDACTED".freeze
  TYPES = %w[School PrivateChildcareProvider LocalAuthority].freeze

  delegated_type :institutionable, types: TYPES, dependent: :destroy

  NAME_SYNONYMS = { "saint" => "st", "st" => "saint" }.freeze
  SEARCH_LIMIT = 100

  validates :institution_reference_number, presence: true

  pg_search_scope :base_search,
                  against: %i[name postcode postcode_without_spaces],
                  using: { tsearch: { prefix: true, dictionary: "english", tsvector_column: "search_vector" } }

  scope :open_school_or_non_school, lambda {
    open_school_institution_ids = School.open.joins(:institution).select("institutions.id")
    where.not(institutionable_type: "School").or(where(id: open_school_institution_ids))
  }

  delegate :in_england?, :identifier, :eligible_establishment?, to: :institutionable

  def self.search(search_term)
    return none if search_term.blank?

    text_matches = base_search(search_term)
    urn_matches = where("institution_reference_number ILIKE ?", "#{sanitize_sql_like(search_term)}%")
    scope = where(id: text_matches.select(:id)).or(where(id: urn_matches.select(:id))).limit(SEARCH_LIMIT)

    NAME_SYNONYMS.each do |key, value|
      next unless search_term.downcase.match?(/\b#{key}\b/i)

      synonym_term = search_term.downcase.gsub(key, value)
      synonym_matches = base_search(synonym_term)
      synonym_scope = where(id: synonym_matches.select(:id)).limit(SEARCH_LIMIT)
      return scope.or(synonym_scope).limit(SEARCH_LIMIT)
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
