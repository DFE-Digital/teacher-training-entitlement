class Institution < ApplicationRecord
  include PgSearch::Model

  PRIVATE_INSTITUTION = "private_institution".freeze
  STATE_FUNDED_INSTITUTION = "state_funded_institution".freeze
  OTHER = "other".freeze
  ALL_SETTINGS = [PRIVATE_INSTITUTION, STATE_FUNDED_INSTITUTION, OTHER].freeze

  REDACTED_DATA_STRING = "REDACTED".freeze
  TYPES = %w[School PrivateChildcareProvider LocalAuthority].freeze
  UK_COUNTRY_CODE = "GBR".freeze
  CROWN_DEPENDENCY_COUNTRY_CODES = %w[JEY GGY IMN].freeze
  ENGLAND_SUBDIVISION_CODE = "ENG".freeze
  WALES_SUBDIVISION_CODE = "WLS".freeze

  STATE_FUNDED = "state_funded".freeze
  FURTHER_EDUCATION = "further_education".freeze
  YOUNG_OFFENDER_INSTITUTION = "young_offender_institution".freeze
  HOSPITAL = "hospital".freeze
  MOD_OVERSEAS = "mod_overseas".freeze
  VIRTUAL_SCHOOL = "virtual_school".freeze
  LOCAL_AUTHORITY = "local_authority".freeze
  PRIVATE_CHILDCARE_PROVIDER = "private_childcare_provider".freeze

  # Ordered list of institution_type slugs. This is the selector evaluation order:
  # the first selector that matches a row assigns its slug. A GIAS row matching
  # no selector defaults to STATE_FUNDED.
  INSTITUTION_TYPES = [
    STATE_FUNDED,
    FURTHER_EDUCATION,
    YOUNG_OFFENDER_INSTITUTION,
    HOSPITAL,
    MOD_OVERSEAS,
    VIRTUAL_SCHOOL,
    LOCAL_AUTHORITY,
    PRIVATE_CHILDCARE_PROVIDER,
  ].freeze

  # Maps institution_type to the legacy API v1 institution_type value.
  # Any slug not listed here is emitted unchanged.
  API_INSTITUTION_TYPE_MAPPING = {
    STATE_FUNDED => "school",
    LOCAL_AUTHORITY => "localauthority",
    PRIVATE_CHILDCARE_PROVIDER => "privatechildcareprovider",
  }.tap { |mapping| mapping.default_proc = ->(_hash, slug) { slug } }.freeze

  delegated_type :institutionable, types: TYPES, dependent: :destroy

  NAME_SYNONYMS = { "saint" => "st", "st" => "saint" }.freeze
  SEARCH_LIMIT = 100

  validates :institution_reference_number, presence: true
  validates :alpha3_country_code, :subdivision_code, length: { is: 3 }, allow_nil: true

  pg_search_scope :base_search,
                  against: %i[name postcode postcode_without_spaces],
                  using: { tsearch: { prefix: true, dictionary: "english", tsvector_column: "search_vector" } }

  scope :open_school_or_non_school, lambda {
    open_school_institution_ids = School.open.joins(:institution).select("institutions.id")
    where.not(institutionable_type: "School").or(where(id: open_school_institution_ids))
  }

  delegate :identifier, :eligible_establishment?, to: :institutionable

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

  def country_long_name
    return if alpha3_country_code.blank?

    ISO3166::Country.find_country_by_alpha3(alpha3_country_code)&.iso_short_name
  end

  def within_the_uk?
    alpha3_country_code.in?([UK_COUNTRY_CODE, *CROWN_DEPENDENCY_COUNTRY_CODES])
  end

  def in_england?
    alpha3_country_code == UK_COUNTRY_CODE && subdivision_code == ENGLAND_SUBDIVISION_CODE
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
