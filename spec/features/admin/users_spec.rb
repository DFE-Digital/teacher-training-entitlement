require "rails_helper"

RSpec.feature "User administration", type: :feature do
  include Helpers::AdminLogin

  let(:users_per_page) { Pagy::DEFAULT[:limit] }
  let(:user) { User.first }

  before do
    create_list(:user, users_per_page, :with_one_login_id)
    user.update!(national_insurance_number: "QQ123456C", preferred_name: "Jonny D")
    sign_in_as(create(:admin))
  end

  feature "listing users" do
    scenario "viewing the list of users" do
      visit(admin_users_path)

      expect(page).to have_css("h1", text: "Users")

      User.all.find_each do |user|
        expect(page).to have_link(user.full_name, href: admin_user_path(user))
        expect(page).to have_css("td", text: user.trn)
        expect(page).to have_css("td", text: user.created_at.to_date.to_formatted_s(:govuk))
      end
    end

    scenario "navigating to the second page of users" do
      create :user, :with_one_login_id # exceed pagination threshold

      visit(admin_users_path)

      click_on("Next")

      expect(page).to have_css("table.govuk-table tbody tr", count: 1)
      expect(page).to have_css(".govuk-pagination__item--current", text: "2")
    end

    scenario "searching for a user" do
      visit(admin_users_path)

      fill_in("Find a user", with: user.email)
      click_on("Search")

      expect(page).to have_css("tbody tr", count: 1)
      expect(page).to have_css("tbody tr", text: user.full_name)
    end
  end

  feature "viewing a user" do
    scenario "shows user details" do
      visit admin_user_path(user)

      expect(page).to have_css("h1", text: user.full_name)

      within(".govuk-summary-card", text: "Overview") do |summary_card|
        expect(summary_card).to have_summary_item("User ID", user.ecf_id)
        expect(summary_card).to have_summary_item("Preferred Name", user.preferred_name)
        expect(summary_card).to have_summary_item("Email", user.email)
        expect(summary_card).to have_summary_item("Date of birth", user.date_of_birth.to_fs(:govuk_short))
        expect(summary_card).to have_summary_item("National Insurance number", user.national_insurance_number)
        expect(summary_card).to have_summary_item("TRN", user.trn, "Not verified")
        expect(summary_card).to have_summary_item("One Login ID", user.one_login_id)
      end
    end

    scenario "renders when attributes with method chains are nil" do
      user.update!(date_of_birth: nil)
      visit admin_user_path(user)

      expect(page).to have_content("Date of birth")
    end

    scenario "shows a message if the user has no applications" do
      visit admin_user_path(user)

      expect(page).to have_css("h1", text: user.full_name)
      expect(page).to have_css(".govuk-body", text: "This user has no applications.")
    end

    scenario "shows a summary of each user application" do
      applications = %i[tte_early_years]
        .map { create(:application, user:, course: create(:course, _1)) }
        .sort_by { [_1.created_at, _1.id] }

      applications.each do |a|
        create(:declaration, :completed, :paid, application: a)
      end
      visit admin_user_path(user)

      expect(page).to have_css("h1", text: user.full_name)
      expect(page).to have_css("h2", text: "Applications", count: 1)
      applications.each do |application|
        within(".govuk-summary-card", text: application.course.name.to_s) do |summary_card|
          expect(summary_card).to have_summary_item("Course", application.course.name)
          expect(summary_card).to have_summary_item("Provider", application.lead_provider.name)
          expect(summary_card).to have_summary_item("Eligible for funding", "No")
          expect(summary_card).to have_summary_item("Application status", "Pending")
          expect(summary_card).to have_summary_item("Funded place", "No")
          expect(summary_card).to have_summary_item("Training milestone reached", "Completed (paid)")
          expect(summary_card).to have_summary_item("Registration submission date", application.created_at.to_fs(:govuk_short))
        end
      end
    end

  end
end
