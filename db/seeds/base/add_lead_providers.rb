require_relative "constants"

LEAD_PROVIDERS.each do |name|
  LeadProvider.find_by(name:) || FactoryBot.create(:lead_provider, name:)
end

Course.find_each do |course|
  LeadProvider.find_each do |lead_provider|
    Cohort.find_each do |cohort|
      course_cohort = CourseCohort.find_by(course:, cohort:)
      course_cohort ||= CourseCohort.create!(course:, cohort:, schedule: FactoryBot.create(:schedule, cohort:))

      CourseCohortProvider.find_or_create_by!(
        lead_provider:,
        course_cohort:,
      )
    end
  end
end
