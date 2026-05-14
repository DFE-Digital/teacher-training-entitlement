require "rails_helper"

RSpec.describe "applications/applications/show.html.erb", type: :view do
  let(:application) { build_stubbed(:application) }
  let(:lead_provider) { build_stubbed(:lead_provider) }

  subject { Capybara.string(render) }

  before do
    current_application = application
    view.define_singleton_method(:application) { current_application }
    allow(application).to receive(:lead_provider).and_return(lead_provider)
    allow(view).to receive(:current_user).and_return(build_stubbed(:user))
  end

  context "when application is pending" do
    let(:application) { build_stubbed(:application, :pending) }

    it { is_expected.to have_link "Register with a different provider", href: application_change_provider_path(application.ecf_id, :start) }
  end

  context "when application is accepted" do
    let(:application) { build_stubbed(:application, :accepted) }

    it { is_expected.to have_link "Register with a different provider", href: application_change_provider_path(application.ecf_id, "contact-us") }
  end

  context "when application is started" do
    let(:application) { build_stubbed(:application, :started) }

    it { is_expected.not_to have_link "Register with a different provider" }
  end
end
