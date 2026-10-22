module Importers
  module CountryCodeAttributes
  module_function

    def country_code_attributes_for(institutionable)
      case institutionable
      when School
        return { alpha3_country_code: nil, subdivision_code: nil } unless institutionable.in_uk?

        subdivision_code = institutionable.establishment_type_code == "30" ? Institution::WALES_SUBDIVISION_CODE : Institution::ENGLAND_SUBDIVISION_CODE
        { alpha3_country_code: Institution::UK_COUNTRY_CODE, subdivision_code: }
      when PrivateChildcareProvider, LocalAuthority
        { alpha3_country_code: Institution::UK_COUNTRY_CODE, subdivision_code: Institution::ENGLAND_SUBDIVISION_CODE }
      else
        { alpha3_country_code: nil, subdivision_code: nil }
      end
    end
  end
end
