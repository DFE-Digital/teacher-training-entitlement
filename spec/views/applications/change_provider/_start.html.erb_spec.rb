require "rails_helper"

RSpec.describe "app/views/applications/change_provider/_start.html.erb", type: :view do
  subject(:rendered_page) do
    render partial: "applications/change_provider/start"
    Capybara.string(rendered)
  end

  let(:application) { build_stubbed(:application, application_status) }
  let(:application_status) { :pending }
  let(:current_step_name) { :start }
  let(:current_step_path) { "/the/path" }
  let(:current_step) { ChangeProvider::Forms::StartForm.new }
  let(:wizard) { instance_double(ChangeProvider::FormWizard, current_step:, current_step_path:) }

  before do
    assign(:wizard, wizard)
    current_application = application
    current_step_for_view = current_step
    current_step_name_for_view = current_step_name

    view.define_singleton_method(:application) { current_application }
    view.define_singleton_method(:current_step) { current_step_for_view }
    view.define_singleton_method(:current_step_name) { current_step_name_for_view }
  end

  context "when the application is pending" do
    let(:application_status) { :pending }

    it "renders the change provider form" do
      expect(rendered_page).to have_css("form")
      expect(rendered_page).to have_css("h2", text: I18n.t("applications.change_provider.start.what_happens.title"))
      expect(rendered_page).to have_css("label", text: I18n.t("applications.change_provider.start.application_pending.form.yes_option"))
      expect(rendered_page).to have_css("label", text: I18n.t("applications.change_provider.start.application_pending.form.no_option"))
    end
  end

  context "when the application is rejected" do
    let(:application_status) { :rejected }

    it "renders the change provider form" do
      expect(rendered_page).to have_css("form")
      expect(rendered_page).to have_css("h2", text: I18n.t("applications.change_provider.start.what_happens.title"))
      expect(rendered_page).to have_css("label", text: I18n.t("applications.change_provider.start.application_rejected.form.yes_option"))
      expect(rendered_page).to have_css("label", text: I18n.t("applications.change_provider.start.application_rejected.form.no_option"))
    end
  end
end
