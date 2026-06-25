require "rails_helper"

RSpec.feature "Registration start page", type: :feature do
  let(:lead_provider) { create(:lead_provider, url: "https://example.com/provider") }
  let(:course) { create(:course, :npd_eirt, lead_provider:) }
  let!(:provider_course_profile) { create(:provider_course_profile, course:, lead_provider:, url: "https://example.com/course-provider") }

  before { create(:course_cohort_provider, course_cohort: CourseCohort.next_open_for(course:), lead_provider:) }

  scenario "links providers to their course-specific URL" do
    visit(root_path)

    expect(page).to have_link(lead_provider.name, href: provider_course_profile.url)
    expect(page).not_to have_link(lead_provider.name, href: lead_provider.url)
  end
end
