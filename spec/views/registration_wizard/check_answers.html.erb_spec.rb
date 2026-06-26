require "rails_helper"

RSpec.describe "registration_wizard/check_answers.html.erb", type: :view do
  subject(:rendered_page) { Capybara.string(render) }

  let(:course) { create(:course, :npd_eirt) }
  let(:lead_provider) { create(:lead_provider) }
  let(:user) { create(:user) }
  let(:store) do
    {
      "lead_provider_id" => lead_provider.id,
      "course_start" => "April 2026",
      "teacher_catchment" => "england",
    }
  end

  let(:wizard) do
    course

    RegistrationWizard.new(
      current_step: :check_answers,
      store:,
      request: controller.request,
      current_user: user,
    )
  end

  before do
    assign(:wizard, wizard)
    assign(:form, Questionnaires::CheckAnswers.new(wizard:))
    controller.request.path_parameters[:step] = "check-answers"
  end

  it "does not render a change link for answers without a change step" do
    expect(wizard.answers.find { _1.key == "Course" }.change_step).to be_nil

    within_course_row = rendered_page
      .all(".govuk-summary-list__row")
      .find { _1.has_css?(".govuk-summary-list__key", text: "Course", exact_text: true) }
    expect(within_course_row).not_to have_link("Change")
  end

  it "renders a change link for answers with a change step" do
    within_provider_row = rendered_page
      .all(".govuk-summary-list__row")
      .find { _1.has_css?(".govuk-summary-list__key", text: "Provider", exact_text: true) }

    expect(within_provider_row).to have_link("Change", href: "/registration/choose-your-provider/change")
  end
end
