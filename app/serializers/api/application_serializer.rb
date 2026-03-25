module API
  class ApplicationSerializer < Blueprinter::Base
    identifier :ecf_id, name: :id
    field(:type) { "application" }

    class AttributesSerializer < Blueprinter::Base
      exclude :id

      view :v1 do
        field(:course_identifier) { |a| a.course.identifier }
        field(:email) { |a| a.user.email }
        field(:email_validated) { true }
        field(:full_name) { |a| a.user.full_name }
        field(:funding_choice)
        field(:ineligible_for_funding_reason)
        field(:participant_id) { |a| a.user.ecf_id }
        field(:teacher_reference_number) { |a| a.user.trn }
        field(:institution_reference_number) { |a| a.institution&.institution_reference_number }
        field(:institution_type) { |a| a.institution&.institutionable_type&.downcase }
        field(:ukprn) { |a| a.institution&.ukprn }
        field(:status)
        field(:reason_for_rejection)
        field(:works_in_school)
        field(:cohort) { |a| a.cohort&.start_year&.to_s }
        field(:eligible_for_dfe_funding?, name: :eligible_for_funding)
        field(:inside_uk_catchment?, name: :teacher_catchment)
        field(:teacher_catchment_country)
        field(:teacher_catchment_iso_country_code)
        field(:funded_place)
        field(:schedule_identifier) { |a| a.schedule&.identifier }
        field(:created_at)
        field(:updated_at) do |a|
          [
            a.user.significantly_updated_at,
            a.updated_at,
          ].compact.max
        end
      end
    end

    association :attributes, blueprint: AttributesSerializer do |application|
      application
    end

    view :v1 do
      association :attributes, blueprint: AttributesSerializer, view: :v1 do |application|
        application
      end
    end
  end
end
