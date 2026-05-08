require "rails_helper"

RSpec.describe "applications/change_provider/start/index.html.erb", type: :view do
  subject(:rendered_page) { Capybara.string(render) }

  let(:application) { build_stubbed(:application, application_status) }
  let(:application_status) { :pending }

  before do
    assign(:form, Applications::ChangeProvider::StartForm.new(application:))
    current_application = application
    view.define_singleton_method(:application) { current_application }
  end

  context "when the application has not been pending" do
    let(:application_status) { :pending }

    it "renders the change provider form" do
      expect(rendered_page).to have_css("form")
      expect(rendered_page).to have_css("h2", text: I18n.t("applications.change_provider.start.what_happens.title"))
      expect(rendered_page).to have_css("label", text: I18n.t("applications.change_provider.start.application_pending.form.yes_option"))
      expect(rendered_page).to have_css("label", text: I18n.t("applications.change_provider.start.application_pending.form.no_option"))
    end
  end

  context "when the application has not been rejected" do
    let(:application_status) { :rejected }

    it "renders the change provider form" do
      expect(rendered_page).to have_css("form")
      expect(rendered_page).to have_css("h2", text: I18n.t("applications.change_provider.start.what_happens.title"))
      expect(rendered_page).to have_css("label", text: I18n.t("applications.change_provider.start.application_rejected.form.yes_option"))
      expect(rendered_page).to have_css("label", text: I18n.t("applications.change_provider.start.application_rejected.form.no_option"))
    end
  end
end
