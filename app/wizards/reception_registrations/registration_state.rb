module ReceptionRegistrations
  class RegistrationState
    include DfE::Wizard::StateStore

    KIND_OF_NURSERY_PUBLIC_OPTIONS = %w[
      local_authority_maintained_nursery
      preschool_class_as_part_of_school
    ].freeze

    KIND_OF_NURSERY_PRIVATE_OPTIONS = %w[
      childminder
      private_nursery
      another_early_years_setting
    ].freeze

    KIND_OF_NURSERY_OPTIONS = KIND_OF_NURSERY_PUBLIC_OPTIONS + KIND_OF_NURSERY_PRIVATE_OPTIONS

    VALID_FUNDING_OPTIONS = [
      SCHOOL = "school".freeze,
      TRUST = "trust".freeze,
      SELF = "self".freeze,
      ANOTHER_ = "another".freeze,
      EMPLOYER = "employer".freeze,
    ].freeze

    def course
      return nil if course_identifier.blank?

      @course ||= Course.find_by(identifier: course_identifier)
    end

    def lead_provider
      return nil if lead_provider_id.blank?

      @lead_provider ||= LeadProvider.find_by(id: lead_provider_id)
    end

    def funding_eligibility_status_code
      return FundingEligibility::INELIGIBLE_SETTING if kind_of_nursery_private? || works_in_other?

      self["funding_eligibility_status_code"]
    end

    def eligible_for_funding
      self["eligible_for_funding"] || false
    end

    def works_in_school
      self["works_in_school"]
    end

    def works_in_childcare
      self["works_in_childcare"]
    end

    def trn
      self["trn"]
    end

    def course_start
      @course_start ||= Cohort.application_course_start_date
    end

    def public_nursery?
      KIND_OF_NURSERY_PUBLIC_OPTIONS.include?(kind_of_nursery)
    end

    def kind_of_nursery_private?
      KIND_OF_NURSERY_PRIVATE_OPTIONS.include?(kind_of_nursery)
    end

    def works_in_other?
      work_setting == "other"
    end

    def inside_catchment?
      teacher_catchment == "england"
    end

    def no_institution_selected?
      institution_id == "other" || institution_id.blank?
    end

    def selected_institution
      return nil if institution_id.blank? || institution_id == "other"

      @selected_institution ||= Institution.find(institution_id)
    end

    def primary_establishment
      selected_institution.school.primary_education_phase? if selected_institution&.school?
    end

    def number_of_pupils
      selected_institution.school.number_of_pupils if selected_institution&.school?
    end

    def ukprn
      if inside_catchment? && (selected_institution&.local_authority? || selected_institution&.school?)
        selected_institution.ukprn
      end
    end

    def funding_choice
      # It is possible that the applicant had chosen a non-funded path and selected a funding choice
      # before going back a few steps and choosing a funded route. We should clear the funding choice
      # to nil here to reduce confusion
      if eligible_for_funding
        nil
      else
        funding
      end
    end

    def teacher_catchment_country
      in_uk_catchement_area? ? uk_country.iso_short_name : nil
    end

    def teacher_catchment_iso_country_code
      return if teacher_catchment_country.blank?
      return uk_country.alpha3 if in_uk_catchement_area?

      if (country = ISO3166::Country.find_country_by_any_name(teacher_catchment_country))
        country.alpha3
      else
        Sentry.capture_message("Could not find the ISO3166 alpha3 code for #{teacher_catchment_country}.", level: :warning)
        nil
      end
    end

    def inelegible_for_funding_type
      return :ineligible_setting if kind_of_nursery_private? || works_in_other?

      funding_eligibility_status_code
    end

  private

    def uk_country
      @uk_country ||= ISO3166::Country.find_country_by_any_name("United Kingdom")
    end

    def in_uk_catchement_area?
      teacher_catchment.in?(Application::UK_CATCHMENT_AREA)
    end
  end
end
