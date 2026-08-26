require "rails_helper"

RSpec.describe Admin::RegistrationJourneysController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  describe "GET /admin/registration-journeys" do
    before { sign_in_as_admin }

    it "links to registration templates and provides a delete action for each journey" do
      journey = RegistrationJourney.create!(name: "Journey to delete")

      get admin_registration_journeys_path

      expect(response.body).to include(admin_registration_templates_path)
      delete_link = Nokogiri::HTML(response.body).at_xpath(
        "//a[normalize-space()='Delete' and @href='#{admin_registration_journey_path(journey)}']",
      )
      expect(delete_link).to be_present
      expect(delete_link["data-method"]).to eq("delete")
    end
  end

  describe "GET /admin/registration-journeys/:id" do
    before { sign_in_as_admin }

    it "provides a delete action for each registration step" do
      journey = RegistrationJourney.create!(name: "Journey", slug: "journey")
      step = journey.registration_steps.create!(
        name: "Choose a snack",
        slug: "choose-a-snack",
        type: "Radio buttons",
        config: {},
      )

      get admin_registration_journey_path(journey)

      delete_link = Nokogiri::HTML(response.body).at_xpath(
        "//a[normalize-space()='Delete' and @href='#{admin_registration_journey_registration_step_path(journey, step)}']",
      )
      expect(delete_link).to be_present
      expect(delete_link["data-method"]).to eq("delete")
    end
  end

  describe "POST /admin/registration-journeys" do
    before { sign_in_as_admin(super_admin: true) }

    it "creates an empty registration journey" do
      course = create(:course)

      expect {
        post admin_registration_journeys_path, params: {
          registration_journey: {
            name: "New journey",
            slug: "new-journey",
            course_id: course.id,
          },
        }
      }.to change(RegistrationJourney, :count).by(1)
        .and not_change(RegistrationStep, :count)

      journey = RegistrationJourney.find_by!(slug: "new-journey")
      expect(response).to redirect_to(admin_registration_journey_path(journey))
      expect(journey.course).to eq(course)
      expect(journey.registration_steps).to be_empty
    end
  end

  describe "PATCH /admin/registration-journeys/:id" do
    before { sign_in_as_admin(super_admin: true) }

    it "updates the registration journey course" do
      journey = RegistrationJourney.create!(name: "Journey", slug: "journey")
      course = create(:course)

      patch admin_registration_journey_path(journey), params: {
        registration_journey: {
          name: "Journey",
          slug: "journey",
          course_id: course.id,
        },
      }

      expect(response).to redirect_to(admin_registration_journey_path(journey))
      expect(journey.reload.course).to eq(course)
    end
  end
end
