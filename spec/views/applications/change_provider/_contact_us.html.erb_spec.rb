require "rails_helper"

RSpec.describe "app/views/applications/change_provider/_contact_us.html.erb", type: :view do
  subject(:rendered_page) do
    render partial: "applications/change_provider/contact_us"
    Capybara.string(rendered)
  end

  let(:application) { build_stubbed(:application, :accepted) }

  before do
    current_application = application
    view.define_singleton_method(:application) { current_application }
  end

  it "renders the contact us instructions" do
    expect(rendered_page).to have_css("h2", text: I18n.t("applications.change_provider.contact_us.instructions.title"))
  end
end
