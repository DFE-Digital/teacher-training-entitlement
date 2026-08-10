# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::StatementSummaryComponent, type: :component do
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::NumberHelper

  subject(:rendered) { render_inline described_class.new(statement:) }

  let(:statement) { create(:statement) }
  let(:summary_list) { page.find(".govuk-summary-list") }
  let(:declarations_table) { page.find(".govuk-table") }

  let(:calculator) do
    OpenStruct.new(
      total_service_fees: 0,
      total_output_payment: 100.12,
      expected_output_payment: 200.00,
      total_clawbacks: 50.34,
      total_adjustments: -10,
      total_payment: 39.78,
      total_starts: 5,
      total_completed: 3,
      total_voided: 4,
      expected_starts: 10,
      expected_completed: 5,
      expected_total: 15,
      outstanding_starts: 5,
      outstanding_completed: 2,
      outstanding_total: 7,
      total_declarations: 8,
    )
  end

  before do
    allow(::Statements::SummaryCalculator).to receive(:new).and_return(calculator)
  end

  it { is_expected.to have_text "Statement summary" }
  it { is_expected.to have_text "Funded declarations" }
  it { is_expected.to have_text "Payment details" }

  it { is_expected.not_to have_text "The output payment deadline is" }

  it "shows funded declarations table headers" do
    subject
    expect(declarations_table).to have_text("Declaration type")
    expect(declarations_table).to have_text("Expected")
    expect(declarations_table).to have_text("Received")
    expect(declarations_table).to have_text("Outstanding")
  end

  it "shows starts row" do
    subject
    expect(declarations_table).to have_text("Starts")
    expect(declarations_table).to have_text(calculator.expected_starts.to_s)
    expect(declarations_table).to have_text(calculator.total_starts.to_s)
    expect(declarations_table).to have_text(calculator.outstanding_starts.to_s)
  end

  it "shows completed row" do
    subject
    expect(declarations_table).to have_text("Completed")
    expect(declarations_table).to have_text(calculator.expected_completed.to_s)
    expect(declarations_table).to have_text(calculator.total_completed.to_s)
    expect(declarations_table).to have_text(calculator.outstanding_completed.to_s)
  end

  it "shows total row" do
    subject
    expect(declarations_table).to have_text("Total")
    expect(declarations_table).to have_text(calculator.expected_total.to_s)
    expect(declarations_table).to have_text(calculator.total_declarations.to_s)
    expect(declarations_table).to have_text(calculator.outstanding_total.to_s)
  end

  it "shows payment details" do
    subject
    expect(summary_list).to have_summary_item("Expected output payment", number_to_currency(calculator.expected_output_payment))
    expect(summary_list).to have_text("Output payment")
    expect(summary_list).to have_text(number_to_currency(calculator.total_output_payment))
    expect(summary_list).to have_summary_item("Declaration deadline", statement.deadline_date.to_fs(:govuk))
    expect(summary_list).to have_summary_item("Voids", calculator.total_voided)
    expect(summary_list).to have_text("Clawbacks")
    expect(summary_list).to have_text(number_to_currency(-calculator.total_clawbacks))
    expect(summary_list).to have_summary_item("Manual adjustments", number_to_currency(calculator.total_adjustments))
  end

  it "shows output payment subtext" do
    subject
    expect(summary_list).to have_text("This payment takes into account late declarations and voids")
  end

  it "shows clawbacks subtext" do
    subject
    expect(summary_list).to have_text("The total value of voids")
  end

  it { is_expected.to have_link "View Voids", href: admin_finance_voided_index_path(statement) }
  it { is_expected.to have_link "Change", href: admin_finance_statements_change_deadline_date_path(statement) }

  context "when link_to_voids is false" do
    subject(:rendered) { render_inline described_class.new(statement:, link_to_voids: false) }

    it { is_expected.not_to have_link "View Voids", href: admin_finance_voided_index_path(statement) }
  end

  context "without total service fees" do
    it { is_expected.not_to have_text "Service fee" }
  end

  context "with total service fees" do
    before do
      allow(calculator).to receive(:total_service_fees).and_return(123)
      subject
    end

    it "shows total service fees" do
      expect(summary_list).to have_summary_item("Service fee", number_to_currency(123))
    end
  end

  it "does not show retained row" do
    subject
    expect(page).not_to have_text("Retained")
  end
end
