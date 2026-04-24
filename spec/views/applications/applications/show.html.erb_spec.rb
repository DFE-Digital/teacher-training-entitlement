require "rails_helper"

RSpec.describe "applications/applications/show.html.erb", type: :view do
  let(:application) { build_stubbed(:application) }

  subject { Capybara.string(render) }

  before do
    assign(:application, application)
    allow(view).to receive(:current_user).and_return(build_stubbed(:user))
  end

  context "when application is pending" do
    let(:application) { build_stubbed(:application, :pending) }

    it { is_expected.to have_link "Register with a different provider", href: application_change_provider_start_index_path(application.ecf_id) }
  end

  context "when application is accepted" do
    let(:application) { build_stubbed(:application, :accepted) }

    it { is_expected.to have_link "Register with a different provider", href: application_change_provider_start_index_path(application.ecf_id) }
  end

  context "when application is started" do
    let(:application) { build_stubbed(:application, :started) }

    it { is_expected.not_to have_link "Register with a different provider" }
  end
end
