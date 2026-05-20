require "rails_helper"

RSpec.feature "Listing and viewing applications", type: :feature do
  include Helpers::AdminLogin
  include Helpers::MailHelper

  RSpec::Matchers.define :have_application do |expected|
    match do |_actual|
      within("td:nth-child(1)") do
        expect(page).to have_text(expected.user.full_name)
      end
    end
  end

  let(:applications_per_page) { Pagy::DEFAULT[:limit] }
  let(:applications_in_order) { Application.order(created_at: :desc, id: :desc) }

  before do
    create_list(:application, applications_per_page + 1)
    create(:lead_provider, :with_courses)
    sign_in_as(create(:admin))
  end

  scenario "viewing the list of applications" do
    visit(admin_applications_path)

    expect(page).to have_css("h1", text: "Applications")

    applications_in_order.limit(applications_per_page).each do |application|
      expect(page).to have_text(application.user.full_name)
      expect(page).to have_text(application.employer_name_to_display)
      expect(page).to have_link("View", href: admin_application_path(application.id))
    end

    expect(page).to have_css(".govuk-pagination__item--current", text: 1)
  end

  scenario "navigating to the second page of applications" do
    visit(admin_applications_path)

    click_on("Next")

    expect(page).to have_css("table.govuk-table tbody tr", count: 1)
    expect(page).to have_css(".govuk-pagination__item--current", text: "2")
  end

  scenario "searching applications" do
    visit(admin_applications_path)

    fill_in "Find an application", with: applications_in_order[0].ecf_id
    click_on "Search"

    expect(page).to have_css("table.govuk-table tbody tr", count: 1)
    expect(page).to have_application(applications_in_order[0])
  end

  scenario "filtering applications by application status" do
    application = applications_in_order.last
    application.update_column(:status, Application::DEFERRED)

    visit(admin_applications_path)
    select "Deferred", from: "Application status"
    click_on "Search"

    expect(page).to have_select("Application status", selected: "Deferred")
    expect(page).to have_css("table.govuk-table tbody tr", count: 1)
    expect(page).to have_application(application)
  end

  scenario "filtering applications by Application status" do
    application = applications_in_order.last
    application.update! status: Application::ACCEPTED, funded_place: false

    visit(admin_applications_path)
    select "Accepted", from: "Application status"
    click_on "Search"

    expect(page).to have_select("Application status", selected: "Accepted")
    expect(page).to have_css("table.govuk-table tbody tr", count: 1)
    expect(page).to have_application(application)
  end

  scenario "filtering applications by year of application" do
    cohort = create(:cohort, start_year: 2022)
    course_cohort = create(:course_cohort, cohort:)
    application = applications_in_order.last
    application.update!(course_cohort:)

    visit(admin_applications_path)
    click_on "2022 to 2023"

    expect(page).to have_css("table.govuk-table tbody tr", count: 1)
    expect(page).to have_application(application)
  end

  scenario "filtering applications by work setting" do
    application = applications_in_order.last
    application.update!(work_setting: "a_school")

    visit(admin_applications_path)
    select "A school", from: "Work setting"
    click_on "Search"

    expect(page).to have_select("Work setting", selected: "A school")
    expect(page).to have_css("table.govuk-table tbody tr", count: 1)
    expect(page).to have_application(application)
  end

  scenario "simultaneously filtering and searching applications" do
    application = applications_in_order.last

    search_with_results = application.user.full_name
    approval_status_with_results = "Pending"
    search_without_results = "no-match"
    approval_status_without_results = "Accepted"

    visit(admin_applications_path)

    fill_in "Find an application", with: search_with_results
    select approval_status_without_results, from: "Application status"
    click_on "Search"
    expect(page).to have_text("No applications match the search and filters")

    fill_in "Find an application", with: search_without_results
    select approval_status_with_results, from: "Application status"
    click_on "Search"
    expect(page).to have_text("No applications match the search and filters")

    fill_in "Find an application", with: search_with_results
    select approval_status_with_results, from: "Application status"
    click_on "Search"
    expect(page).to have_css("table.govuk-table tbody tr", count: 1)
    expect(page).to have_application(application)
  end

  scenario "viewing application details" do
    visit(admin_applications_path)

    application = applications_in_order.first
    application.update!(
      eligible_for_funding: true,
      funded_place: true,
      status: Application::ACCEPTED,
      funding_eligiblity_status_code: 123,
    )

    within("tr", text: application.user.full_name) do
      click_link("View")
    end

    summary_lists = all(".govuk-summary-list")

    expect(page).to have_css(
      ".govuk-caption-m",
      text: "#{application.user.full_name}, #{application.course.name}, #{application.created_at.to_date.to_fs(:govuk_short)}",
    )
    expect(page).to have_css("h1", text: "Application details")
    expect(page).to have_css("h2", text: "Overview")

    within(summary_lists[0]) do |summary_list|
      expect(summary_list).to have_summary_item("Name", application.user.full_name)
      expect(summary_list).to have_summary_item("Application ID", application.ecf_id)
      expect(summary_list).to have_summary_item("Course", application.course.name)
      expect(summary_list).to have_summary_item("Course identifier", application.course.identifier)
      expect(summary_list).to have_summary_item("Provider", application.lead_provider.name)
      expect(summary_list).to have_summary_item("Application status", application.status.humanize)
      expect(summary_list).to have_summary_item("Created", application.created_at.to_fs(:govuk_short))
      expect(summary_list).to have_summary_item("Updated", application.updated_at.to_fs(:govuk_short))
    end

    expect(page).to have_css("h2", text: "Funding eligibility")

    within(summary_lists[1]) do |summary_list|
      expect(summary_list).to have_summary_item("Eligible for funding", "Yes")
      expect(summary_list).to have_summary_item("Funded place", "")
      expect(summary_list).to have_summary_item("Status code", application.funding_eligiblity_status_code.humanize)
      expect(summary_list).to have_summary_item("Schedule cohort", application.cohort.name)
      expect(summary_list).to have_summary_item("Schedule identifier", "-")
      expect(summary_list).to have_summary_item("Funding choice", application.funding_choice&.capitalize)
      expect(summary_list).to have_summary_item("Notes", "No notes")
    end

    expect(page).to have_css("h2", text: "Workplace")

    within(summary_lists[2]) do |summary_list|
      expect(summary_list).to have_summary_item("UK Provider Reference Number (UKPRN)", application.ukprn)
      expect(summary_list).to have_summary_item("Unique reference number (URN)", application.school_urn)
      expect(summary_list).to have_summary_item("Country", application.teacher_catchment_country)
    end
  end

  scenario "viewing participant details" do
    visit(admin_applications_path)

    user = applications_in_order.first.user

    expect(page).to have_text(user.full_name)
  end

  scenario "viewing user details" do
    application = create(:application, :accepted)

    visit admin_application_path(application)

    within(".govuk-summary-card", text: "Overview") do
      within(".govuk-summary-list__row", text: "Name") do
        expect(page).to have_text(application.user.full_name)
        click_link("View user")
      end
    end

    expect(page).to have_current_path(admin_user_path(application.user))
    expect(page).to have_css("h1", text: application.user.full_name)

    within(".govuk-summary-card", text: application.course.name) do
      click_link("View full application")
    end

    expect(page).to have_current_path(admin_application_path(application))

    within(first(".govuk-summary-list__row", text: "Name")) do
      expect(page).to have_text(application.user.full_name)
    end
  end

  scenario "revert to pending" do
    application = create(:application, :accepted)

    visit admin_application_path(application)

    expect(page).to have_css("h1", text: "Application details")

    within(".govuk-summary-list__row", text: "Application status") do |summary_list_row|
      expect(summary_list_row).to have_text "Accepted"
      click_link("Revert to Pending")
    end

    expect(page).to have_css("h1", text: "Are you sure you want to change the status to Pending?")
    click_button "Change status to Pending"

    expect(page).to have_css(".govuk-error-message", text: "Confirm you wish to change the status to Pending")
    choose "Yes", visible: :all
    click_button "Change status to Pending"

    expect(page).to have_css("h1", text: "Application details")
    within(".govuk-summary-list__row", text: "Application status") do |summary_list_row|
      expect(summary_list_row).to have_text "Pending"
      expect(summary_list_row).not_to have_link("Change")
    end
  end

  scenario "changing status" do
    lead_provider = create(:lead_provider)
    schedule = create(:schedule, training_starts_at: 1.day.ago, training_ends_at: 1.day.from_now)
    course_cohort = create(:course_cohort, lead_provider: lead_provider, schedule:)
    application = create(:application, :accepted, course_cohort:, lead_provider:)
    create(:declaration, application:, course: course_cohort.course, cohort: course_cohort.cohort, lead_provider:, declaration_type: "started", declaration_date: schedule.training_starts_at + 1.hour)

    visit admin_application_path(application)

    expect(page).to have_css("h1", text: "Application details")

    within(".govuk-summary-list__row", text: "Application status") do |summary_list|
      expect(summary_list).to have_text "Accepted"
      click_on "Defer/Withdraw"
    end

    expect(page).to have_css("h1", text: "Change status")
    choose "Deferred", visible: :all
    click_button "Continue"

    expect(page).to have_css(".govuk-error-message", text: "Choose a valid reason for the status change")
    select Admin::Applications::ChangeStatusForm::REASON_OPTIONS["deferred"].first
    click_button "Continue"

    expect(page).to have_css("h1", text: "Application details")
    within(".govuk-summary-list__row", text: "status") do |summary_list|
      expect(summary_list).to have_text "Deferred"
      click_on "Accept"
    end

    expect(page).to have_css("h1", text: "Change status")
    choose "Accepted", visible: :all
    click_button "Continue"

    expect(page).to have_css("h1", text: "Application details")
    within(".govuk-summary-list__row", text: "status") do |summary_list|
      expect(summary_list).to have_text "Started"
    end
  end

  scenario "changing eligibility for funding" do
    application = create(:application, :accepted)

    visit admin_application_path(application)

    expect(page).to have_css("h1", text: "Application details")
    within(".govuk-summary-list__row", text: "Eligible for funding") do |summary_list_row|
      expect(summary_list_row).to have_text "No"
      click_link("Change")
    end

    expect(page).to have_css("h1", text: "Is #{application.user.full_name} eligible for funding?")
    expect(page.find_field("No", visible: :all)).to be_checked
    choose "Yes", visible: :all

    perform_enqueued_jobs { click_button "Continue" }

    expect_mail_to_have_been_sent(to: application.user.email, template_id: GenericMailer::TEMPLATE_ID)

    expect(page).to have_css("h1", text: "Application details")
    expect(page).to have_content("Funding eligibility has been changed to ‘Yes’")
    within(".govuk-summary-list__row", text: "Eligible for funding") do |summary_list_row|
      expect(summary_list_row).to have_text "Yes"
      click_link("Change")
    end

    expect(page).to have_css("h1", text: application.user.full_name)
    choose "No", visible: :all
    click_button "Continue"

    expect(page).to have_css("h1", text: "Application details")
    within(".govuk-summary-list__row", text: "Eligible for funding") do |summary_list_row|
      expect(summary_list_row).to have_text "No"
    end
  end

  scenario "changing schedule cohort" do
    future_cohort = create(:cohort, start_year: 3.years.from_now.year)
    course_cohort = create(:course_cohort, cohort: Cohort.first)
    create(:course_cohort, course: course_cohort.course, cohort: future_cohort)
    create(:cohort, start_year: 2.years.from_now.year)
    application = create(:application, course_cohort:)

    visit admin_application_path(application)

    within(".govuk-summary-list__row", text: "Schedule cohort") do
      click_link("Change")
    end

    expect(page).to have_css("h1", text: "Choose a cohort")

    click_button "Continue"
    expect(page).to have_css(".govuk-error-message", text: "Choose a cohort")

    choose future_cohort.start_year.to_s, visible: :all
    click_button "Continue"

    within(".govuk-summary-list__row", text: "Schedule cohort") do |row|
      expect(row).to have_text(future_cohort.start_year.to_s)
    end
  end

  scenario "adding and editing notes" do
    visit(admin_applications_path)

    application = applications_in_order.first

    within("tr", text: application.user.full_name) do
      click_link("View")
    end

    within(".govuk-summary-list__row", text: "Notes") do
      click_on "Add note"
    end

    # check cancel
    click_on "Cancel"
    expect(page).to have_current_path(admin_application_path(application))

    # change for real
    within(".govuk-summary-list__row", text: "Notes") do
      click_on "Add note"
    end

    fill_in "Add a note about the changes to this registration", with: "Some notes"
    click_on "Add note"

    expect(page).to have_current_path(admin_application_path(application))
    within(".govuk-summary-list__row", text: "Notes") do
      expect(page).to have_text("Some notes")
    end

    within(".govuk-summary-list__row", text: "Notes") do
      click_on "Edit note"
    end
    fill_in "Edit the note about the changes to this registration", with: "Different notes"
    click_on "Edit note"

    expect(page).to have_current_path(admin_application_path(application))
    within(".govuk-summary-list__row", text: "Notes") do
      expect(page).to have_text("Different notes")
    end

    # check going straight to the note edit page
    visit(edit_admin_applications_notes_path(application))
    click_on "Cancel"
    expect(page).to have_current_path(admin_application_path(application))
  end
end
