require "rails_helper"

RSpec.describe Admin::CoursePaymentOverviewComponent, type: :component do
  subject(:rendered) { render_inline component }

  let(:component) { described_class.new(course_cohort:, statement:) }
  let(:cohort) { create(:cohort, :with_funding_cap) }
  let(:lead_provider) { create(:lead_provider) }
  let(:statement) { create(:statement, lead_provider:) }
  let(:course) { create(:course, :npd_eirt) }
  let(:course_cohort) { create(:course_cohort, course:, cohort:) }

  let(:calculator) do
    instance_double(
      ::Statements::Calculate,
      output_payment_per_participant: 100.0,
    ).tap do |calc|
      allow(calc).to receive(:funded_billable_count_for_type) do |type|
        { "started" => 3, "completed" => 1 }[type]
      end
      allow(calc).to receive(:self_funded_billable_count_for_type) do |type|
        { "started" => 5, "completed" => 2 }[type]
      end
    end
  end

  before do
    allow(::Statements::Calculate).to receive(:new).and_return(calculator)
    create(:schedule, :tte_reception_autumn, cohort:)
    create(:schedule, :tte_reception_spring, cohort:)
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
      self_funded_table = rendered.css("table").last
      expect(self_funded_table.text).to include(t(".started"))
      expect(self_funded_table.css("tbody tr:nth-child(1) td:nth-child(2)").text).to eq("5")
    end

    it "shows completed row" do
      self_funded_table = rendered.css("table").last
      expect(self_funded_table.css("tbody tr:nth-child(2) td:nth-child(2)").text).to eq("2")
    end

    it "shows total row" do
      self_funded_table = rendered.css("table").last
      expect(self_funded_table.css("tbody tr:nth-child(3) td:nth-child(2)").text).to eq("7")
    end

    it "does not have payment per participant column" do
      self_funded_table = rendered.css("table").last
      expect(self_funded_table.css("th").map(&:text)).not_to include(t(".payment_per_participant"))
    end
  end

  def t(key)
    I18n.t("admin.course_payment_overview_component#{key}")
  end
end
