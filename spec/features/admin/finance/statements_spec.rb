require "rails_helper"

RSpec.feature "Listing statements", type: :feature do
  include Helpers::AdminLogin

  let(:statements_per_page) { Pagy::DEFAULT[:limit] }
  let!(:statements) do
    Array.new(statements_per_page + 1) do |index|
      create(:statement, start_date: (statements_per_page - index).months.from_now.to_date.beginning_of_month)
    end
  end

  before do
    sign_in_as(create(:admin))
  end

  scenario "viewing the list of statements" do
    visit(admin_finance_statements_path)

    expect(page).to have_css("h1", text: "Finance")

    statements.sort_by(&:start_date).reverse.first(statements_per_page).each do |statement|
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
