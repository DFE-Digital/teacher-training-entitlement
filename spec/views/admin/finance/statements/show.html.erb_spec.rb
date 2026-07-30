require "rails_helper"

RSpec.describe "admin/finance/statements/show", type: :view do
  subject { Capybara.string(render) }

  let(:contract) { create(:contract, course:, statement:) }
  let(:course) { create(:course, :npd_eirt) }

  before do
    assign(:statement, statement)
    assign(:special_contracts, [])
    assign(:contracts, [contract])
    without_partial_double_verification { allow(view).to receive(:current_admin).and_return(admin_user) }
  end

  context "when the user is a super admin" do
    let(:admin_user) { create(:admin, super_admin: true) }

    context "when the statement is current" do
      let(:statement) { create(:statement) }

      it { is_expected.to have_link("Change", href: admin_finance_change_per_participant_path(contract), visible: :all) }
    end

    context "when the statement is in the past" do
      let(:statement) { create(:statement, :payable) }

      it { is_expected.not_to have_link("Change", href: admin_finance_change_per_participant_path(contract), visible: :all) }
    end

    context "when the statement is paid" do
      let(:statement) { create(:statement, state: "paid", marked_as_paid_at: 1.week.ago) }

      it { is_expected.not_to have_link("Change", href: admin_finance_change_per_participant_path(contract), visible: :all) }
    end
  end

  context "when the user is not a super admin" do
    let(:admin_user) { create(:admin) }

    let(:statement) { create(:statement) }

    it { is_expected.not_to have_link("Change", href: admin_finance_change_per_participant_path(contract), visible: :all) }
  end
end
