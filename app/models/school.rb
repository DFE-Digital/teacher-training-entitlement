class School < ApplicationRecord
  has_one :institution, as: :institutionable, touch: true

  delegate :name, :address, :address_string, :display_name, :name_with_address,
           :address_1, :address_2, :address_3, :town, :county, :postcode,
           :urn, to: :institution

  PRIMARY_PHASE = "Primary".freeze
  MIDDLE_DEEMED_PRIMARY_PHASE = "Middle deemed primary".freeze

  ELIGIBLE_ESTABLISHMENT_TYPE_CODES = {
    "1" => "Community school",
    "2" => "Voluntary aided school",
    "3" => "Voluntary controlled school",
    "5" => "Foundation school",
    "6" => "City technology college",
    "7" => "Community special school",
    "8" => "Non-maintained special school",
    "10" => "Other independent special school",
    "12" => "Foundation special school",
    "14" => "Pupil referral unit",
    "15" => "Local authority nursery school",
    "18" => "Further education",
    "24" => "Secure units",
    "26" => "Service children's education",
    "28" => "Academy sponsor led",
    "31" => "Sixth form centres",
    "32" => "Special post 16 institution",
    "33" => "Academy special sponsor led",
    "34" => "Academy converter",
    "35" => "Free schools",
    "36" => "Free schools special",
    "38" => "Free schools alternative provision",
    "39" => "Free schools 16 to 19",
    "40" => "University technical college",
    "41" => "Studio schools",
    "42" => "Academy alternative provision converter",
    "43" => "Academy alternative provision sponsor led",
    "44" => "Academy special converter",
    "45" => "Academy 16-19 converter",
    "46" => "Academy 16 to 19 sponsor led",
  }.freeze

  # 1 => establishment_status_name: "Open"
  # 2 => establishment_status_name: "Closed"
  # 3 => establishment_status_name: "Open, but proposed to close"
  # 4 => establishment_status_name: "Proposed to open"

  NOT_IN_ENGLAND_CODES = {
    # Welsh establishment
    establishment_type_code: %w[30],
    # 000-"Does not appyl"
    # 673-"Vale of Glamorgan"
    # 702-"BFPO Overseas Establishments"
    # 704-"Fieldwork Overseas Establishments"
    # 708-"Gibraltar Overseas Establishments"
    la_code: %w[000 673 702 704 708],
  }.freeze

  scope :open, -> { where(establishment_status_code: %w[1 3 4]) }
  scope :not_in_england, lambda {
    where(establishment_type_code: NOT_IN_ENGLAND_CODES[:establishment_type_code])
      .or(where(la_code: NOT_IN_ENGLAND_CODES[:la_code]))
  }

  ELIGIBLE_ESTABLISHMENT_TYPE_CODES.each do |code, name|
    define_method("#{name.parameterize.underscore}?") do
      establishment_type_code == code
    end
  end

  def primary_education_phase?
    [MIDDLE_DEEMED_PRIMARY_PHASE, PRIMARY_PHASE].include?(phase_name)
  end

  def in_england?
    return if establishment_type_code.in?(NOT_IN_ENGLAND_CODES[:establishment_type_code])
    return if la_code.in?(NOT_IN_ENGLAND_CODES[:la_code])

    true
  end

  def identifier
    "School-#{urn}"
  end

  def long_name
    [display_name, address_string].join(" - ")
  end

  def eligible_establishment?
    ELIGIBLE_ESTABLISHMENT_TYPE_CODES.keys.include?(establishment_type_code)
  end

  def pp50?(work_setting)
    if work_setting == Questionnaires::WorkSetting::A_16_TO_19_EDUCATIONAL_SETTING
      !!PP50_FE_UKPRN_HASH[ukprn.to_s]
    else
      !!PP50_SCHOOLS_URN_HASH[urn.to_s]
    end
  end

  def eyl_disadvantaged?
    !!EY_OFSTED_URN_HASH[urn.to_s]
  end

  def la_disadvantaged_nursery?
    !!LA_DISADVANTAGED_NURSERIES[urn.to_s]
  end

  def rise?
    FundingEligibilityData.rise_school?(urn.to_s)
  end
end
