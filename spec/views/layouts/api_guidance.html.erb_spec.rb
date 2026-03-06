require "rails_helper"

RSpec.describe "layouts/api_guidance.html.erb", type: :view do
  subject { Capybara.string(render) }

  describe "header" do
    before do
      view.instance_variable_set(:@page, instance_double(Guidance::GuidancePage, index_page?: true))
    end

    it { is_expected.to have_link("Teacher training entitlement", href: "/api/guidance") }
  end

  describe "sidebar navigation" do
    before do
      view.instance_variable_set(:@page, instance_double(Guidance::GuidancePage, index_page?: false, sections: []))
    end

    it "has links for the guidance navigation structure" do
      expect(subject).to have_link("Get started")
      expect(subject).to have_link("How the API works")
      expect(subject).to have_link("Test environments")
      expect(subject).to have_link("What's new")
      expect(subject).to have_link("How-to guides")
      expect(subject).to have_link("Process diagrams")
      expect(subject).to have_link("Roadmap")
    end
  end
end
