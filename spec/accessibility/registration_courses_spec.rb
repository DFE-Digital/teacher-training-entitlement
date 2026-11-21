require "rails_helper"

RSpec.describe "Registration course selector accessibility", :axe, type: :feature do
  before do
    create(:course, name: "Course A")
    create(:course, name: "Course B")
    Flipper.enable(Feature::REGISTRATION_OPEN)
    Flipper.enable(Feature::REGISTRATION_DFE_WIZARD)
  end

  it "course selector is accessible" do
    visit registration_courses_path
    expect(page).to be_axe_clean
  end

  it "course selector with an error is accessible" do
    visit registration_courses_path
    click_button "Continue"
    expect(page).to be_axe_clean
  end
end
