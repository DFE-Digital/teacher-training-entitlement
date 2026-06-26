RSpec.shared_context "with default lead provider", shared_context: :metadata do
  before do
    cohort = Cohort.current
    lead_provider = LeadProvider.first || create(:lead_provider)

    course = Course.find_by(identifier: "npd-excellence-in-reception-teaching") || create(:course, :npd_eirt)

    cohort.update!(course:) unless cohort.course == course
    Schedule.find_by(cohort:) || create(:schedule, cohort:)

    unless cohort.cohort_providers.exists?(lead_provider:)
      create(:cohort_provider, cohort:, lead_provider:)
    end
  end
end

RSpec.configure do |config|
  config.include_context "with default lead provider", :with_default_lead_provider
end
