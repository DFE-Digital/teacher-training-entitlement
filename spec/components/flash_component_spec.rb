require "rails_helper"

RSpec.describe FlashComponent, type: :component do
  subject(:rendered) { rendered_content }

  context "when flash contains a notice string" do
    let(:flash) { { notice: "My message" } }

    it "renders the default notice title and message" do
      render_inline(described_class.new(flash:))

      expect(rendered).to have_css(".govuk-notification-banner__title", text: "Important")
      expect(rendered).to have_css(".govuk-notification-banner__heading", text: "My message")
    end
  end

  context "when flash contains a notice hash" do
    let(:flash) do
      {
        notice: {
          title: "My Title",
          message: "My Message",
        },
      }
    end

    it "renders the custom title and message" do
      render_inline(described_class.new(flash:))

      expect(rendered).to have_css(".govuk-notification-banner__title", text: "My Title")
      expect(rendered).to have_css(".govuk-notification-banner__heading", text: "My Message")
    end
  end

  context "when flash contains a success string" do
    let(:flash) { { success: "Saved successfully" } }

    it "renders a success banner with the default title" do
      render_inline(described_class.new(flash:))

      expect(rendered).to have_css(".govuk-notification-banner--success")
      expect(rendered).to have_css(".govuk-notification-banner__title", text: "Success")
      expect(rendered).to have_css(".govuk-notification-banner__heading", text: "Saved successfully")
    end
  end

  context "when flash contains a success hash" do
    let(:flash) do
      {
        success: {
          title: "Custom success",
          message: "Everything worked",
        },
      }
    end

    it "renders a success banner with the custom title and message" do
      render_inline(described_class.new(flash:))

      expect(rendered).to have_css(".govuk-notification-banner--success")
      expect(rendered).to have_css(".govuk-notification-banner__title", text: "Custom success")
      expect(rendered).to have_css(".govuk-notification-banner__heading", text: "Everything worked")
    end
  end

  context "when flash contains an alert string" do
    let(:flash) { { alert: "Something went wrong" } }

    it "renders the error title and alert message" do
      render_inline(described_class.new(flash:))

      expect(rendered).to have_css(".govuk-notification-banner__title", text: "Error")
      expect(rendered).to have_css(".govuk-notification-banner__heading", text: "Something went wrong")
    end
  end
end
