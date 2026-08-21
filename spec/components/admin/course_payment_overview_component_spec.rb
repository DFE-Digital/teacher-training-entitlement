require "rails_helper"

RSpec.describe Admin::CoursePaymentOverviewComponent, type: :component do
  subject(:rendered) { render_inline component }

  let(:component) { described_class.new(statement:, course_cohort_calculator:) }
  let(:lead_provider) { create(:lead_provider) }
  let(:statement) { create(:statement, lead_provider:) }
  let(:course_cohort_provider) { create(:course_cohort_provider, lead_provider:, teacher_funding: 100) }
  let(:course_cohort) { course_cohort_provider.course_cohort }
  let(:course) { course_cohort.course }
  let(:course_cohort_calculator) { Statements::CourseCohortCalculator.new(statement:, course_cohort:) }

  let(:funded) do
    [
      {
        declaration_type: Milestone::STARTED,
        expected: 1,
        received: 3,
        outstanding: 0,
        value: 10,
        expected_value: 10,
        received_value: 10,
      },
      {
        declaration_type: Milestone::COMPLETED,
        expected: 4,
        received: 1,
        outstanding: 1,
        value: 10,
        expected_value: 40,
        received_value: 30,
      },
    ]
  end

  let(:self_funded) do
    [
      {
        declaration_type: Milestone::STARTED,
        expected: 0,
        received: 5,
        outstanding: 0,
        value: 0,
        expected_value: 0,
        received_value: 0,
      },
      {
        declaration_type: Milestone::COMPLETED,
        expected: 0,
        received: 2,
        outstanding: 0,
        value: 0,
        expected_value: 0,
        received_value: 0,
      },
    ]
  end

  before do
    allow(course_cohort_calculator).to receive_messages(funded:, self_funded:)
  end

  it { is_expected.to have_css "h2", text: course.name }

  describe "funded table" do
    it "has correct headings" do
      expect(rendered).to have_css "h3", text: "Funded"
      expect(rendered).to have_css "thead th", text: t(".payment_type")
      expect(rendered).to have_css "thead th", text: t(".participants")
      expect(rendered).to have_css "thead th", text: t(".payment_per_participant")
      expect(rendered).to have_css "thead th", text: t(".total")
    end

    it "shows started row" do
      expect(rendered).to have_css "tbody tr:nth-child(1) td:nth-child(1)", text: t(".started")
      expect(rendered).to have_css "tbody tr:nth-child(1) td:nth-child(2)", text: "3"
    end

    it "shows completed row" do
      expect(rendered).to have_css "tbody tr:nth-child(2) td:nth-child(1)", text: t(".completed")
      expect(rendered).to have_css "tbody tr:nth-child(2) td:nth-child(2)", text: "1"
    end

    it "shows total row" do
      expect(rendered).to have_css "tbody tr:nth-child(3) td:nth-child(1)", text: t(".total")
      expect(rendered).to have_css "tbody tr:nth-child(3) td:nth-child(2)", text: "4"
    end

    it "does not show output payment row" do
      expect(rendered).not_to have_text t(".output_payment")
    end

    it "does not show retained rows" do
      expect(rendered).not_to have_text "Retained"
    end

    it "does not show total not eligible for funding" do
      expect(rendered).not_to have_text t(".total_not_eligible_for_funding")
    end
  end

  describe "self-funded table" do
    it "has correct headings" do
      expect(rendered).to have_css "h3", text: "Self-funded"
    end

    it "shows started row" do
      self_funded_table = rendered.css("table")[1]
      expect(self_funded_table.text).to include(t(".started"))
      expect(self_funded_table.css("tbody tr:nth-child(1) td:nth-child(2)").text).to eq("5")
    end

    it "shows completed row" do
      self_funded_table = rendered.css("table")[1]
      expect(self_funded_table.css("tbody tr:nth-child(2) td:nth-child(2)").text).to eq("2")
    end

    it "shows total row" do
      self_funded_table = rendered.css("table")[1]
      expect(self_funded_table.css("tbody tr:nth-child(3) td:nth-child(2)").text).to eq("7")
    end

    it "does not have payment per participant column" do
      self_funded_table = rendered.css("table")[1]
      expect(self_funded_table.css("th").map(&:text)).not_to include(t(".payment_per_participant"))
    end
  end

  def t(key)
    I18n.t("admin.course_payment_overview_component#{key}")
  end
end
