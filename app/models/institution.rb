class Institution < ApplicationRecord
  include PgSearch::Model

  REDACTED_DATA_STRING = "REDACTED".freeze

  delegated_type :institutionable, types: %w[School PrivateChildcareProvider LocalAuthority], dependent: :destroy

  pg_search_scope :search_by_name,
                  against: %i[name address_1 address_2 address_3 town county postcode postcode_without_spaces region],
                  using: {
                    tsearch: {
                      prefix: true,
                      dictionary: "english",
                    },
                  }

  delegate :in_england?, :urn, :ukprn, :la_name, :identifier, :eligible_establishment?, to: :institutionable

  # Finds an institutionable (School, PrivateChildcareProvider, LocalAuthority) by its
  # string identifier format, e.g., "School-123456", "PrivateChildcareProvider-100001"
  def self.find_institutionable_by_identifier(identifier)
    return nil if identifier.blank?

    klass_name, value = identifier.split("-", 2)
    return nil if value.blank?

    case klass_name
    when "School"
      School.find_by(urn: value)
    when "PrivateChildcareProvider"
      PrivateChildcareProvider.find_by(provider_urn: value)
    when "LocalAuthority"
      LocalAuthority.find_by(id: value)
    end
  end

  def name
    raw_name = self[:name]
    raw_name unless raw_name == REDACTED_DATA_STRING
  end

  def address
    [address_1, address_2, address_3, town, county, postcode].reject(&:blank?) - [REDACTED_DATA_STRING]
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
