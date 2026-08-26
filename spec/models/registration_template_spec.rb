require "rails_helper"

RSpec.describe RegistrationTemplate do
  it "stores its template metadata" do
    registration_template = described_class.create!(
      name: "NPD funding eligibility",
      description: "Adds the NPD funding eligibility steps.",
      template_generating_service_class: "Registrations::StepTemplates::Courses::NpdService",
    )

    expect(registration_template).to have_attributes(
      name: "NPD funding eligibility",
      description: "Adds the NPD funding eligibility steps.",
      template_generating_service_class: "Registrations::StepTemplates::Courses::NpdService",
    )
  end

  describe "#template_generating_services" do
    it "returns classes derived from the base step-template service" do
      expect(described_class.new.template_generating_services).to include(
        "Registrations::StepTemplates::Courses::NpdService",
      )
    end
  end
end
