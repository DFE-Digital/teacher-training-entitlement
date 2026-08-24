# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::StatementDetailsComponent, type: :component do
  include Rails.application.routes.url_helpers

  subject(:rendered) { render_inline described_class.new(statement:) }

  let(:statement) { create(:statement) }
  let(:calculator) { Statements::Calculate.new(statement:) }

  before do
    calculator
    allow(calculator).to receive(:declaration_types).and_return([Milestone::STARTED, Milestone::COMPLETED])
    allow(::Statements::Calculate).to receive(:new).and_return(calculator)
  end

  it { is_expected.to have_text t(".totals") }
  it { is_expected.to have_text(/#{t('.output_payment')}\s+£#{calculator.total_output_payment}/) }
  it { is_expected.to have_text(/#{t('.clawbacks')}\s+£#{calculator.total_clawbacks}/) }
  it { is_expected.to have_text(/#{t('.total_net_vat')}\s+£#{calculator.total_payment}/) }
  it { is_expected.to have_text(/#{t('.cut_off_date')}\s+#{statement.deadline_date.to_fs(:govuk)}/) }
  it { is_expected.to have_text(/#{t('.total', declaration_type: "started")}\s+#{calculator.get_funded(:received, declaration_type: "started")}/) }
  it { is_expected.to have_text(/#{t('.total', declaration_type: "completed")}\s+#{calculator.get_funded(:received, declaration_type: "completed")}/) }
  it { is_expected.to have_text(/#{t('.total_voids')}\s+#{calculator.total_voided}/) }
  it { is_expected.to have_link t(".view", href: admin_finance_voided_index_path(statement)) }

  context "when link_to_voids is false" do
    subject(:rendered) { render_inline described_class.new(statement:, link_to_voids: false) }

    it { is_expected.not_to have_link t(".view", href: admin_finance_voided_index_path(statement)) }
  end
end
