require "rails_helper"

RSpec.feature "Application declaration details", :versioning, type: :feature do
  include Helpers::AdminLogin

  let(:course_cohort_provider) { create(:course_cohort_provider, teacher_funding: 650) }
  let(:lead_provider) { course_cohort_provider.lead_provider }
  let(:course_cohort) { course_cohort_provider.course_cohort }
  let(:application) { create(:application, lead_provider:, course_cohort:) }
  let(:payable_statement) { create(:statement, :payable, lead_provider:) }
  let(:started_milestone) { create(:milestone, :started, course_cohort:) }
  let(:completed_milestone) { create(:milestone, :completed, course_cohort:) }
  let(:payable_milestone) { create(:milestone, declaration_type: Milestone::RETAINED_1, course_cohort:) }

  context "when not logged in" do
    scenario "viewing declaration details" do
      visit(admin_application_path(application))
      expect(page).to have_current_path(sign_in_path)
    end
  end

  context "when logged in as an admin" do
    let!(:started_declaration) { create(:declaration, :eligible, :started, application:, statement: payable_statement, milestone: started_milestone) }
    let!(:completed_declaration) { create(:declaration, :eligible, :completed, :submitted, application:, statement: payable_statement, milestone: completed_milestone) }

    before do
      completed_declaration.mark_eligible!
      create(:declaration, :payable, application:, declaration_type: Milestone::RETAINED_1, milestone: payable_milestone, statement: payable_statement)
      sign_in_as(create(:admin))
    end

    scenario "viewing declaration details" do
      visit(admin_application_path(application))
      click_link "Declaration details"

      expect(page).to have_css("h1", text: "Declaration details")

      summary_cards = all(".govuk-summary-card")
      expect(summary_cards).to have_attributes(length: 3)

      within(summary_cards[0]) do |summary_card|
        expect(summary_card).to have_css(".govuk-summary-card__title", text: "Started (Eligible)")

        within(find(".govuk-summary-list")) do |summary_list|
          expect(summary_list).to have_summary_item("Declaration ID", started_declaration.ecf_id)
          expect(summary_list).to have_summary_item("Declaration date", started_declaration.declaration_date.to_fs(:govuk_short))
          expect(summary_list).to have_summary_item("Declaration cohort", started_declaration.milestone.cohort.name)
          expect(summary_list).to have_summary_item("Provider", started_declaration.lead_provider.name)
          expect(summary_list).to have_summary_item("Delivery partner", started_declaration.delivery_partner.name)
          expect(summary_list).to have_summary_item("Created at", started_declaration.created_at.to_fs(:govuk_short))
          expect(summary_list).to have_summary_item("Updated at", started_declaration.updated_at.to_fs(:govuk_short))
          expect(summary_list).to have_summary_item("Statement", "")
        end
      end

      within(summary_cards[1]) do |summary_card|
        expect(summary_card).to have_css(".govuk-summary-card__title", text: "Completed (Eligible)")

        within(find(".govuk-summary-list")) do |summary_list|
          expect(summary_list).to have_summary_item("Declaration ID", "-")
          expect(summary_list).to have_summary_item("Declaration date", completed_declaration.declaration_date.to_fs(:govuk_short))
          expect(summary_list).to have_summary_item("Declaration cohort", completed_declaration.milestone.cohort.name)
          expect(summary_list).to have_summary_item("Provider", completed_declaration.lead_provider.name)
          expect(summary_list).to have_summary_item("Delivery partner", completed_declaration.delivery_partner.name)
          expect(summary_list).to have_summary_item("Secondary delivery partner", "")
          expect(summary_list).to have_summary_item("Created at", completed_declaration.created_at.to_fs(:govuk_short))
          expect(summary_list).to have_summary_item("Updated at", completed_declaration.updated_at.to_fs(:govuk_short))
          expect(summary_list).to have_summary_item("Statement", "")
        end

        expect(summary_card).to have_css(".moj-timeline__item", text: /Submitted\s+#{completed_declaration.created_at.to_fs(:govuk_short)}/)
        expect(summary_card).to have_css(".moj-timeline__item", text: /Eligible\s+#{completed_declaration.created_at.to_fs(:govuk_short)}/)
      end

      within(summary_cards[2]) do
        within(find(".govuk-summary-list")) do |summary_list|
          expect(summary_list).to have_summary_item(
            "Statement",
            payable_statement.start_date.to_fs(:govuk_approx),
          )
        end
      end

      within(summary_cards[0]) do
        click_link(payable_statement.start_date.to_fs(:govuk_approx))
      end
      expect(page).to have_current_path(admin_finance_statement_path(payable_statement))
    end
  end
end
