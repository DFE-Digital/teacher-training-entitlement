require "rails_helper"

RSpec.describe NavigationStructures::AdminNavigationStructure, type: :component do
  subject(:instance) { described_class.new(admin) }

  let(:admin) { build_stubbed(:admin) }

  describe "#primary_structure" do
    subject { instance.primary_structure }

    expected_structure =
      {
        "Service settings" => "/admin/registration-closed",
        "Registration periods" => "/admin/cohorts",
        "Courses" => "/admin/courses",
        "Applications" => "/admin/applications",
        "Providers" => "/admin/providers",
        "Finance" => "/admin/finance/statements",
        "Delivery partners" => "/admin/delivery-partners",
        "Users" => "/admin/users",
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

    it "excludes service settings from the primary service navigation" do
      expect(service_navigation_items.map { |item| item[:text] }).not_to include("Service settings")
    end
  end

  describe "#sub_structure" do
    subject(:sub_structure) { instance.sub_structure(path) }

    let(:path) { "/admin/schools" }

    it "groups service setting links under Service settings" do
      expect(sub_structure.map(&:name)).to contain_exactly(
        "Bulk changes",
        "Action logs",
        "Registration closed",
        "Workplaces",
        "Glossary",
      )
    end

    context "when user is a super admin" do
      let(:admin) { build_stubbed(:super_admin) }

      it "includes super admin service setting links" do
        expect(sub_structure.map(&:name)).to include("Feature flags", "Admins")
      end
    end
  end

  describe "#sub_navigation_heading" do
    it "shows the Service settings heading for service setting paths" do
      expect(instance.sub_navigation_heading("/admin/schools")).to eq(text: "Service settings", visible: true)
    end

    it "shows the Service settings heading for other paths" do
      expect(instance.sub_navigation_heading("/admin/applications")).to eq(text: "Service settings", visible: true)
    end
  end
end
