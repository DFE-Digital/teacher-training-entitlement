require "rails_helper"

RSpec.describe "Registration steps", type: :request do
  let(:user) { create(:user) }
  let(:course) { create(:course) }
  let(:course_cohort) { course.course_cohorts.first }
  let(:provider) { course_cohort.lead_providers.first }
  let(:flag_enabled) { true }
  let(:session_store) { { user_id: user.id }.with_indifferent_access }

  before do
    Flipper.enable(Feature::REGISTRATION_OPEN)
    Flipper.enable(Feature::REGISTRATION_DFE_WIZARD) if flag_enabled
    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return(session_store)
  end

  def step_path(step, identifier: course.identifier)
    registration_step_path(course_identifier: identifier, step:)
  end

  context "when the feature flag is off" do
    let(:flag_enabled) { false }

    it "is not found" do
      get step_path("course-start-date")

      expect(response).to have_http_status(:not_found)
    end
  end

  context "when signed out" do
    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
    end

    it "redirects a step after sign in to the sign in step" do
      get step_path("course-start-date")

      expect(response).to redirect_to(step_path("sign-in"))
    end

    it "redirects when submitting a step after sign in" do
      patch step_path("choose-your-provider"), params: { choose_your_provider: { lead_provider_id: provider.id } }

      expect(response).to redirect_to(step_path("sign-in"))
    end

    it "shows the sign in page with the start button for the course" do
      get step_path("sign-in")

      expect(response.body).to include("Start now").and include(%(action="/one-login?course_identifier=#{course.identifier}"))
    end
  end

  context "when signed in" do
    it "skips the sign in step" do
      get step_path("sign-in")

      expect(response).to redirect_to(step_path("course-start-date"))
    end

    it "does not link back to the sign in page from course start date" do
      get step_path("course-start-date")

      expect(response.body).not_to include(step_path("sign-in"))
    end
  end

  describe "course start date" do
    it "lists the open start dates of the course" do
      get step_path("course-start-date")

      expect(response.body).to include(course_cohort.cohort.name)
    end

    it "offers later" do
      get step_path("course-start-date")

      expect(response.body).to include("I want to start at a later date")
    end

    it "shows the already started hint for a start date in the past" do
      course_cohort.update!(training_starts_at: 1.week.ago.to_date)

      get step_path("course-start-date")

      expect(response.body).to include("This course has already started.")
    end

    it "does not show the hint for a start date in the future" do
      course_cohort.update!(training_starts_at: 1.week.from_now.to_date)

      get step_path("course-start-date")

      expect(response.body).not_to include("This course has already started.")
    end

    it "redisplays the step with an error when nothing is picked" do
      patch step_path("course-start-date")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Choose your course start date.")
    end

    it "moves on to choose your provider when a start date is picked" do
      patch step_path("course-start-date"), params: { course_start_date: { course_start_date: course_cohort.ecf_id } }

      expect(response).to redirect_to(step_path("choose-your-provider"))
    end

    it "moves on to cannot register yet and flags the user when later is picked" do
      patch step_path("course-start-date"), params: { course_start_date: { course_start_date: "later" } }

      expect(response).to redirect_to(step_path("cannot-register-yet"))
      expect(user.reload.notify_user_for_future_reg).to be(true)
    end
  end

  describe "full journey" do
    before do
      patch step_path("course-start-date"), params: { course_start_date: { course_start_date: course_cohort.ecf_id } }
    end

    it "shows the providers of the course cohort" do
      get step_path("choose-your-provider")

      expect(response.body).to include(ERB::Util.html_escape(provider.name))
    end

    it "links back to the previous step" do
      get step_path("choose-your-provider")

      expect(response.body).to include(%(href="#{step_path('course-start-date')}"))
    end

    def pass_funding_steps
      patch step_path("choose-your-provider"), params: { choose_your_provider: { lead_provider_id: provider.id } }
      expect(response).to redirect_to(step_path("teacher-catchment"))

      patch step_path("teacher-catchment"), params: { teacher_catchment: { teacher_catchment: "other" } }
      patch step_path("funding-your-course"), params: { funding_your_course: { funding: "self" } }
      expect(response).to redirect_to(step_path("share-provider"))
    end

    it "reaches the submitted page after the shared steps" do
      pass_funding_steps

      patch step_path("share-provider"), params: { share_provider: { can_share_choices: "1" } }
      expect(response).to redirect_to(step_path("check-answers"))

      get step_path("check-answers")
      expect(response.body).to include(ERB::Util.html_escape(provider.name))

      patch step_path("check-answers")
      expect(response).to redirect_to(step_path("registration-submitted"))

      get step_path("registration-submitted")
      expect(response).to have_http_status(:ok)
    end

    context "when the answers are submitted" do
      before do
        pass_funding_steps
        patch step_path("share-provider"), params: { share_provider: { can_share_choices: "1" } }
      end

      it "creates one pending application" do
        expect { patch step_path("check-answers") }.to change { user.applications.count }.by(1)

        expect(user.applications.last).to have_attributes(
          course_cohort:,
          lead_provider: provider,
          institution: nil,
          status: Application::PENDING,
          funding_eligibility: "ineligible_setting",
          funding_choice: "self",
        )
      end

      it "queues the submission email once" do
        expect { patch step_path("check-answers") }.to have_enqueued_job(Emails::SendApplicationSubmissionEmailJob).once
      end

      it "saves the registration data keys of the legacy journey" do
        patch step_path("check-answers")

        expect(user.applications.last.registration_data).to eq(
          "can_share_choices" => "1",
          "course_cohort_ecf_id" => course_cohort.ecf_id,
          "course_start_date" => course_cohort.ecf_id,
          "funding" => "self",
          "funding_amount" => nil,
          "lead_provider_id" => provider.id.to_s,
          "submitted" => true,
          "teacher_catchment" => "other",
        )
      end

      it "does not create a second application when going back and submitting again" do
        patch step_path("check-answers")

        expect {
          get step_path("check-answers")
          patch step_path("check-answers")
        }.not_to(change(Application, :count))
      end

      it "starts again when going back to check answers" do
        patch step_path("check-answers")

        get step_path("check-answers")

        expect(response).to redirect_to(step_path("course-start-date"))
      end

      it "keeps showing the submitted page when it is refreshed" do
        patch step_path("check-answers")

        get step_path("registration-submitted")
        get step_path("registration-submitted")

        expect(response).to have_http_status(:ok)
      end

      it "does not create an application twice when changing an earlier answer after submitting" do
        patch step_path("check-answers")

        expect {
          patch step_path("teacher-catchment"), params: { teacher_catchment: { teacher_catchment: "ENG" } }
        }.not_to(change(Application, :count))
      end

      it "does not show the submitted page once an answer is changed after submitting" do
        patch step_path("check-answers")
        patch step_path("course-start-date"), params: { course_start_date: { course_start_date: course_cohort.ecf_id } }

        get step_path("registration-submitted")

        expect(response).to redirect_to(step_path("choose-your-provider"))
      end

      it "does not show the submitted page once the journey is answered again after submitting" do
        patch step_path("check-answers")
        patch step_path("course-start-date"), params: { course_start_date: { course_start_date: course_cohort.ecf_id } }
        pass_funding_steps
        patch step_path("share-provider"), params: { share_provider: { can_share_choices: "1" } }

        get step_path("registration-submitted")

        expect(response).to redirect_to(step_path("check-answers"))
      end

      it "links the submitted page to the submitted application" do
        patch step_path("check-answers")

        get step_path("registration-submitted")

        expect(response.body).to include(application_path(user.applications.last.ecf_id))
      end

      context "when the teacher already has an application for the course cohort" do
        before { create(:application, user:, course_cohort:) }

        it "creates nothing" do
          expect { patch step_path("check-answers") }.not_to(change(Application, :count))
        end

        it "shows an error instead of raising" do
          patch step_path("check-answers")

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("We could not submit your registration")
        end

        it "prefixes the page title with Error" do
          patch step_path("check-answers")

          expect(response.body).to match(/<title[^>]*>\s*Error: /)
        end

        it "keeps the answers" do
          patch step_path("check-answers")

          get step_path("check-answers")

          expect(response).to have_http_status(:ok)
        end
      end
    end

    it "does not show the submitted page before check answers is submitted" do
      pass_funding_steps
      patch step_path("share-provider"), params: { share_provider: { can_share_choices: "1" } }

      get step_path("registration-submitted")

      expect(response).to redirect_to(step_path("check-answers"))
    end

    it "shows the error messages of the step when nothing is picked" do
      patch step_path("choose-your-provider")

      expect(response.body).to include("Choose a provider")
    end

    it "asks for the data sharing agreement" do
      pass_funding_steps
      patch step_path("share-provider"), params: { share_provider: { can_share_choices: "0" } }

      expect(response.body).to include("You must agree to share data with providers to continue")
    end

    it "keeps the answers of different courses apart" do
      other_course = create(:course)

      get step_path("choose-your-provider", identifier: other_course.identifier)

      expect(response).to redirect_to(step_path("course-start-date", identifier: other_course.identifier))
    end
  end

  describe "a step that has not been reached" do
    it "redirects to the first step not completed" do
      get step_path("share-provider")

      expect(response).to redirect_to(step_path("course-start-date"))
    end

    it "redirects to the first step not completed when submitting" do
      patch step_path("share-provider"), params: { share_provider: { can_share_choices: "1" } }

      expect(response).to redirect_to(step_path("course-start-date"))
    end
  end

  describe "a step url that is not canonical" do
    it "is not found" do
      get step_path("course_start_date")

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "unknown step" do
    it "is not found" do
      get step_path("nope")

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "unknown course" do
    it "is not found" do
      get step_path("course-start-date", identifier: "unknown")

      expect(response).to have_http_status(:not_found)
    end
  end
end
