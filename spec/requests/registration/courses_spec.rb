require "rails_helper"

RSpec.describe "Registration course selection", type: :request do
  let(:cohort) { create(:cohort, :current) }
  let!(:course_a) { create(:course, name: "Course A", position: 2) }
  let!(:course_b) { create(:course, name: "Course B", position: 1) }
  let(:flag_enabled) { true }

  before do
    Course.where.not(id: [course_a.id, course_b.id]).update_all(display: false)
    Flipper.enable(Feature::REGISTRATION_OPEN)
    Flipper.enable(Feature::REGISTRATION_DFE_WIZARD) if flag_enabled
  end

  def sign_in_path(course) = registration_step_path(course_identifier: course.identifier, step: "sign-in")

  def start_date_path(course) = registration_step_path(course_identifier: course.identifier, step: "course-start-date")

  def wizard_state(course)
    session_state = request.session.to_h.deep_stringify_keys.dig("registration", course.identifier)
    session_state.to_h
  end

  describe "GET /registration/courses" do
    context "when the feature flag is off" do
      let(:flag_enabled) { false }

      it "is not found" do
        get registration_courses_path

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when no course is open" do
      before { CourseCohort.destroy_all }

      it "redirects to the closed page" do
        get registration_courses_path

        expect(response).to redirect_to(registration_wizard_show_path(:closed))
      end
    end

    context "when registration is closed for the teacher" do
      before { Flipper.disable(Feature::REGISTRATION_OPEN) }

      it "redirects to the closed page" do
        get registration_courses_path

        expect(response).to redirect_to(registration_wizard_show_path(:closed))
      end
    end

    context "when several courses are open and the teacher is signed out" do
      it "lists the courses in position order" do
        get registration_courses_path

        expect(response.body.index("Course B")).to be < response.body.index("Course A")
      end

      it "uses GOV.UK radios" do
        get registration_courses_path

        expect(response.body).to include("govuk-radios__input")
      end
    end

    context "when the teacher has already applied for a course" do
      let(:user) { create(:user) }

      before do
        create(:application, user:, course: course_a, course_cohort: course_a.course_cohorts.first)
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      it "still lists the course" do
        get registration_courses_path

        expect(response.body).to include("Course A")
      end
    end

    context "when only one course is open" do
      before { course_b.course_cohorts.destroy_all }

      it "skips the selector for a signed-out teacher" do
        get registration_courses_path

        expect(response).to redirect_to(sign_in_path(course_a))
      end

      it "skips the selector for a signed-in teacher" do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(create(:user))

        get registration_courses_path

        expect(response).to redirect_to(start_date_path(course_a))
      end
    end

    context "when a course is not displayed" do
      before { course_b.update!(display: false) }

      it "is not open" do
        get registration_courses_path

        expect(response).to redirect_to(sign_in_path(course_a))
      end
    end
  end

  describe "POST /registration/courses" do
    it "starts the selected course" do
      post registration_courses_path, params: { course_selection: { course_identifier: course_a.identifier } }

      expect(response).to redirect_to(sign_in_path(course_a))
    end

    it "shows an error when nothing is selected" do
      post registration_courses_path

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Select the course you want to register for")
    end

    it "shows an error when the course is not open" do
      post registration_courses_path, params: { course_selection: { course_identifier: "nope" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /registration/:course_identifier" do
    it "starts at the first step for a signed-out teacher" do
      get registration_course_path(course_a.identifier)

      expect(response).to redirect_to(sign_in_path(course_a))
    end

    it "starts at the first step for a signed-in teacher" do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(create(:user))

      get registration_course_path(course_a.identifier)

      expect(response).to redirect_to(start_date_path(course_a))
    end

    it "starts course B at its first step while course A is in progress" do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(create(:user))
      patch start_date_path(course_a), params: { course_start_date: { course_start_date: course_a.course_cohorts.first.ecf_id } }

      get registration_course_path(course_b.identifier)

      expect(response).to redirect_to(start_date_path(course_b))
      expect(wizard_state(course_b)).to be_empty
      expect(wizard_state(course_a)).to include("course_start_date" => course_a.course_cohorts.first.ecf_id)
    end

    it "sends an unknown identifier to the selector with a message" do
      get "/registration/unknown-course"

      expect(response).to redirect_to(registration_courses_path)
      expect(flash[:notice]).to eq("That course is not available for registration.")
    end

    it "sends a course without an open cohort to the selector" do
      course_a.course_cohorts.destroy_all

      get registration_course_path(course_a.identifier)

      expect(response).to redirect_to(registration_courses_path)
    end

    it "keeps the message when the only open course skips the selector" do
      course_b.course_cohorts.destroy_all

      get "/registration/unknown-course"
      follow_redirect!
      follow_redirect!

      expect(response.body).to include("not available")
    end

    it "keeps the message when no course is open" do
      Course.update_all(display: false)

      get "/registration/unknown-course"
      follow_redirect!
      follow_redirect!

      expect(response.body).to include("That course is not available for registration.")
    end

    it "does not take over the legacy start page" do
      get "/registration/start"

      expect(response).not_to redirect_to(sign_in_path(course_a))
    end

    it "does not take over the legacy closed page" do
      get "/registration/closed"

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /registration/start" do
    it "goes to the course selector when the feature flag is on" do
      get registration_wizard_show_path(:start)

      expect(response).to redirect_to(registration_courses_path)
    end

    context "when the feature flag is off" do
      let(:flag_enabled) { false }

      it "shows the legacy start page" do
        get registration_wizard_show_path(:start)

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
