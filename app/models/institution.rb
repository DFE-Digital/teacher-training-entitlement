class Institution < ApplicationRecord
  include PgSearch::Model

  REDACTED_DATA_STRING = "REDACTED".freeze

  delegated_type :institutionable, types: %w[School PrivateChildcareProvider LocalAuthority], dependent: :destroy

  validates :institution_reference_number, presence: true

  pg_search_scope :search_by_name,
                  against: %i[name address_1 address_2 address_3 town county postcode postcode_without_spaces region],
                  using: {
                    tsearch: {
                      prefix: true,
                      dictionary: "english",
                    },
                  }

  delegate :in_england?, :identifier, :eligible_establishment?, to: :institutionable

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
