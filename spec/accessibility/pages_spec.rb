require "rails_helper"

RSpec.describe "Pages accessibility", :axe, type: :feature do
  it "start page is accessible" do
    visit root_path
    expect(page).to be_axe_clean
  end

  it "sign in page is accessible" do
    visit "/sign-in"
    expect(page).to be_axe_clean
  end

  it "cookies page is accessible" do
    visit cookies_path
    expect(page).to be_axe_clean
  end

  it "accessibility statement is accessible" do
    visit accessibility_statement_path
    expect(page).to be_axe_clean
  end

  it "closed registration exception page is accessible" do
    visit closed_registration_exception_path
    expect(page).to be_axe_clean
  end
end
