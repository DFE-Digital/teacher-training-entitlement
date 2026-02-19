require_relative "constants"

LEAD_PROVIDERS.each do |name|
  FactoryBot.create(:lead_provider, name:)
end

Course.find_each do |course|
  LeadProvider.find_each do |lead_provider|
    course_cohort = CourseCohort.find_or_create_by!(
      course:,
      cohort: Cohort.current,
    )
    CourseCohortProvider.create!(
      lead_provider:,
      course_cohort:,
    )
  end
end
