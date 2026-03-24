FactoryBot.define do
  factory :registration_wizard_store, class: Hash do
    initialize_with { attributes.stringify_keys }

    transient do
      course { Course.find_by(identifier: Course::IDENTIFIERS.first) || create(Course::IDENTIFIERS.first.to_sym) }
      school { create(:school, :funding_eligible_establishment_type_code) }
      lead_provider { LeadProvider.first }
    end

    current_user { create(:user) }
    course_identifier { course.identifier }
    institution_id { school.institution.id }
    lead_provider_id { lead_provider.id }
    works_in_school { "yes" }
    teacher_catchment { "england" }
    work_setting { "a_school" }
    referred_by_return_to_teaching_adviser { "no" }
    trn { current_user.trn }
  end
end
