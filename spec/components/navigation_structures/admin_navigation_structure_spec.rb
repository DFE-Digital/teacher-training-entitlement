require "rails_helper"

RSpec.describe NavigationStructures::AdminNavigationStructure, type: :component do
  subject(:instance) { described_class.new(admin) }

  let(:admin) { build_stubbed(:admin) }

  describe "#primary_structure" do
    subject { instance.primary_structure }

    expected_structure =
      {
        "Registration periods" => "/admin/cohorts",
        "Courses" => "/admin/courses",
        "Applications" => "/admin/applications",
        "Providers" => "/admin/providers",
        "Finance" => "/admin/finance/statements",
        "Delivery partners" => "/admin/delivery-partners",
        "Users" => "/admin/users",
        "Settings" => "/admin/settings",
        "Workplaces" => "/admin/schools",
        "Glossary" => "/admin/glossary",
      }
    expected_structure.each_with_index do |(name, href), i|
      it "#{name} with href #{href} is at position #{i + 1}" do
        expect(subject[i].name).to eql(name)
        expect(subject[i].href).to eql(href)
      end
    end

    it "has the expected number of items" do
      expect(subject.size).to eql(expected_structure.size)
    end

    it "excludes feature flags" do
      expect(subject.map(&:name)).not_to include("Feature flags")
    end

    context "when user is a super admin" do
      let(:admin) { build_stubbed(:super_admin) }

      it "does not include feature flags in the primary navigation" do
        expect(subject.map(&:name)).not_to include("Feature flags")
      end

      it "does not include admins in the primary navigation" do
        expect(subject.map(&:name)).not_to include("Admins")
      end
    end
  end

  describe "#service_navigation_items" do
    subject(:service_navigation_items) { instance.service_navigation_items }

    it "includes settings in the primary service navigation" do
      expect(service_navigation_items.map { |item| item[:text] }).to include("Settings")
    end
  end

  describe "#sub_navigation_structure" do
    subject(:sub_navigation_structure) { instance.sub_navigation_structure(path) }

    let(:path) { "/admin/settings" }

    it "groups service setting links under Service settings" do
      expect(sub_navigation_structure.map(&:name)).to contain_exactly(
        "Bulk changes",
        "Action logs",
        "Registration closed",
      )
    end

    context "when user is a super admin" do
      let(:admin) { build_stubbed(:super_admin) }

      it "includes super admin service setting links" do
        expect(sub_navigation_structure.map(&:name)).to include("Feature flags", "Admins")
      end
    end

    context "when the path is not in settings" do
      let(:path) { "/admin/applications" }

      it { is_expected.to be_empty }
    end
  end

  describe "#sub_navigation_heading" do
    it "shows the Service settings heading for service setting paths" do
      expect(instance.sub_navigation_heading("/admin/settings")).to eq(text: "Service settings", visible: true)
    end

    it "does not show the Service settings heading for other paths" do
      expect(instance.sub_navigation_heading("/admin/applications")).to eq({})
    end
  end
end
