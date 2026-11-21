require "rails_helper"

RSpec.describe "Registration change answers and guards", type: :request do
  let(:user) { create(:user) }
  let(:course) { create(:course) }
  let(:course_cohort) { course.course_cohorts.first }
  let(:provider) { course_cohort.lead_providers.first }
  let(:session_store) { { user_id: user.id }.with_indifferent_access }

  before do
    Flipper.enable(Feature::REGISTRATION_OPEN)
    Flipper.enable(Feature::REGISTRATION_DFE_WIZARD)
    allow_any_instance_of(ApplicationController).to receive(:session).and_return(session_store)
  end

  def step_path(step, **options)
    registration_step_path(course_identifier: course.identifier, step:, **options)
  end

  def answer(step, **params)
    patch step_path(step.dasherize), params: { step => params }
  end

  def answer_up_to_check_answers
    answer("course_start_date", course_start_date: course_cohort.ecf_id)
    answer("choose_your_provider", lead_provider_id: provider.id)
    answer("teacher_catchment", teacher_catchment: "other")
    answer("funding_your_course", funding: "self")
    answer("share_provider", can_share_choices: "1")
  end

  describe "change links on check answers" do
    before { answer_up_to_check_answers }

    it "link to the step with the change flag" do
      get step_path("check-answers")

      expect(response.body).to include(%(href="#{step_path('teacher-catchment', return_to_review: 'teacher_catchment')}"))
    end

    it "keeps the change flag in the form of the step" do
      get step_path("teacher-catchment", return_to_review: "teacher_catchment")

      expect(response.body).to include(%(action="#{step_path('teacher-catchment', return_to_review: 'teacher_catchment')}"))
    end

    it "links back to check answers from the step being changed" do
      get step_path("teacher-catchment", return_to_review: "teacher_catchment")

      expect(response.body).to include(%(href="#{step_path('check-answers')}"))
    end

    it "returns to check answers when the same answer is kept" do
      patch step_path("teacher-catchment", return_to_review: "teacher_catchment"), params: { teacher_catchment: { teacher_catchment: "other" } }

      expect(response).to redirect_to(step_path("check-answers"))
    end

    it "returns to check answers when the provider is changed" do
      patch step_path("choose-your-provider", return_to_review: "choose_your_provider"), params: { choose_your_provider: { lead_provider_id: provider.id } }

      expect(response).to redirect_to(step_path("check-answers"))
    end

    context "when the change leads to new questions" do
      before do
        patch step_path("teacher-catchment", return_to_review: "teacher_catchment"), params: { teacher_catchment: { teacher_catchment: "ENG" } }
      end

      it "goes through them first" do
        expect(response).to redirect_to(step_path("work-setting", return_to_review: "teacher_catchment"))
      end

      it "returns to check answers once they are answered" do
        patch step_path("work-setting", return_to_review: "teacher_catchment"), params: { work_setting: { work_setting: Institution::OTHER } }
        expect(response).to redirect_to(step_path("ineligible-for-funding", return_to_review: "teacher_catchment"))

        patch step_path("ineligible-for-funding", return_to_review: "teacher_catchment")
        expect(response).to redirect_to(step_path("funding-your-course", return_to_review: "teacher_catchment"))

        patch step_path("funding-your-course", return_to_review: "teacher_catchment"), params: { funding_your_course: { funding: "school" } }
        expect(response).to redirect_to(step_path("check-answers"))
      end
    end
  end

  describe "a submitted teacher starting again" do
    before do
      answer_up_to_check_answers
      patch step_path("check-answers")
    end

    it "does not pre-fill the previous answers" do
      get step_path("course-start-date")

      expect(response.body).not_to match(/checked(="checked")?[ >]/)
    end
  end

  describe "submitting the answers", :versioning do
    it "records the public user in the audit trail" do
      answer_up_to_check_answers
      patch step_path("check-answers")

      expect(user.applications.last.versions.last.whodunnit).to eq("Public User #{user.id}")
    end
  end

  describe "page titles" do
    it "match the legacy journey for question pages" do
      get step_path("course-start-date")

      expect(response.body).to match(/<title>\s*Course Start Date\s*- NPD - GOV.UK<\/title>/)
    end

    it "match the legacy journey when the answer is invalid" do
      answer("course_start_date")

      expect(response.body).to include("Form invalid:")
    end
  end

  describe "closed registration" do
    before { Flipper.disable(Feature::REGISTRATION_OPEN) }

    it "shows the closed page for any step" do
      get step_path("course-start-date")

      expect(response).to redirect_to(registration_wizard_show_path(:closed))
    end

    it "shows the closed page when submitting a step" do
      answer("course_start_date", course_start_date: course_cohort.ecf_id)

      expect(response).to redirect_to(registration_wizard_show_path(:closed))
    end

    it "shows the closed page for the course selector" do
      get registration_courses_path

      expect(response).to redirect_to(registration_closed_path)
    end

    context "when the teacher is a closed registration user" do
      before { Flipper.enable_actor(Feature::REGISTRATION_OPEN, user) }

      it "lets them through" do
        get step_path("course-start-date")

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "registration disabled" do
    before { Feature.disable_registration! }

    it "hides the start button of the sign in step" do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)

      get step_path("sign-in")

      expect(response.body).not_to include("Start now")
    end
  end
end
