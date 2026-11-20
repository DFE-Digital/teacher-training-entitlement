require "rails_helper"

RSpec.describe "registrations/_check_answers.html.erb", type: :view do
  subject(:rendered_page) { Capybara.string(rendered) }

  let(:provider_step) do
    instance_double(
      RegistrationStep,
      answer_key: :provider_id,
      answer_display_name: "Provider",
      display_on_check_answers?: true,
      display_answer_value: "Provider One",
      slug: "choose-provider",
    )
  end
  let(:sharing_step) do
    instance_double(
      RegistrationStep,
      answer_key: :can_share_choices,
      answer_display_name: "Sharing information",
      display_on_check_answers?: true,
      display_answer_value: "Yes",
      slug: "share-information",
    )
  end
  let(:unlabelled_step) do
    instance_double(
      RegistrationStep,
      answer_key: :unmapped_answer,
      answer_display_name: nil,
      display_on_check_answers?: true,
      display_answer_value: "raw value",
      slug: "unmapped-step",
    )
  end
  let(:journey) do
    instance_double(
      RegistrationJourney,
      course: nil,
      registration_steps: [provider_step, sharing_step, unlabelled_step],
      slug: "demo-journey",
    )
  end
  let(:router_step) do
    instance_double(
      Registrations::RouterStep,
      registration_journey: journey,
      registration_journey_slug: journey.slug,
      captured_values: { "provider_id" => "provider-1", "can_share_choices" => "1", "unmapped_answer" => "raw value" },
    )
  end

  before do
    render partial: "registrations/check_answers", locals: { router_step: }
  end

  it "renders each answer with its own label and change link" do
    rows = rendered_page.all(".govuk-summary-list__row")

    expect(rows[0]).to have_css(".govuk-summary-list__key", text: "Provider", exact_text: true)
    expect(rows[0]).to have_text("Provider One")
    expect(rows[0]).to have_link("Change", href: step_registration_path(journey.slug, provider_step.slug))

    expect(rows[1]).to have_css(".govuk-summary-list__key", text: "Sharing information", exact_text: true)
    expect(rows[1]).to have_text("Yes")
    expect(rows[1]).to have_link("Change", href: step_registration_path(journey.slug, sharing_step.slug))
  end

  it "humanizes the answer key when the step has no display name" do
    row = rendered_page.all(".govuk-summary-list__row")[2]

    expect(row).to have_css(".govuk-summary-list__key", text: "Unmapped answer", exact_text: true)
    expect(row).to have_text("raw value")
    expect(row).to have_link("Change", href: step_registration_path(journey.slug, unlabelled_step.slug))
  end
end
