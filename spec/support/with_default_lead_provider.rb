RSpec.shared_context "with default lead provider", shared_context: :metadata do
  before do
    cohort = Cohort.current
    lead_provider = LeadProvider.first || create(:lead_provider)

    course = Course.find_by(identifier: "npd-excellence-in-reception-teaching") || create(:course, :npd_eirt)

    course_cohort = course.course_cohorts.find_by(cohort:)
    unless course_cohort
      schedule = Schedule.find_by(cohort:) || create(:schedule, cohort:)
      course_cohort = create(:course_cohort, course:, cohort:, schedule:)
    end

    unless course_cohort.course_cohort_providers.exists?(lead_provider:)
      create(:course_cohort_provider, course_cohort:, lead_provider:)
    end
  end
end

RSpec.configure do |config|
  config.include_context "with default lead provider", :with_default_lead_provider
end
