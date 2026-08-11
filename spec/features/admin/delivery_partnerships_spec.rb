require "rails_helper"

RSpec.feature "NPQ Separation Admin Delivery Partnerships", type: :feature do
  include Helpers::AdminLogin

  let(:admin) { create(:admin) }
  let!(:delivery_partner) { create(:delivery_partner) }
  let!(:lead_providers) { create_list(:lead_provider, 3) }
  let!(:cohorts) { [create(:cohort, :current), create(:cohort, :next)] }
  let!(:course_cohorts) { cohorts.map { |cohort| create(:course_cohort, cohort:) } }

  context "when not logged in" do
    scenario "delivery partnerships interface is inaccessible" do
      visit edit_admin_delivery_partner_delivery_partnerships_path(delivery_partner)
      expect(page).to have_current_path(sign_in_path)
    end
  end

  context "when logged in as admin" do
    before { sign_in_as_admin }

    scenario "viewing the edit page for a delivery partner's partnerships" do
      visit admin_delivery_partners_path
      click_link "Assign to provider", match: :first

      expect(page).to have_current_path(edit_admin_delivery_partner_delivery_partnerships_path(delivery_partner))

      within "main" do
        expect(page).to have_content("Assign #{delivery_partner.name} to provider")

        # All course providers are displayed
        lead_providers.each do |lead_provider|
          expect(page).to have_content(lead_provider.name)
        end

        # Course cohorts are hidden until a course provider is selected
        expect(page).not_to have_content(course_cohort_label(course_cohorts.first))
      end
    end

    scenario "assigning course providers and cohorts to a delivery partner" do
      lead_provider = lead_providers.first
      course_cohort = course_cohorts.first

      visit edit_admin_delivery_partner_delivery_partnerships_path(delivery_partner)

      # Check the course provider checkbox
      check lead_provider.name, visible: :all

      # Check the cohort checkbox for this course provider
      within("#delivery-partner-lead-provider-id-#{lead_provider.id}-conditional") do
        check course_cohort_label(course_cohort), visible: :all
      end

      click_button "Save"

      expect(page).to have_current_path(admin_delivery_partners_path)
      expect(page).to have_content("Delivery partner updated")
      expect(DeliveryPartnership.where(delivery_partner:, lead_provider:, course_cohort:)).to exist
    end

    scenario "removing a course provider partnership" do
      # Create an existing partnership
      lead_provider = lead_providers.first
      course_cohort = course_cohorts.first

      delivery_partnership = create(:delivery_partnership,
                                    delivery_partner:,
                                    lead_provider:,
                                    course_cohort:)

      visit edit_admin_delivery_partner_delivery_partnerships_path(delivery_partner)

      # The course provider should be checked
      expect(page).to have_field("delivery_partner[lead_provider_id][]", with: lead_provider.id.to_s, checked: true, visible: :all)

      # The cohort should be checked
      within("#delivery-partner-lead-provider-id-#{lead_provider.id}-conditional") do
        expect(page).to have_field(course_cohort_label(course_cohort), checked: true, visible: :all)
      end

      # Uncheck the course provider (this should also uncheck all cohorts via JS)
      uncheck lead_provider.name, visible: :all

      click_button "Save"

      expect(page).to have_current_path(admin_delivery_partners_path)
      expect(page).to have_content("Delivery partner updated")
      expect(DeliveryPartnership.find_by(id: delivery_partnership.id)).to be_nil
    end

    scenario "assigning two course cohorts in the same cohort" do
      lead_provider = lead_providers.first
      cohort = cohorts.first
      first_course_cohort = course_cohorts.first
      second_course_cohort = create(:course_cohort, cohort:, course: create(:course))

      create(:delivery_partnership,
             delivery_partner:,
             lead_provider:,
             cohort:,
             course_cohort: first_course_cohort)

      visit edit_admin_delivery_partner_delivery_partnerships_path(delivery_partner)

      within("#delivery-partner-lead-provider-id-#{lead_provider.id}-conditional") do
        check course_cohort_label(second_course_cohort), visible: :all
      end

      click_button "Save"

      expect(page).to have_current_path(admin_delivery_partners_path)
      expect(delivery_partner.course_cohorts.reload).to contain_exactly(first_course_cohort, second_course_cohort)
      expect(delivery_partner.delivery_partnerships.find_by(course_cohort: second_course_cohort).cohort_id).to be_nil
    end

    scenario "assigning a course cohort when another delivery partner has a similar name" do
      delivery_partner.update!(name: "Delivery partner 1")
      create(:delivery_partner, name: "Delivery partner 2")
      lead_provider = lead_providers.first
      course_cohort = course_cohorts.first

      visit edit_admin_delivery_partner_delivery_partnerships_path(delivery_partner)

      check lead_provider.name, visible: :all
      within("#delivery-partner-lead-provider-id-#{lead_provider.id}-conditional") do
        check course_cohort_label(course_cohort), visible: :all
      end

      click_button "Save"

      expect(page).to have_current_path(admin_delivery_partners_path)
      expect(page).not_to have_content("We found similar delivery partners")
      expect(DeliveryPartnership.where(delivery_partner:, lead_provider:, course_cohort:)).to exist
    end

    scenario "removing a specific cohort from a course provider partnership" do
      # Create existing partnerships for two cohorts
      lead_provider = lead_providers.first
      course_cohort1 = course_cohorts.first
      course_cohort2 = course_cohorts.second

      partnership1 = create(:delivery_partnership,
                            delivery_partner: delivery_partner,
                            lead_provider: lead_provider,
                            course_cohort: course_cohort1)

      partnership2 = create(:delivery_partnership,
                            delivery_partner: delivery_partner,
                            lead_provider: lead_provider,
                            course_cohort: course_cohort2)

      visit edit_admin_delivery_partner_delivery_partnerships_path(delivery_partner)

      # The course provider should be checked
      expect(page).to have_field("delivery_partner[lead_provider_id][]", with: lead_provider.id.to_s, checked: true, visible: :all)

      # Both cohorts should be checked
      within("#delivery-partner-lead-provider-id-#{lead_provider.id}-conditional") do
        expect(page).to have_field(course_cohort_label(course_cohort1), checked: true, visible: :all)
        expect(page).to have_field(course_cohort_label(course_cohort2), checked: true, visible: :all)

        # Uncheck just the first cohort
        uncheck course_cohort_label(course_cohort1), visible: :all
      end

      click_button "Save"

      expect(page).to have_current_path(admin_delivery_partners_path)
      expect(page).to have_content("Delivery partner updated")
      expect(DeliveryPartnership.find_by(id: partnership1.id)).to be_nil
      expect(DeliveryPartnership.find_by(id: partnership2.id)).to be_present
    end

    scenario "cancel button redirects back to delivery partners index page" do
      visit edit_admin_delivery_partner_delivery_partnerships_path(delivery_partner)

      click_link "Cancel"
      expect(page).to have_current_path(admin_delivery_partners_path)
    end
  end

private

  def course_cohort_label(course_cohort)
    "#{course_cohort.course.name} – #{course_cohort.cohort.description}"
  end
end
