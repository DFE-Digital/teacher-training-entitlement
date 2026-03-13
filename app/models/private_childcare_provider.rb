class PrivateChildcareProvider < ApplicationRecord
  include Disableable
  include PgSearch::Model

  has_one :institution, as: :institutionable, touch: true

  delegate :name, :county, :region, :town, :postcode, :urn, :address, :address_string,
           :name_with_address, to: :institution

  def self.search_by_urn(query)
    joins(:institution).where("institutions.institution_reference_number ILIKE ?", "%#{query}%")
  end

  def display_name
    [urn, name_with_address].compact.join(" - ")
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
    !!EY_OFSTED_URN_HASH[urn.to_s]
  end

  def on_childminders_list?
    !!CHILDMINDERS_OFSTED_URN_HASH[urn.to_s]
  end

  def registration_details
    details = []

    details << urn
    details << (name.presence || address_string)
    details << address_string if name.presence
    details.join(" – ")
  end
end
