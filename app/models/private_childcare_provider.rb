class PrivateChildcareProvider < ApplicationRecord
  include Disableable
  include PgSearch::Model

  has_one :institution, as: :institutionable, touch: true

  delegate :name, :county, :region, :town, :postcode, :urn, :address, :address_string,
           :name_with_address, :display_name, to: :institution

  def identifier
    "PrivateChildcareProvider-#{urn}"
  end
end
