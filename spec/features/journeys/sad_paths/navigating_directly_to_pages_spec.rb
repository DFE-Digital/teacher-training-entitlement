require "rails_helper"

RSpec.feature "Sad journeys", :npq, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "Stub Teacher Auth Responses"

  before { start_registration_from_root }

  context "with the legacy registration journey" do
    steps_that_require_course = %w[
      check-answers
      choose-your-provider
      possible-funding
    ]

    RegistrationWizard::VALID_REGISTRATION_STEPS
      .map { |step| step.to_s.dasherize }.each do |step|
      scenario "Navigating directly to the #{step} page does not raise an error" do
        visit "/registration/#{step}"
        if steps_that_require_course.include?(step)
          expect(page).to have_current_path("/registration/course-start-date")
        else
          expect(page).to have_current_path("/registration/#{step}")
        end
      end
    end
  end

  context "with the dfe-wizard registration journey", :dfe_wizard_registration do
    # The wizard sends the teacher to the first step not completed yet.
    (Registration::Wizard::STEPS.keys - %i[sign_in course_start_date]).map { |step| step.to_s.dasherize }.each do |step|
      scenario "Navigating directly to the #{step} page does not raise an error" do
        visit journey_path("/registration/#{step}")

        expect(page).to have_current_path(journey_path("/registration/course-start-date"))
      end
    end
  end
end
