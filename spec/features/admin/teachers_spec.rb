require "rails_helper"

RSpec.feature "Teacher administration", type: :feature do
  include Helpers::AdminLogin

  let(:teachers_per_page) { Pagy::DEFAULT[:limit] }
  let(:teacher) { Teacher.first }

  before do
    create_list(:teacher, teachers_per_page, :with_one_login_id)
    teacher.update!(national_insurance_number: "QQ123456C", preferred_name: "Jonny D")
    sign_in_as(create(:admin))
  end

  feature "viewing a teacher" do
    scenario "shows teacher details" do
      visit admin_teacher_path(teacher)

      expect(page).to have_css("h1", text: teacher.full_name)

      within(".govuk-summary-card", text: "Overview") do |summary_card|
        expect(summary_card).to have_summary_item("Teacher ID", teacher.ecf_id)
        expect(summary_card).to have_summary_item("Preferred Name", teacher.preferred_name)
        expect(summary_card).to have_summary_item("Email", teacher.email)
        expect(summary_card).to have_summary_item("Date of birth", teacher.date_of_birth.to_fs(:govuk_short))
        expect(summary_card).to have_summary_item("National Insurance number", teacher.national_insurance_number)
        expect(summary_card).to have_summary_item("TRN", teacher.trn)
        expect(summary_card).to have_summary_item("One Login ID", teacher.one_login_id)
      end
    end

    scenario "shows 'TRN Requested' when TRN has been requested" do
      teacher.update!(trn: nil, trn_requested_at: 1.hour.ago)
      visit admin_teacher_path(teacher)

      within(".govuk-summary-card", text: "Overview") do |summary_card|
        expect(summary_card).to have_summary_item("TRN", "TRN Requested")
      end
    end

    scenario "renders when attributes with method chains are nil" do
      teacher.update!(date_of_birth: nil)
      visit admin_teacher_path(teacher)

      expect(page).to have_content("Date of birth")
    end

    scenario "shows a message if the teacher has no applications" do
      visit admin_teacher_path(teacher)

      expect(page).to have_css("h1", text: teacher.full_name)
      expect(page).to have_css(".govuk-body", text: "This teacher has no applications.")
    end

    scenario "shows a summary of each teacher application" do
      applications = %i[npd_eirt]
        .map { create(:application, teacher:, course: create(:course, _1)) }
        .sort_by { [_1.created_at, _1.id] }

      applications.each do |a|
        create(:declaration, :completed, :paid, application: a)
      end
      visit admin_teacher_path(teacher)

      expect(page).to have_css("h1", text: teacher.full_name)
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
