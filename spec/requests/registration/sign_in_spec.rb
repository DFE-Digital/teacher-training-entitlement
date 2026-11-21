require "rails_helper"

RSpec.describe "Registration sign in", type: :request do
  let(:course) { create(:course) }
  let(:user) { create(:user, :with_one_login_id) }
  let(:service) { instance_double(Users::FindOrCreateFromTeacherAuth, call: user) }
  let(:mock_auth) do
    OmniAuth::AuthHash.new("uid" => "uid", "credentials" => { "id_token" => "token" })
  end

  def step_path(step)
    registration_step_path(course_identifier: course.identifier, step:)
  end

  before do
    Flipper.enable(Feature::REGISTRATION_OPEN)
    Flipper.enable(Feature::REGISTRATION_DFE_WIZARD)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:teacher_auth] = mock_auth
    Rails.application.env_config["omniauth.auth"] = mock_auth
    allow(Users::FindOrCreateFromTeacherAuth).to receive(:new).and_return(service)
  end

  describe "POST /one-login" do
    it "starts the Teacher Auth redirect and sends the started event" do
      expect(StreamAnalyticsEventToBigQueryJob).to receive(:send_event).with(
        type: :one_login_started,
        request: an_instance_of(ActionDispatch::Request),
      )

      post one_login_redirect_path(course_identifier: course.identifier)

      expect(response).to redirect_to(user_teacher_auth_omniauth_authorize_path)
    end
  end

  describe "returning from Teacher Auth" do
    before { post one_login_redirect_path(course_identifier: course.identifier) }

    it "lands on the step after sign in for the course" do
      post "/users/auth/teacher_auth/callback"

      expect(response).to redirect_to(step_path("course-start-date"))
    end

    it "sends the completed event" do
      expect(StreamAnalyticsEventToBigQueryJob).to receive(:send_event).with(
        type: :one_login_completed,
        request: an_instance_of(ActionDispatch::Request),
        user:,
      )

      post "/users/auth/teacher_auth/callback"
    end

    context "when the sign in fails" do
      before { allow(service).to receive(:call).and_raise(StandardError, "boom") }

      it "returns to the sign in step of the course" do
        post "/users/auth/teacher_auth/callback"

        expect(response).to redirect_to(step_path("sign-in"))
      end

      it "sets the error message" do
        post "/users/auth/teacher_auth/callback"

        expect(flash[:error]).to include("There was an error")
      end

      it "shows the error message on the sign in page" do
        post "/users/auth/teacher_auth/callback"
        follow_redirect!

        expect(response.body).to include("There was an error")
      end

      it "sends the failed event" do
        expect(StreamAnalyticsEventToBigQueryJob).to receive(:send_event).with(
          type: :one_login_failed,
          request: an_instance_of(ActionDispatch::Request),
          data: { error_type: "callback_error" },
        )

        post "/users/auth/teacher_auth/callback"
      end
    end

    context "when the sign in is cancelled" do
      it "returns to the sign in step of the course" do
        OmniAuth.config.mock_auth[:teacher_auth] = :access_denied
        post "/users/auth/teacher_auth/callback"
        expect(response).to redirect_to(step_path("sign-in"))
      end
    end
  end

  describe "signing in from the email updates page after abandoning a registration sign in" do
    it "goes to the email updates page" do
      post one_login_redirect_path(course_identifier: course.identifier)
      post user_teacher_auth_omniauth_authorize_path(request_email_updates: "true")
      post "/users/auth/teacher_auth/callback"

      expect(response).to redirect_to(new_email_update_path)
    end
  end

  describe "development login" do
    before do
      allow(Rails.env).to receive(:development?).and_return(true)
      get "/development_login", params: { user_email: user.email, course_identifier: course.identifier }
    end

    it "signs the teacher in and continues the journey" do
      expect(response).to redirect_to(step_path("course-start-date"))
    end
  end

  describe "development login without a course" do
    it "continues the legacy journey" do
      allow(Rails.env).to receive(:development?).and_return(true)

      get "/development_login", params: { user_email: user.email }

      expect(response).to redirect_to(registration_wizard_show_path("course-start-date"))
    end
  end

  describe "starting without a course" do
    it "keeps the legacy return path" do
      post one_login_redirect_path
      post "/users/auth/teacher_auth/callback"

      expect(response).to redirect_to(registration_wizard_show_path("course-start-date"))
    end
  end

  describe "with sign in moved after a step that needs no authentication" do
    let(:test_step) do
      Class.new do
        include Registration::Steps::Base

        self.requires_user = false
        attribute :colour
        validates :colour, presence: true

        def self.permitted_params
          %i[colour]
        end
      end
    end

    before do
      stub_const("Registration::Wizard::STEPS", Registration::Wizard::STEPS.merge(colour: test_step))
      stub_const("Registration::Wizard::HEAD_STEPS", %i[colour sign_in course_start_date])
    end

    it "keeps the earlier answer through the sign in" do
      patch step_path("colour"), params: { colour: { colour: "red" } }
      expect(response).to redirect_to(step_path("sign-in"))

      post one_login_redirect_path(course_identifier: course.identifier)
      post "/users/auth/teacher_auth/callback"
      expect(response).to redirect_to(step_path("course-start-date"))

      expect(session[:registration]).to include(course.identifier => hash_including("colour" => "red"))
    end

    it "sends a signed out teacher to the first unanswered step before sign in" do
      get step_path("course-start-date")

      expect(response).to redirect_to(step_path("colour"))
    end

    it "sends a signed out teacher to sign in once the earlier step is answered" do
      patch step_path("colour"), params: { colour: { colour: "red" } }
      get step_path("course-start-date")

      expect(response).to redirect_to(step_path("sign-in"))
    end
  end
end
