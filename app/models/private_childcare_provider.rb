class PrivateChildcareProvider < ApplicationRecord
  include Disableable
  include PgSearch::Model

  has_one :institution, as: :institutionable, touch: true

  pg_search_scope :search_by_urn,
                  against: [:provider_urn],
                  using: {
                    trigram: {
                      word_similarity: true,
                      threshold: 0.2,
                    },
                  }

  delegate :name, :county, :region, :town, :postcode, to: :institution

  def name_with_address
    [name, address_string].join(" – ")
  end

  def address
    [institution.address_1, institution.address_2, institution.address_3, institution.town, institution.region, institution.postcode]
      .reject(&:blank?) - [Institution::REDACTED_DATA_STRING]
  end

  def address_string
    address.join(", ")
  end

  def display_name
    [urn, name_with_address].compact.join(" - ")
  end

  validates :provider_urn, presence: true

  def urn
    provider_urn
  end

  def ukprn
    nil
  end

  def in_england?
    true # Needs filling in
  end

  def identifier
    "PrivateChildcareProvider-#{urn}"
  end

  def long_name
    [name, address].join(" - ")
  end

  def on_early_years_register?
    early_years_individual_registers.include?("EYR")
  end

  def eyl_disadvantaged?
    !!EY_OFSTED_URN_HASH[provider_urn.to_s]
  end

  def on_childminders_list?
    !!CHILDMINDERS_OFSTED_URN_HASH[provider_urn.to_s]
  end

  def registration_details
    details = []

    details << urn
    details << (name.presence || address_string)
    details << address_string if name.presence
    details.join(" – ")
  end
end
