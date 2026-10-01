require "rails_helper"

RSpec.feature "Admin search", type: :feature do
  include Helpers::AdminLogin

  RSpec::Matchers.define :have_application do |expected|
    match do |_actual|
      within(find("tr", text: expected.user.full_name)) do
        expect(page).to have_text(expected.user.full_name)
        expect(page).to have_link("View", href: admin_application_path(expected))
      end
    end
  end

  before do
    sign_in_as(create(:admin))
  end

  scenario "searching applications" do
    application = create(:application)

    visit(admin_search_path)

    fill_in "Name, email, TRN, user ID, application ID, declaration ID or URN", with: application.ecf_id
    click_button "Search"

    expect(page).to have_css("table.govuk-table tbody tr", count: 1)
    expect(page).to have_application(application)
  end

  scenario "filtering applications by application status" do
    create(:application, :pending)
    application = create(:application, :deferred)

    visit(admin_search_path)
    select "Deferred", from: "Application status"
    click_button "Search"

    expect(page).to have_select("Application status", selected: "Deferred")
    expect(page).to have_css("table.govuk-table tbody tr", count: 1)
    expect(page).to have_application(application)
  end

  scenario "filtering applications by accepted application status" do
    create(:application, :pending)
    application = create(:application, :accepted, funded_place: false)

    visit(admin_search_path)
    select "Accepted", from: "Application status"
    click_button "Search"

    expect(page).to have_select("Application status", selected: "Accepted")
    expect(page).to have_css("table.govuk-table tbody tr", count: 1)
    expect(page).to have_application(application)
  end

  scenario "simultaneously filtering and searching applications" do
    application = create(:application, :pending)

    search_with_results = application.ecf_id
    approval_status_with_results = "Pending"
    search_without_results = "no-match"
    approval_status_without_results = "Accepted"

    visit(admin_search_path)

    fill_in "Name, email, TRN, user ID, application ID, declaration ID or URN", with: search_with_results
    select approval_status_without_results, from: "Application status"
    click_button "Search"
    expect(page).to have_text("No applications match the search and filters")

    fill_in "Name, email, TRN, user ID, application ID, declaration ID or URN", with: search_without_results
    select approval_status_with_results, from: "Application status"
    click_button "Search"
    expect(page).to have_text("No users or applications match the search and filters")

    fill_in "Name, email, TRN, user ID, application ID, declaration ID or URN", with: search_with_results
    select approval_status_with_results, from: "Application status"
    click_button "Search"
    expect(page).to have_css("table.govuk-table tbody tr", count: 1)
    expect(page).to have_application(application)
  end

  scenario "searching for a user" do
    user = create(:user, :with_one_login_id)
    create(:application, user:)

    visit(admin_search_path)

    fill_in("Name, email, TRN, user ID, application ID, declaration ID or URN", with: user.email)
    click_button("Search")
    click_on("Users (1)")

    expect(page).to have_css("tbody tr", count: 1)
    expect(page).to have_css("tbody tr", text: user.full_name)
    expect(page).to have_link(user.full_name, href: admin_user_path(user))
  end
end
