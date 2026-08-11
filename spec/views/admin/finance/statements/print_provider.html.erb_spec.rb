require "rails_helper"

RSpec.describe "admin/finance/statements/print_provider", :npq, type: :view do
  subject { render }

  let(:rendered) { Capybara.string(subject) }
  let(:statement) { create(:statement, :open) }
  let(:admin_user) { create(:admin) }
  let(:course) { create(:course, :npd_eirt) }
  let(:lead_provider) { statement.lead_provider }
  let(:course_cohort) { create(:course_cohort, course:) }

  before do
    create(:course_cohort_provider, course_cohort:, lead_provider:, recruitment_target: 100, teacher_funding: 900)
    assign(:statement, statement)
    assign(:course_cohorts, [course_cohort])
    without_partial_double_verification { allow(view).to receive(:current_admin).and_return(admin_user) }
  end

  it "shows the statement overview" do
    summary_card = rendered.find(".govuk-summary-card", text: "Overview")
    expect(summary_card).to have_summary_item("Output payment date", statement.payment_date.to_fs(:govuk))
    expect(summary_card).to have_summary_item("Status", statement.state.humanize)
    expect(summary_card).to have_summary_item("Statement ID", statement.ecf_id)
  end

  it "shows the statement summary" do
    expect(subject).to have_component(Admin::StatementSummaryComponent.new(statement:))
  end

  it "shows adjustments" do
    expect(subject).to have_component(Admin::AdjustmentsTableComponent.new(adjustments: statement.adjustments, show_total: true))
  end

  it "shows the course finance details" do
    expect(subject).to have_component(Admin::CoursePaymentOverviewComponent.new(course_cohort:, statement:))
  end

  it "shows the course finance details heading" do
    expect(rendered).to have_css "h2", text: course.name
  end

  it "shows the contract finance details" do
    expect(rendered).to have_table rows: [
      [course.name, 100, number_to_currency(900)],
    ]
  end
end
