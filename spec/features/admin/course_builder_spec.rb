require "rails_helper"

RSpec.feature "Building a course", type: :feature do
  include Helpers::AdminLogin

  let!(:lead_provider) { create(:lead_provider, name: "A Lead Provider") }
  let!(:other_lead_provider) { create(:lead_provider, name: "B Lead Provider") }
  let!(:delivery_partner) { create(:delivery_partner, name: "A Delivery Partner") }
  let(:super_admin) { create(:super_admin) }

  before { sign_in_as_super_admin }

  def delivery_partner_checkbox(lead_provider, delivery_partner)
    find(
      "input[type='checkbox'][name='delivery_partners[delivery_partners][#{lead_provider.id}][#{delivery_partner.id}]']",
      visible: false,
    )
  end

  def lead_provider_group(lead_provider)
    find("fieldset", text: "Delivery partners for #{lead_provider.name}")
  end

  scenario "creating a course with the default milestones and minimal provider data" do
    visit admin_settings_courses_builder_path(step: "course-details")

    fill_in "Name", with: "Minimal course"
    select "Reception", from: "Course group"
    click_on "Continue"

    fill_in "milestones-started-payment-percentage-field", with: "60"
    fill_in "milestones-completed-payment-percentage-field", with: "40"
    click_on "Continue"

    find("label", text: lead_provider.name).click
    click_on "Continue"

    click_on "Continue"

    expect(page).to have_css("h1", text: "Delivery partners")

    within(lead_provider_group(lead_provider)) do
      find("label", text: delivery_partner.name).click
    end
    click_on "Continue"

    expect(page).to have_css("h1", text: "Check course configuration")
    expect(page).to have_text("Started and Completed")
    expect(page).to have_text(lead_provider.name)
    expect(page).to have_text("Delivery partners")
    expect(page).to have_text(delivery_partner.name)

    click_button "Create course"

    course = Course.find_by!(name: "Minimal course")
    expect(course.milestones.pluck(:declaration_type, :payment_percentage)).to contain_exactly(
      [Milestone::STARTED, BigDecimal("0.6")],
      [Milestone::COMPLETED, BigDecimal("0.4")],
    )
    expect(course.delivery_partnerships.pluck(:delivery_partner_id)).to contain_exactly(delivery_partner.id)
    expect(page).to have_current_path(admin_settings_courses_path)
    expect(page).to have_text("Course created successfully")

    visit admin_settings_course_path(course)
    expect(page).to have_css("h2", text: "Delivery partners")
    expect(page).to have_text(lead_provider.name)
    expect(page).to have_text(delivery_partner.name)
  end

  scenario "showing a delivery partners check answer row with a change link that keeps the ticks" do
    visit admin_settings_courses_builder_path(step: "course-details")

    fill_in "Name", with: "Change link course"
    select "Reception", from: "Course group"
    click_on "Continue"

    fill_in "milestones-started-payment-percentage-field", with: "60"
    fill_in "milestones-completed-payment-percentage-field", with: "40"
    click_on "Continue"

    find("label", text: lead_provider.name).click
    click_on "Continue"
    click_on "Continue"

    within(lead_provider_group(lead_provider)) do
      find("label", text: delivery_partner.name).click
    end
    click_on "Continue"

    within(find("tr", text: "Delivery partners")) do
      click_on "Change"
    end

    expect(page).to have_css("h1", text: "Delivery partners")
    expect(delivery_partner_checkbox(lead_provider, delivery_partner).checked?).to be true
  end

  scenario "validating that every selected lead provider has a delivery partner" do
    visit admin_settings_courses_builder_path(step: "course-details")

    fill_in "Name", with: "Validation course"
    select "Reception", from: "Course group"
    click_on "Continue"

    fill_in "milestones-started-payment-percentage-field", with: "60"
    fill_in "milestones-completed-payment-percentage-field", with: "40"
    click_on "Continue"

    find("label", text: lead_provider.name).click
    find("label", text: other_lead_provider.name).click
    click_on "Continue"
    click_on "Continue"

    within(lead_provider_group(lead_provider)) do
      find("label", text: delivery_partner.name).click
    end
    click_on "Continue"

    expect(page).to have_css("h1", text: "Delivery partners")
    expect(page).to have_css(".govuk-error-summary")

    error_link = find(".govuk-error-summary a", text: "Select at least one delivery partner for B Lead Provider")
    expect(error_link[:href]).to end_with("#delivery-partners-lead-provider-#{other_lead_provider.id}-field-error")
    expect(page).to have_css("#delivery-partners-lead-provider-#{other_lead_provider.id}-field-error", visible: :all)

    within(lead_provider_group(other_lead_provider)) do
      expect(page).to have_text("Select at least one delivery partner for B Lead Provider")
    end
    expect(delivery_partner_checkbox(lead_provider, delivery_partner).checked?).to be true
  end

  scenario "blocking check answers when a lead provider is added without a delivery partner" do
    visit admin_settings_courses_builder_path(step: "course-details")

    fill_in "Name", with: "Added lead course"
    select "Reception", from: "Course group"
    click_on "Continue"

    fill_in "milestones-started-payment-percentage-field", with: "60"
    fill_in "milestones-completed-payment-percentage-field", with: "40"
    click_on "Continue"

    find("label", text: lead_provider.name).click
    click_on "Continue"
    click_on "Continue"

    within(lead_provider_group(lead_provider)) do
      find("label", text: delivery_partner.name).click
    end
    click_on "Continue"

    expect(page).to have_css("h1", text: "Check course configuration")

    within(find("tr", text: "Lead providers")) do
      click_on "Change"
    end
    find("label", text: other_lead_provider.name).click
    click_on "Continue"
    click_on "Continue"

    expect(page).to have_css("h1", text: "Delivery partners")
    click_on "Continue"

    expect(page).to have_css("h1", text: "Delivery partners")
    expect(page).to have_css(".govuk-error-summary")
    within(lead_provider_group(other_lead_provider)) do
      expect(page).to have_text("Select at least one delivery partner for B Lead Provider")
    end

    within(lead_provider_group(other_lead_provider)) do
      find("label", text: delivery_partner.name).click
    end
    click_on "Continue"

    expect(page).to have_css("h1", text: "Check course configuration")
  end

  scenario "continuing past delivery partners when no lead providers were selected" do
    visit admin_settings_courses_builder_path(step: "course-details")

    fill_in "Name", with: "No providers course"
    select "Reception", from: "Course group"
    click_on "Continue"

    fill_in "milestones-started-payment-percentage-field", with: "60"
    fill_in "milestones-completed-payment-percentage-field", with: "40"
    click_on "Continue"

    click_on "Continue"
    click_on "Continue"

    expect(page).to have_css("h1", text: "Delivery partners")
    expect(page).to have_text("No lead providers were selected.")

    click_on "Continue"

    expect(page).to have_css("h1", text: "Check course configuration")
    expect(page).to have_text("Delivery partners")
    expect(page).to have_text("None selected")
  end

  scenario "not saving partners for a lead provider that was removed" do
    visit admin_settings_courses_builder_path(step: "course-details")

    fill_in "Name", with: "Removed lead course"
    select "Reception", from: "Course group"
    click_on "Continue"

    fill_in "milestones-started-payment-percentage-field", with: "60"
    fill_in "milestones-completed-payment-percentage-field", with: "40"
    click_on "Continue"

    find("label", text: lead_provider.name).click
    click_on "Continue"
    click_on "Continue"

    within(lead_provider_group(lead_provider)) do
      find("label", text: delivery_partner.name).click
    end
    click_on "Continue"

    within(find("tr", text: "Lead providers")) do
      click_on "Change"
    end

    find("label", text: lead_provider.name).click
    click_on "Continue"
    click_on "Continue"

    expect(page).to have_text("No lead providers were selected.")
    click_on "Continue"

    expect(page).to have_css("h1", text: "Check course configuration")
    expect(page).not_to have_text(delivery_partner.name)

    click_button "Create course"

    expect(page).to have_text("Course created successfully")
    course = Course.find_by!(name: "Removed lead course")
    expect(course.delivery_partnerships).to be_empty
  end
end
