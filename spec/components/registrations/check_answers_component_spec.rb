require "rails_helper"

RSpec.describe Registrations::CheckAnswersComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:course) { create(:course) }
  let(:journey) { create(:journey_definition, course:, slug: "demo-journey") }
  let!(:provider_step) do
    create(:step_definition,
           journey_definition: journey,
           name: "Choose a provider",
           slug: "choose-provider",
           state_store_key: "provider_id",
           answer_display_name: "Provider").tap do |step|
      step.set_answer_options!(answers: [{ name: "Provider One", value: "provider-1" }])
    end
  end
  let!(:topics_step) do
    create(:step_definition,
           journey_definition: journey,
           name: "Topics",
           slug: "topics",
           state_store_key: "topics",
           answer_display_name: "Topics")
  end
  let!(:details_step) do
    create(:step_definition,
           journey_definition: journey,
           name: "Additional details",
           slug: "additional-details",
           state_store_key: "details",
           answer_display_name: "Additional details")
  end
  let(:hidden_step) do
    create(:step_definition,
           journey_definition: journey,
           name: "Internal value",
           slug: "internal-value",
           state_store_key: "internal_value",
           display_on_check_answers: false)
  end
  let(:captured_values) do
    {
      "provider_id" => "provider-1",
      "topics" => %w[Early-years Inclusion],
      "details" => { "level" => "Level 1" },
      "internal_value" => "hidden",
      "completed" => true,
      "blank_value" => "",
    }
  end
  let(:wizard_step) do
    instance_double(
      Registrations::StepDefinitions::FormStep,
      journey_definition: journey,
      journey_slug: journey.slug,
      captured_values:,
    )
  end

  it "renders the course and visible answers with their change links" do
    hidden_step
    render_inline(described_class.new(wizard_step:))

    expect(page).to have_css(".govuk-summary-list__row", count: 4)
    expect(page).to have_css(".govuk-summary-list__key", text: "Course")
    expect(page).to have_css(".govuk-summary-list__value", text: course.name)
    expect(page).to have_css(".govuk-summary-list__key", text: "Provider")
    expect(page).to have_css(".govuk-summary-list__value", text: "Provider One")
    expect(page).to have_css(".govuk-summary-list__value", text: "Early-years")
    expect(page).to have_css(".govuk-summary-list__value", text: "Inclusion")
    expect(page).to have_css(".govuk-summary-list__value", text: "Level: Level 1")
    expect(page).to have_link("Change", href: step_registration_path(journey.slug, provider_step.slug))
    expect(page).to have_link("Change", href: step_registration_path(journey.slug, topics_step.slug))
    expect(page).to have_link("Change", href: step_registration_path(journey.slug, details_step.slug))
    expect(page).not_to have_text("hidden")
    expect(page).not_to have_text("completed")
  end

  context "when the course and state store have no displayable values" do
    let(:course) { nil }
    let(:journey) { create(:journey_definition, slug: "empty-journey") }
    let(:captured_values) { {} }

    it "renders the empty-state message" do
      render_inline(described_class.new(wizard_step:))

      expect(page).to have_text("No answers have been captured yet.")
    end
  end
end
