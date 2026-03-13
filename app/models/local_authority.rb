class LocalAuthority < ApplicationRecord
  has_one :institution, as: :institutionable, touch: true

  delegate :name, :address, :address_string, :display_name, :name_with_address,
           :town, :county, :postcode, to: :institution

  def self.search_by_name(name)
    joins(:institution).merge(Institution.search_by_name(name))
  end

  def urn
    nil
  end

  def identifier
    "LocalAuthority-#{id}"
  end

  def in_england?
    true
  end

  def eligible_establishment?
    true
  end

end
