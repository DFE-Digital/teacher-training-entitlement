# Assigns an institution_type slug. School selectors are evaluated in the order of
# Institution::INSTITUTION_TYPES and the first match wins; a School matching no
# selector defaults to state_funded. The order is pending Policy confirmation.
#
# Not yet implemented for lack of data: young_offender_institution, mod_overseas
# and virtual_school (see the importer tickets in the institution architecture epic).
class Institutions::ClassifyType
  FURTHER_EDUCATION_ESTABLISHMENT_TYPE_CODE = "18".freeze
  HOSPITAL_NAME_PATTERN = /hospital|clinic|therapeutic/i

  def initialize(institutionable:, name: nil)
    @institutionable = institutionable
    @name = name
  end

  def call
    case institutionable
    when LocalAuthority then Institution::LOCAL_AUTHORITY
    when PrivateChildcareProvider then Institution::PRIVATE_CHILDCARE_PROVIDER
    else classify_school
    end
  end

private

  attr_reader :institutionable, :name

  def classify_school
    code = institutionable.establishment_type_code.to_s

    if state_funded_code?(code)
      Institution::STATE_FUNDED
    elsif code == FURTHER_EDUCATION_ESTABLISHMENT_TYPE_CODE
      Institution::FURTHER_EDUCATION
    elsif name.to_s.match?(HOSPITAL_NAME_PATTERN)
      Institution::HOSPITAL
    else
      Institution::STATE_FUNDED
    end
  end

  def state_funded_code?(code)
    School::ELIGIBLE_ESTABLISHMENT_TYPE_CODES.key?(code) &&
      code != FURTHER_EDUCATION_ESTABLISHMENT_TYPE_CODE
  end
end
