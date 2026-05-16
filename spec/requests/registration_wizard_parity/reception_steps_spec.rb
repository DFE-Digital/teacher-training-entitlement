require "rails_helper"

RSpec.describe "Registration wizard parity / Reception steps", type: :request do
  let(:user) { create(:user, :with_verified_trn) }
  let(:lead_provider) { create(:lead_provider) }
  let(:course) { create(:course, display: true, lead_provider:) }
  let(:school) { create(:school, :funding_eligible_establishment_type_code, urn: "123456") }
  let(:request_session) { {}.with_indifferent_access }

  let(:old_base_store) do
    {
      "course_start_date" => "yes",
      "course_start" => "In autumn 2025",
      "course_identifier" => course.identifier,
      "lead_provider_id" => lead_provider.id.to_s,
    }
  end

  let(:new_base_store) do
    {
      confirmation: "yes",
      course_identifier: course.identifier,
      lead_provider_id: lead_provider.id.to_s,
    }
  end

  before do
    school

    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return(request_session)
  end

  describe "choose your course" do
    it "redirects to choose your provider after a course is selected" do
      expect_matching_redirect(
        old: wizard(:old, "choose-your-course", {}, params: { registration_wizard: { course_identifier: course.identifier } }),
        new: wizard(:new, "choose-your-course", {}, params: { "choose-your-course" => { course_identifier: course.identifier } }),
        old_path: "/registration/choose-your-provider",
        new_path: "/reception-registration/choose-your-provider",
      )
    end
  end

  describe "choose your provider" do
    it "renders the provider options" do
      expect_matching_content(
        old: wizard(:old, "choose-your-provider"),
        new: wizard(:new, "choose-your-provider"),
        content: [
          lead_provider.name,
          I18n.t("helpers.label.registration_wizard.lead_provider_id_options.not_chosen"),
        ],
      )
    end

    it "redirects to teacher catchment after a provider is selected" do
      expect_matching_redirect(
        old: wizard(:old, "choose-your-provider", {}, params: { registration_wizard: { lead_provider_id: lead_provider.id.to_s } }),
        new: wizard(:new, "choose-your-provider", {}, params: { "choose-your-provider" => { lead_provider_id: lead_provider.id.to_s } }),
        old_path: "/registration/teacher-catchment",
        new_path: "/reception-registration/teacher-catchment",
      )
    end

    it "redirects to choose a TTE and provider when no provider was chosen" do
      expect_matching_redirect(
        old: wizard(:old, "choose-your-provider", {}, params: { registration_wizard: { lead_provider_id: "not_chosen" } }),
        new: wizard(:new, "choose-your-provider", {}, params: { "choose-your-provider" => { lead_provider_id: "not_chosen" } }),
        old_path: "/registration/choose-a-tte-and-provider",
        new_path: "/reception-registration/choose-a-tte-and-provider",
      )
    end
  end

  describe "teacher catchment" do
    it "redirects to work setting after the user answers" do
      expect_matching_redirect(
        old: wizard(:old, "teacher-catchment", {}, params: { registration_wizard: { teacher_catchment: "england" } }),
        new: wizard(:new, "teacher-catchment", {}, params: { "teacher-catchment" => { teacher_catchment: "england" } }),
        old_path: "/registration/work-setting",
        new_path: "/reception-registration/work-setting",
      )
    end
  end

  describe "work setting" do
    it "redirects to choose school for school settings" do
      expect_matching_redirect(
        old: wizard(:old, "work-setting", { "teacher_catchment" => "england" }, params: { registration_wizard: { work_setting: "a_school" } }),
        new: wizard(:new, "work-setting", { teacher_catchment: "england" }, params: { "work-setting" => { work_setting: "a_school" } }),
        old_path: "/registration/choose-school",
        new_path: "/reception-registration/choose-school",
      )
    end

    it "redirects to kind of nursery for childcare settings" do
      expect_matching_redirect(
        old: wizard(:old, "work-setting", { "teacher_catchment" => "england" }, params: { registration_wizard: { work_setting: "early_years_or_childcare" } }),
        new: wizard(:new, "work-setting", { teacher_catchment: "england" }, params: { "work-setting" => { work_setting: "early_years_or_childcare" } }),
        old_path: "/registration/kind-of-nursery",
        new_path: "/reception-registration/kind-of-nursery",
      )
    end

    it "redirects to ineligible for funding for other settings" do
      expect_matching_redirect(
        old: wizard(:old, "work-setting", { "teacher_catchment" => "england" }, params: { registration_wizard: { work_setting: "other" } }),
        new: wizard(:new, "work-setting", { teacher_catchment: "england" }, params: { "work-setting" => { work_setting: "other" } }),
        old_path: "/registration/ineligible-for-funding",
        new_path: "/reception-registration/ineligible-for-funding",
      )
    end
  end

  describe "kind of nursery" do
    it "redirects to choose school for public nursery settings" do
      expect_matching_redirect(
        old: wizard(:old, "kind-of-nursery", old_childcare_store, params: { registration_wizard: { kind_of_nursery: "local_authority_maintained_nursery" } }),
        new: wizard(:new, "kind-of-nursery", new_childcare_store, params: { "kind-of-nursery" => { kind_of_nursery: "local_authority_maintained_nursery" } }),
        old_path: "/registration/choose-school",
        new_path: "/reception-registration/choose-school",
      )
    end

    it "redirects to ineligible for funding for private nursery settings" do
      expect_matching_redirect(
        old: wizard(:old, "kind-of-nursery", old_childcare_store, params: { registration_wizard: { kind_of_nursery: "private_nursery" } }),
        new: wizard(:new, "kind-of-nursery", new_childcare_store, params: { "kind-of-nursery" => { kind_of_nursery: "private_nursery" } }),
        old_path: "/registration/ineligible-for-funding",
        new_path: "/reception-registration/ineligible-for-funding",
      )
    end
  end

  describe "choose school" do
    it "redirects to possible funding for eligible schools" do
      expect_matching_redirect(
        old: wizard(:old, "choose-school", old_school_store, params: { registration_wizard: { institution_id: school.institution.id.to_s } }),
        new: wizard(:new, "choose-school", new_school_store, params: { "choose-school" => { institution_id: school.institution.id.to_s } }),
        old_path: "/registration/possible-funding",
        new_path: "/reception-registration/possible-funding",
      )
    end

    it "renders again when no school is selected" do
      expect_matching_status(
        old: wizard(:old, "choose-school", old_school_store, params: { registration_wizard: { institution_id: nil } }),
        new: wizard(:new, "choose-school", new_school_store, params: { "choose-school" => { institution_id: nil } }),
        status: :ok,
      )
    end
  end

  describe "possible funding" do
    it "redirects to share provider on continue" do
      expect_matching_redirect(
        old: wizard(:old, "possible-funding", old_possible_funding_store),
        new: wizard(:new, "possible-funding", new_possible_funding_store),
        old_path: "/registration/share-provider",
        new_path: "/reception-registration/share-provider",
      )
    end
  end

  describe "funding your course" do
    it "redirects to share provider after funding is selected" do
      expect_matching_redirect(
        old: wizard(:old, "funding-your-course", old_ineligible_store, params: { registration_wizard: { funding: "self" } }),
        new: wizard(:new, "funding-your-course", new_ineligible_store, params: { "funding-your-course" => { funding: "self" } }),
        old_path: "/registration/share-provider",
        new_path: "/reception-registration/share-provider",
      )
    end
  end

  describe "share provider" do
    it "redirects to check answers when sharing consent is accepted" do
      expect_matching_redirect(
        old: wizard(:old, "share-provider", old_share_provider_store, params: { registration_wizard: { can_share_choices: "1" } }),
        new: wizard(:new, "share-provider", new_share_provider_store, params: { "share-provider" => { can_share_choices: "1" } }),
        old_path: "/registration/check-answers",
        new_path: "/reception-registration/check-answers",
      )
    end
  end

  describe "copy pages" do
    it "renders cannot register yet content" do
      expect_matching_content(
        old: wizard(:old, "cannot-register-yet"),
        new: wizard(:new, "cannot-register-yet"),
        content: ["You cannot register yet", "Registrations are currently only open for courses starting in autumn 2025."],
      )
    end

    it "renders choose a TTE and provider content" do
      expect_matching_content(
        old: wizard(:old, "choose-a-tte-and-provider"),
        new: wizard(:new, "choose-a-tte-and-provider"),
        content: ["Choose a TTE course and provider", "Learn about TTEs"],
      )
    end

    it "renders ineligible funding content" do
      expect_matching_content(
        old: wizard(:old, "ineligible-for-funding", old_ineligible_store),
        new: wizard(:new, "ineligible-for-funding", new_ineligible_store),
        content: ["Funding", "not eligible for scholarship funding"],
      )
    end
  end

  def old_childcare_store
    old_base_store.merge(
      "teacher_catchment" => "england",
      "work_setting" => "early_years_or_childcare",
      "works_in_school" => "no",
      "works_in_childcare" => "yes",
    )
  end

  def new_childcare_store
    new_base_store.merge(
      teacher_catchment: "england",
      work_setting: "early_years_or_childcare",
      works_in_school: false,
      works_in_childcare: true,
    )
  end

  def old_school_store
    old_base_store.merge(
      "teacher_catchment" => "england",
      "work_setting" => "a_school",
      "works_in_school" => "yes",
      "works_in_childcare" => "no",
    )
  end

  def new_school_store
    new_base_store.merge(
      teacher_catchment: "england",
      work_setting: "a_school",
      works_in_school: true,
      works_in_childcare: false,
    )
  end

  def old_possible_funding_store
    old_school_store.merge(
      "institution_id" => school.institution.id.to_s,
      "funding_eligiblity_status_code" => FundingEligibility::FUNDED_ELIGIBILITY_RESULT,
      "eligible_for_funding" => true,
    )
  end

  def new_possible_funding_store
    new_school_store.merge(
      institution_id: school.institution.id.to_s,
      funding_eligibility_status_code: FundingEligibility::FUNDED_ELIGIBILITY_RESULT,
      eligible_for_funding: true,
    )
  end

  def old_ineligible_store
    old_base_store.merge(
      "teacher_catchment" => "england",
      "work_setting" => "other",
      "works_in_school" => "no",
      "works_in_childcare" => "no",
      "funding_eligiblity_status_code" => FundingEligibility::INELIGIBLE_SETTING,
      "eligible_for_funding" => false,
    )
  end

  def new_ineligible_store
    new_base_store.merge(
      teacher_catchment: "england",
      work_setting: "other",
      works_in_school: false,
      works_in_childcare: false,
      funding_eligibility_status_code: FundingEligibility::INELIGIBLE_SETTING,
      eligible_for_funding: false,
    )
  end

  def old_share_provider_store
    old_ineligible_store.merge("funding" => "self")
  end

  def new_share_provider_store
    new_ineligible_store.merge(funding: "self")
  end

  def wizard(kind, step, store = {}, params: nil)
    if kind == :old
      {
        url: "/registration/#{step}",
        session: { user_id: user.id, registration_store: old_base_store.merge(store) },
        params: params || {},
      }
    else
      {
        url: "/reception-registration/#{step}",
        session: { user_id: user.id, "registrations_#{user.id}" => new_base_store.merge(store) },
        params: params || {},
      }
    end
  end

  def expect_matching_content(old:, new:, content:)
    [old, new].each do |config|
      use_session(config[:session])
      get config[:url]

      expect(response).to have_http_status(:ok)
      content.each { |text| expect(response.body).to include(CGI.escapeHTML(text)) }
    end
  end

  def expect_matching_redirect(old:, new:, old_path:, new_path:)
    [[old, old_path], [new, new_path]].each do |config, path|
      use_session(config[:session])
      patch config[:url], params: config[:params]

      expect(response).to redirect_to(path)
    end
  end

  def expect_matching_status(old:, new:, status:)
    [old, new].each do |config|
      use_session(config[:session])
      patch config[:url], params: config[:params]

      expect(response).to have_http_status(status)
    end
  end

  def use_session(session)
    request_session.clear
    request_session.merge!(session.with_indifferent_access)
  end
end
