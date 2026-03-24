require_relative "constants"

LEAD_PROVIDERS.each do |name|
  LeadProvider.find_by(name:) || FactoryBot.create(:lead_provider, name:)
end

Course.find_each do |course|
  Cohort.find_each do |cohort|
    schedule = Schedule.find_by(cohort:, course_group: course.course_group) || FactoryBot.create(:schedule, cohort:, course_group: course.course_group)
    course_cohort = CourseCohort.find_or_create_by!(course:, cohort:) do |cc|
      cc.schedule = schedule
    end

    LeadProvider.find_each do |lead_provider|
      CourseCohortProvider.find_or_create_by!(
        lead_provider:,
        course_cohort:,
      )
    end
  end
end
