require "rails_helper"

RSpec.feature "Cookies", type: :feature do
  include_context "Stub Teacher Auth Responses"

  scenario "view info about cookies" do
    visit "/"
    click_link("View cookies")

    expect(page).to have_text("Cookies are small files saved on your phone, tablet or computer when you visit a website.")
  end

  scenario "when rejecting cookies", :js do
    visit "/"
    expect(page).to have_text("We use some essential cookies to make this service work.")
    click_button("Reject additional cookies")

    expect(page).to have_text("You’ve rejected analytics cookies")
    click_button("Hide this message")

    expect(page).to have_no_text("You’ve rejected additional cookies")
  end

  scenario "when accepting cookies", :js do
    visit "/"

    expect(page).to have_text("We use some essential cookies to make this service work.")
    click_button("Accept additional cookies")

    expect(page).to have_text("You’ve accepted analytics cookies")
    click_button("Hide this message")

    expect(page).to have_no_text("You’ve accepted additional cookies")
  end
end
