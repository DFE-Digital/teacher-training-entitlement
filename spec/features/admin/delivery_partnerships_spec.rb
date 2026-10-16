require "rails_helper"

RSpec.feature "NPQ Separation Admin Delivery Partnerships", type: :feature do
  include Helpers::AdminLogin

  let(:admin) { create(:admin) }
  let!(:delivery_partner) { create(:delivery_partner) }
  let!(:lead_providers) { create_list(:lead_provider, 3) }
  let!(:courses) { create_list(:course, 2) }

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

        # Courses are hidden until a course provider is selected
        expect(page).not_to have_content(courses.first.name)
      end
    end

    scenario "assigning course providers and courses to a delivery partner" do
      lead_provider = lead_providers.first
      course = courses.first

      visit edit_admin_delivery_partner_delivery_partnerships_path(delivery_partner)

      # Check the course provider checkbox
      check lead_provider.name, visible: :all

      # Check the course checkbox for this course provider
      within("#delivery-partner-lead-provider-id-#{lead_provider.id}-conditional") do
        check course.name, visible: :all
      end

      click_button "Save"

      expect(page).to have_current_path(admin_delivery_partners_path)
      expect(page).to have_content("Delivery partner updated")
      expect(DeliveryPartnership.where(delivery_partner:, lead_provider:, course:)).to exist
    end

    scenario "removing a course provider partnership" do
      # Create an existing partnership
      lead_provider = lead_providers.first
      course = courses.first

      delivery_partnership = create(:delivery_partnership,
                                    delivery_partner:,
                                    lead_provider:,
                                    course:)

      visit edit_admin_delivery_partner_delivery_partnerships_path(delivery_partner)

      # The course provider should be checked
      expect(page).to have_field("delivery_partner[lead_provider_id][]", with: lead_provider.id.to_s, checked: true, visible: :all)

      # The course should be checked
      within("#delivery-partner-lead-provider-id-#{lead_provider.id}-conditional") do
        expect(page).to have_field(course.name, checked: true, visible: :all)
      end

      # Uncheck the course provider (this should also uncheck all courses via JS)
      uncheck lead_provider.name, visible: :all

      click_button "Save"

      expect(page).to have_current_path(admin_delivery_partners_path)
      expect(page).to have_content("Delivery partner updated")
      expect(DeliveryPartnership.find_by(id: delivery_partnership.id)).to be_nil
    end

    scenario "assigning two courses to a delivery partner" do
      lead_provider = lead_providers.first
      first_course = courses.first
      second_course = create(:course)

      create(:delivery_partnership,
             delivery_partner:,
             lead_provider:,
             course: first_course)

      visit edit_admin_delivery_partner_delivery_partnerships_path(delivery_partner)

      within("#delivery-partner-lead-provider-id-#{lead_provider.id}-conditional") do
        check second_course.name, visible: :all
      end

      click_button "Save"

      expect(page).to have_current_path(admin_delivery_partners_path)
      expect(delivery_partner.courses.reload).to contain_exactly(first_course, second_course)
    end

    scenario "assigning a course when another delivery partner has a similar name" do
      delivery_partner.update!(name: "Delivery partner 1")
      create(:delivery_partner, name: "Delivery partner 2")
      lead_provider = lead_providers.first
      course = courses.first

      visit edit_admin_delivery_partner_delivery_partnerships_path(delivery_partner)

      check lead_provider.name, visible: :all
      within("#delivery-partner-lead-provider-id-#{lead_provider.id}-conditional") do
        check course.name, visible: :all
      end

      click_button "Save"

      expect(page).to have_current_path(admin_delivery_partners_path)
      expect(page).not_to have_content("We found similar delivery partners")
      expect(DeliveryPartnership.where(delivery_partner:, lead_provider:, course:)).to exist
    end

    scenario "removing a specific course from a course provider partnership" do
      # Create existing partnerships for two courses
      lead_provider = lead_providers.first
      course1 = courses.first
      course2 = courses.second

      partnership1 = create(:delivery_partnership,
                            delivery_partner:,
                            lead_provider:,
                            course: course1)

      partnership2 = create(:delivery_partnership,
                            delivery_partner:,
                            lead_provider:,
                            course: course2)

      visit edit_admin_delivery_partner_delivery_partnerships_path(delivery_partner)

      # The course provider should be checked
      expect(page).to have_field("delivery_partner[lead_provider_id][]", with: lead_provider.id.to_s, checked: true, visible: :all)

      # Both courses should be checked
      within("#delivery-partner-lead-provider-id-#{lead_provider.id}-conditional") do
        expect(page).to have_field(course1.name, checked: true, visible: :all)
        expect(page).to have_field(course2.name, checked: true, visible: :all)

        # Uncheck just the first course
        uncheck course1.name, visible: :all
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
end
