require "rails_helper"

RSpec.feature "Listing statements", type: :feature do
  include Helpers::AdminLogin

  let(:statements_per_page) { Pagy::DEFAULT[:limit] }

  before do
    (statements_per_page + 1).times do |index|
      create(:statement, start_date: index.days.ago.to_date)
    end

    sign_in_as(create(:admin))
  end

  scenario "viewing the list of statements" do
    visit(admin_finance_statements_path)

    expect(page).to have_css("h1", text: "Finance")

    Statement.order(start_date: :desc).limit(statements_per_page).each do |statement|
      expect(page).to have_link("View", href: admin_finance_statement_path(statement))
    end

    expect(page).to have_css(".govuk-pagination__item--current", text: 1)
  end

  scenario "navigating to the second page of statements" do
    visit(admin_finance_statements_path)

    click_on("Next")

    expect(page).to have_css("table.govuk-table tbody tr", count: 1)
    expect(page).to have_css(".govuk-pagination__item--current", text: "2")
  end
end
