require "rails_helper"

RSpec.describe "Registration state funded school steps", type: :request do
  let(:user) { create(:user, trn: "1234567") }
  let(:course) { create(:course) }
  let(:course_cohort) { course.course_cohorts.first }
  let(:provider) { course_cohort.lead_providers.first }
  let(:session_store) { { user_id: user.id }.with_indifferent_access }
  let(:state_funded) { Institution::STATE_FUNDED_INSTITUTION }
  let(:ineligible_school) { create(:institution).tap { _1.institutionable.update!(establishment_type_code: "11") } }

  before do
    Flipper.enable(Feature::REGISTRATION_OPEN)
    Flipper.enable(Feature::REGISTRATION_DFE_WIZARD)
    allow_any_instance_of(ApplicationController).to receive(:session).and_return(session_store)

    patch step_path("course-start-date"), params: { course_start_date: { course_start_date: course_cohort.ecf_id } }
    patch step_path("choose-your-provider"), params: { choose_your_provider: { lead_provider_id: provider.id } }
  end

  def step_path(step)
    registration_step_path(course_identifier: course.identifier, step:)
  end

  def answer(step, **params)
    patch step_path(step.dasherize), params: { step => params }
  end

  def expect_redirect_to(step)
    expect(response).to redirect_to(step_path(step))
  end

  describe "teacher catchment" do
    it "asks if the teacher works in England after the provider" do
      get step_path("teacher-catchment")

      expect(response.body).to include("Do you work in England?")
    end

    it "shows an error when nothing is picked" do
      answer("teacher_catchment")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Select ‘Yes&#39; if you work in England")
    end
  end

  describe "work setting" do
    before { answer("teacher_catchment", teacher_catchment: "ENG") }

    it "offers the three settings" do
      get step_path("work-setting")

      expect(response.body).to include("State-funded nursery, pre-school, school or academy trust", "Private nursery, pre-school or school", "Other")
    end

    it "shows an error when nothing is picked" do
      answer("work_setting")

      expect(response.body).to include("Select the setting that you work in")
    end
  end

  describe "paths" do
    let(:school) { create(:institution, :with_address) }

    def finish_journey
      answer("share_provider", can_share_choices: "1")
      expect_redirect_to("check-answers")
      patch step_path("check-answers")
      expect_redirect_to("registration-submitted")
    end

    context "with a funded school" do
      it "goes through the questions of the legacy journey" do
        answer("teacher_catchment", teacher_catchment: "ENG")
        expect_redirect_to("work-setting")
        answer("work_setting", work_setting: state_funded)
        expect_redirect_to("choose-school")
        answer("choose_school", institution_id: school.id)
        expect_redirect_to("possible-funding")

        get step_path("possible-funding")
        expect(response.body).to include("You are eligible for funding.")
        expect(response.body).to include(%(href="#{step_path('choose-school')}"))

        answer("possible_funding", funding_amount: 200)
        expect_redirect_to("share-provider")

        finish_journey
      end

      it "shows the answers in check answers" do
        answer("teacher_catchment", teacher_catchment: "ENG")
        answer("work_setting", work_setting: state_funded)
        answer("choose_school", institution_id: school.id)
        answer("possible_funding", funding_amount: 200)
        answer("share_provider", can_share_choices: "1")

        get step_path("check-answers")

        expect(response.body.scan(/govuk-summary-list__key">\s*([^<]+?)\s*</).flatten).to eq(
          ["Course start", "Course", "Provider", "Workplace in England", "Work setting", "Workplace"],
        )
        expect(response.body).to include(school.name)
      end
    end

    context "when working outside England" do
      it "skips to the ineligible page then to funding your course" do
        answer("teacher_catchment", teacher_catchment: "other")
        expect_redirect_to("ineligible-for-funding")

        get step_path("ineligible-for-funding")
        expect(response.body).to include("Funding eligibility result", "This means that you would need to pay for the course another way")

        answer("funding_your_course", funding: "trust")
        expect_redirect_to("share-provider")

        finish_journey
      end

      it "shows the answers in check answers" do
        answer("teacher_catchment", teacher_catchment: "other")
        answer("funding_your_course", funding: "trust")
        answer("share_provider", can_share_choices: "1")

        get step_path("check-answers")

        expect(response.body.scan(/govuk-summary-list__key">\s*([^<]+?)\s*</).flatten).to eq(
          ["Course start", "Course", "Provider", "Workplace in England", "Course funding"],
        )
      end
    end

    context "with a non state funded setting" do
      before do
        answer("teacher_catchment", teacher_catchment: "ENG")
        answer("work_setting", work_setting: Institution::PRIVATE_INSTITUTION)
      end

      it "goes to the ineligible page" do
        expect_redirect_to("ineligible-for-funding")
      end

      it "shows the ineligible setting reason" do
        get step_path("ineligible-for-funding")

        expect(response.body).to include(ERB::Util.html_escape(I18n.t("helpers.title.registration_wizard.ineligible_for_funding")))
      end

      it "requires a funding choice" do
        answer("funding_your_course")

        expect(response.body).to include("Select an option")
      end
    end

    context "with an ineligible establishment" do
      let(:school) { ineligible_school }

      it "goes to the ineligible page then to funding your course" do
        answer("teacher_catchment", teacher_catchment: "ENG")
        answer("work_setting", work_setting: state_funded)
        answer("choose_school", institution_id: school.id)
        expect_redirect_to("ineligible-for-funding")

        answer("funding_your_course", funding: "trust")
        expect_redirect_to("share-provider")

        finish_journey
      end
    end

    context "when previously funded" do
      before do
        create(:application, :with_funded_place, :accepted, user:, course:)
        answer("teacher_catchment", teacher_catchment: "ENG")
        answer("work_setting", work_setting: state_funded)
        answer("choose_school", institution_id: school.id)
      end

      it "goes to the ineligible page then to funding your course" do
        expect_redirect_to("ineligible-for-funding")

        answer("funding_your_course", funding: "trust")
        expect_redirect_to("share-provider")

        finish_journey
      end

      it "shows the previously funded reason" do
        get step_path("ineligible-for-funding")

        expect(response.body).to include("You've already been allocated scholarship funding for the course.")
      end
    end

    context "when the work setting is other and the teacher was previously funded" do
      it "shows the ineligible setting reason as the legacy journey does" do
        create(:application, :with_funded_place, :accepted, user:, course:)
        answer("teacher_catchment", teacher_catchment: "ENG")
        answer("work_setting", work_setting: Institution::OTHER)

        get step_path("ineligible-for-funding")

        expect(response.body).not_to include("already been allocated")
      end
    end

    context "when no school is picked" do
      before do
        answer("teacher_catchment", teacher_catchment: "ENG")
        answer("work_setting", work_setting: state_funded)
      end

      it "asks again after searching" do
        answer("choose_school", institution_id: "other", institution_name: "Somewhere")

        expect_redirect_to("choose-school")
      end

      it "shows the matching schools of the search when JavaScript is disabled" do
        school.update!(name: "Hogwarts")
        answer("choose_school", institution_id: "other", institution_name: "Hogwarts")

        get step_path("choose-school")

        expect(response.body).to include("Hogwarts")
      end

      it "shows a form error when the school does not exist" do
        answer("choose_school", institution_id: "0")

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "shows an error when nothing is entered" do
        answer("choose_school")

        expect(response.body).to include("Enter a workplace name")
      end

      it "does not allow later steps" do
        answer("choose_school", institution_id: "other", institution_name: "Somewhere")
        get step_path("share-provider")

        expect_redirect_to("choose-school")
      end
    end

    context "when the work setting changes from a school to another setting" do
      before do
        answer("teacher_catchment", teacher_catchment: "ENG")
        answer("work_setting", work_setting: state_funded)
        answer("choose_school", institution_id: school.id)
        answer("work_setting", work_setting: Institution::PRIVATE_INSTITUTION)
      end

      it "clears the school and funding answers" do
        answer("funding_your_course", funding: "self")
        answer("work_setting", work_setting: state_funded)

        expect(session_store[:registration][course.identifier]).to include("institution_id" => nil, "funding" => nil)
      end
    end

    context "when the teacher changes the workplace in England answer to no after picking a funded school" do
      before do
        answer("teacher_catchment", teacher_catchment: "ENG")
        answer("work_setting", work_setting: state_funded)
        answer("choose_school", institution_id: school.id)
        answer("possible_funding", funding_amount: 200)
        answer("teacher_catchment", teacher_catchment: "other")
      end

      it "goes to the ineligible page" do
        expect_redirect_to("ineligible-for-funding")

        get step_path("ineligible-for-funding")
        expect(response).to have_http_status(:ok)
      end

      it "clears the dependent answers" do
        expect(session_store[:registration][course.identifier]).to include("work_setting" => nil, "institution_id" => nil, "funding" => nil)
      end

      it "only asks the workplace in England and funding rows in check answers" do
        answer("funding_your_course", funding: "trust")
        answer("share_provider", can_share_choices: "1")
        get step_path("check-answers")

        expect(response.body.scan(/govuk-summary-list__key">\s*([^<]+?)\s*</).flatten).to eq(
          ["Course start", "Course", "Provider", "Workplace in England", "Course funding"],
        )
      end
    end

    context "when possible funding is skipped after a funding choice was made" do
      before do
        answer("teacher_catchment", teacher_catchment: "ENG")
        answer("work_setting", work_setting: state_funded)
        answer("choose_school", institution_id: ineligible_school.id)
        answer("funding_your_course", funding: "self")
        answer("choose_school", institution_id: school.id)
      end

      it "sends the teacher back to possible funding from share provider" do
        get step_path("share-provider")

        expect_redirect_to("possible-funding")
      end
    end

    context "when a funded teacher had chosen a funding choice before" do
      it "clears the funding choice" do
        answer("teacher_catchment", teacher_catchment: "ENG")
        answer("work_setting", work_setting: state_funded)
        answer("choose_school", institution_id: ineligible_school.id)
        answer("funding_your_course", funding: "self")
        answer("choose_school", institution_id: school.id)
        answer("possible_funding", funding_amount: 200)

        expect(session_store[:registration][course.identifier]).to include("funding" => nil, "funding_amount" => 200)
      end
    end
  end
end
