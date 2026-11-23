require "rails_helper"

RSpec.feature "Course selection registration", :no_js, :with_default_lead_provider, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::CourseSelectionRegistrationPathHelper

  include ApplicationHelper

  include_context "Stub Teacher Auth Responses"

  scenario "Choosing Excellence In Reception course" do
    start_registration
    choose_excellence_in_reception_course

    expect(page).to have_current_path("/registrations/excellence-in-reception", ignore_query: true)
  end

  scenario "Choosing Embedding inclusive practice course" do
    start_registration
    choose_send_teachers_course

    expect(page).to have_current_path("/registrations/embedding-inclusive-practice", ignore_query: true)
  end

  scenario "Choosing Embedding inclusive practice for leaders course" do
    start_registration
    choose_send_leaders_course

    expect(page).to have_current_path("/registrations/embedding-inclusive-practice-for-leaders", ignore_query: true)
  end
end
