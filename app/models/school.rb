class School < ApplicationRecord
  has_one :institution, as: :institutionable, touch: true

  delegate :name, :address, :address_string, :display_name, :name_with_address,
           :address_1, :address_2, :address_3, :town, :county, :postcode,
           :urn, to: :institution

  PRIMARY_PHASE = "Primary".freeze
  MIDDLE_DEEMED_PRIMARY_PHASE = "Middle deemed primary".freeze

  ELIGIBLE_ESTABLISHMENT_TYPE_CODES = FundingEligibility::ELIGIBLE_ESTABLISHMENT_TYPE_CODES

  # 1 => establishment_status_name: "Open"
  # 2 => establishment_status_name: "Closed"
  # 3 => establishment_status_name: "Open, but proposed to close"
  # 4 => establishment_status_name: "Proposed to open"

  WALES_ESTABLISHMENT_TYPE_CODE = "30".freeze
  NOT_IN_ENGLAND_LA_CODES = %w[000 673 702 704 708].freeze

  scope :open, -> { where(establishment_status_code: %w[1 3 4]) }
  scope :not_in_england, lambda {
    where(establishment_type_code: WALES_ESTABLISHMENT_TYPE_CODE)
      .or(where(la_code: NOT_IN_ENGLAND_LA_CODES))
  }

  ELIGIBLE_ESTABLISHMENT_TYPE_CODES.each do |code, name|
    define_method("#{name.parameterize.underscore}?") do
      establishment_type_code == code
    end
  end

  def primary_education_phase?
    [MIDDLE_DEEMED_PRIMARY_PHASE, PRIMARY_PHASE].include?(phase_name)
  end

  def identifier
    "School-#{urn}"
  end

  def eligible_establishment?
    ELIGIBLE_ESTABLISHMENT_TYPE_CODES.key?(establishment_type_code)
  end
end
