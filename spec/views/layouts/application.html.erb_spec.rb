require "rails_helper"

RSpec.describe "layouts/application.html.erb", type: :view do
  subject { Capybara.string(render) }

  let(:service_name) { "Register for a National Professional Development (NPD) course" }
  let(:one_login_link_text) { "GOV.UK One Login" }
  let(:sign_out_link_text) { "Sign out" }

  let(:user) { nil }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "service navigation" do
    it { is_expected.to have_css(".govuk-service-navigation__container", text: service_name) }
  end

  describe "one login header" do
    context "when not logged in" do
      it { is_expected.not_to have_link(one_login_link_text) }
      it { is_expected.not_to have_button(sign_out_link_text) }
    end

    context "when logged in" do
      let(:user) { build(:user) }

      it { is_expected.to have_css(".one-login-header") }
      it { is_expected.to have_link(one_login_link_text) }
      it { is_expected.to have_button(sign_out_link_text) }
    end
  end
end
