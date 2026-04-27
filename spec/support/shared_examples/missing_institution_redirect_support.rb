require "rails_helper"

RSpec.shared_examples "it redirects on missing mandatory institution" do
  before do
    allow(RegistrationWizard).to receive(:new).and_return(missing_institution_wizard.new)
    session["registration_store"] = registration_store
    make_request
  end

  context "when working in a school" do
    let(:registration_store) { { "works_in_school" => "yes" } }

    it { is_expected.to redirect_to registration_wizard_show_path("choose-school") }
  end

  context "when working in a private nursery" do
    let(:registration_store) do
      { "works_in_childcare" => "yes", "kind_of_nursery" => "private_nursery" }
    end

    it { is_expected.to redirect_to registration_wizard_show_path("have-ofsted-urn") }
  end

  context "when working in an early years setting" do
    let(:registration_store) { { "works_in_childcare" => "yes" } }

    it { is_expected.to redirect_to registration_wizard_show_path("choose-childcare-provider") }
  end
end
