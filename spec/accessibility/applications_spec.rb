require "rails_helper"

RSpec.describe "Applications accessibility", :axe, type: :feature do
  let(:teacher) { create(:teacher, :with_one_login_id) }
  let(:application) { create(:application, teacher:) }

  before do
    page.set_rack_session("teacher_id" => teacher.id)
  end

  it "application show page is accessible" do
    visit application_path(application.ecf_id)
    expect(page).to be_axe_clean
  end
end
