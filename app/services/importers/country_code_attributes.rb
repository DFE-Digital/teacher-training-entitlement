module Importers
  module CountryCodeAttributes
  module_function

    def country_code_attributes_for(institutionable)
      case institutionable
      when School
        return { alpha3_country_code: nil, subdivision_code: nil } unless uk_school?(institutionable)

        subdivision_code = institutionable.establishment_type_code == School::WALES_ESTABLISHMENT_TYPE_CODE ? Institution::WALES_SUBDIVISION_CODE : Institution::ENGLAND_SUBDIVISION_CODE
        { alpha3_country_code: Institution::UK_COUNTRY_CODE, subdivision_code: }
      when PrivateChildcareProvider, LocalAuthority
        { alpha3_country_code: Institution::UK_COUNTRY_CODE, subdivision_code: Institution::ENGLAND_SUBDIVISION_CODE }
      else
        { alpha3_country_code: nil, subdivision_code: nil }
      end
    end

    def uk_school?(institutionable)
      institutionable.establishment_type_code == School::WALES_ESTABLISHMENT_TYPE_CODE ||
        School::NOT_IN_ENGLAND_LA_CODES.exclude?(institutionable.la_code)
    end
  end
end
