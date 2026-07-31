require "rails_helper"

RSpec.describe Exporters::Contracts do
  subject { described_class.new(cohort:).call }

  let(:lead_provider) { create(:lead_provider, name: "Some Lead Provider") }
  let(:lead_provider_2) { create(:lead_provider, name: "Another Provider") }
  let(:course) { create(:course) }
  let(:course_2) { create(:course, :npd_eirt) }

  let(:cohort) { create(:cohort, :current) }

  let(:statement) { create(:statement, lead_provider:, start_date: 1.month.ago.beginning_of_month) }
  let(:statement_2) { create(:statement, lead_provider:, start_date: 2.months.ago.beginning_of_month) }
  let(:statement_3_different_lead_provider) { create(:statement, lead_provider: lead_provider_2, start_date: 1.month.ago.beginning_of_month) }

  let(:contract_template) { create(:contract_template) }
  let(:duplicate_contract_template) { create(:contract_template) } # yes, there are duplicate contracts templates in production
  let(:contract_template_2) { create(:contract_template, per_participant: 801, monthly_service_fee: nil) }

  before do
    create(:course_cohort, course:, cohort:)
    create(:course_cohort, course: course_2, cohort:)

    create(:contract, statement:, course:, contract_template:)
    create(:contract, statement: statement_2, course:, contract_template: duplicate_contract_template)
    create(:contract, statement:, course: course_2, contract_template: contract_template_2)
    create(:contract, statement: statement_3_different_lead_provider, course:, contract_template:)
  end

  it "generates a CSV with the correct header" do
    expect(subject.lines[0]).to eq "#{Exporters::Contracts::FIELD_NAMES.join(",")}\n"
  end

  it "generates a CSV of contracts" do
    expect(subject.lines.count).to eq(4) # header + contact_template for lead_provider + contract_template for lead_provider_2 + contract_template_2 for lead_provider_2

    expect(subject.lines.drop(1).map(&:chomp)).to contain_exactly(
      [
        "Some Lead Provider",
        course.identifier,
        contract_template.recruitment_target,
        contract_template.per_participant,
        contract_template.service_fee_installments,
        contract_template.special_course,
        contract_template.monthly_service_fee,
      ].join(","),
      [
        "Some Lead Provider",
        course_2.identifier,
        contract_template_2.recruitment_target,
        contract_template_2.per_participant,
        contract_template_2.service_fee_installments,
        contract_template_2.special_course,
        0.0,
      ].join(","),
      [
        "Another Provider",
        course.identifier,
        contract_template.recruitment_target,
        contract_template.per_participant,
        contract_template.service_fee_installments,
        contract_template.special_course,
        contract_template.monthly_service_fee,
      ].join(","),
    )
  end

  context "when there are statements that have different values for the same cohort, lead provider and course" do
    subject { described_class.new(cohort: older_cohort).call }

    let(:older_cohort) { create(:cohort, registration_starts_at: Date.new(2022, 4, 1)) }
    let(:older_cohort_course) { create(:course) }
    let(:older_statement_output_fee_true) { create(:statement, lead_provider:, output_fee: true, start_date: Date.new(2022, 1, 1)) }
    let(:older_statement_output_fee_false) { create(:statement, lead_provider:, output_fee: false, start_date: Date.new(2022, 2, 1)) }
    let(:latest_statement_output_fee_true) { create(:statement, lead_provider:, output_fee: true, start_date: Date.new(2022, 6, 1)) }
    let(:latest_statement_output_fee_false) { create(:statement, lead_provider:, output_fee: false, start_date: Date.new(2022, 7, 1)) }
    let(:future_statement_output_fee_true) { create(:statement, lead_provider:, output_fee: true, start_date: 1.year.from_now.beginning_of_month) }
    let(:contract_template_1) { create(:contract_template, service_fee_installments: 50, monthly_service_fee: nil) }
    let(:contract_template_2) { create(:contract_template, service_fee_installments: 24, monthly_service_fee: 10) }
    let(:contract_template_3) { create(:contract_template, service_fee_installments: 0, monthly_service_fee: 0.0) }
    let(:contract_template_4) { create(:contract_template, service_fee_installments: 100, monthly_service_fee: 200) }
    let(:contract_template_5) { create(:contract_template, service_fee_installments: 200, monthly_service_fee: 300) }

    before do
      create(:course_cohort, course: older_cohort_course, cohort: older_cohort)

      create(:contract, statement: older_statement_output_fee_true, course: older_cohort_course, contract_template: contract_template_1)
      create(:contract, statement: older_statement_output_fee_false, course: older_cohort_course, contract_template: contract_template_2)
      create(:contract, statement: latest_statement_output_fee_true, course: older_cohort_course, contract_template: contract_template_3)
      create(:contract, statement: latest_statement_output_fee_false, course: older_cohort_course, contract_template: contract_template_4)
      create(:contract, statement: future_statement_output_fee_true, course: older_cohort_course, contract_template: contract_template_5)
    end

    it "generates a CSV using the values of the latest output_fee statement" do
      expect(subject.lines.drop(1).map(&:chomp)).to contain_exactly(
        [
          "Some Lead Provider",
          older_cohort_course.identifier,
          contract_template_3.recruitment_target,
          contract_template_3.per_participant,
          contract_template_3.service_fee_installments,
          contract_template_3.special_course,
          contract_template_3.monthly_service_fee,
        ].join(","),
      )
    end
  end
end
