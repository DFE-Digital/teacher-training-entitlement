require "rails_helper"

RSpec.describe Statements::MilestoneCourseCohortCalculator do
  subject(:calculator) do
    described_class.new(
      statement:,
      course_cohort:,
      milestone:,
      funded_place:,
      contract:,
    )
  end

  let(:lead_provider) { create(:lead_provider) }
  let(:statement) { create(:statement, lead_provider:, deadline_date: Time.zone.today) }
  let(:paid_statement) { create(:statement, :paid, lead_provider:) }
  let(:course_cohort) do
    create(:course_cohort).tap do |course_cohort|
      create(:course_cohort_provider, course_cohort:, lead_provider:, teacher_funding: 100)
    end
  end
  let(:contract) { lead_provider.contract(course_cohort:) }
  let(:milestone) { create(:milestone, :started, course_cohort:, payment_amount: 60, acceptance_window_start_date: 1.day.ago) }
  let(:funded_place) { [true] }

  def create_declaration(application:, statement:, milestone:)
    if milestone.started_declaration_type?
      application.update!(status: Application::STARTED)
    else
      application.update!(status: Application::STARTED) if application.accepted_status?
      application.update!(status: Application::COMPLETED)
    end

    create(
      :declaration,
      :eligible,
      milestone.declaration_type.to_sym,
      application:,
      statement:,
      milestone:,
      lead_provider: statement.lead_provider,
    )
  end

  describe "#row" do
    context "with a funded started milestone" do
      before do
        create_list(:application, 2, :with_funded_place, course_cohort:, lead_provider:, status: Application::REJECTED)
        create_declaration(application: funded_apps.first, statement: paid_statement, milestone:)

        (funded_apps[1..2] + self_funded_apps).each do |application|
          create_declaration(application:, statement:, milestone:)
        end
      end

      let(:funded_apps) { create_list(:application, 4, :accepted, :with_funded_place, course_cohort:, lead_provider:) }
      let(:self_funded_apps) { create_list(:application, 1, :accepted, :without_funded_place, course_cohort:, lead_provider:) }

      it "counts funded applications in started states and deducts declarations on previous statements" do
        expect(calculator.row).to eq(
          declaration_type: Milestone::STARTED,
          expected: 3,
          received: 2,
          outstanding: 1,
          value: BigDecimal(60),
          expected_value: BigDecimal(180),
          received_value: BigDecimal(120),
        )
      end
    end

    context "with a self-funded started milestone" do
      before do
        create_declaration(application: funded_app, statement:, milestone:)
        create_declaration(application: self_funded_app, statement:, milestone:)
      end

      let(:funded_place) { [nil, false] }
      let(:funded_app) { create(:application, :accepted, :with_funded_place, course_cohort:, lead_provider:) }
      let(:self_funded_app) { create(:application, :accepted, :without_funded_place, course_cohort:, lead_provider:) }

      it "counts received declarations without forecasting expected payments" do
        expect(calculator.row).to eq(
          declaration_type: Milestone::STARTED,
          expected: 0,
          received: 1,
          outstanding: 0,
          expected_value: 0,
          received_value: 0,
        )
      end
    end

    context "with a funded completed milestone" do
      before do
        accepted_application
        started_application.update!(status: Application::STARTED)
        rejected_application

        create_declaration(application: completed_application, statement:, milestone:)
      end

      let(:milestone) { create(:milestone, :completed, course_cohort:, payment_amount: 40, acceptance_window_start_date: 1.day.ago) }
      let(:accepted_application) { create(:application, :accepted, :with_funded_place, course_cohort:, lead_provider:) }
      let(:started_application) { create(:application, :accepted, :with_funded_place, course_cohort:, lead_provider:) }
      let(:completed_application) { create(:application, :accepted, :with_funded_place, course_cohort:, lead_provider:) }
      let(:rejected_application) { create(:application, :with_funded_place, course_cohort:, lead_provider:, status: Application::REJECTED) }

      it "counts only started and completed applications as expected" do
        expect(calculator.row).to include(
          declaration_type: Milestone::COMPLETED,
          expected: 2,
          received: 1,
          outstanding: 1,
          value: BigDecimal(40),
        )
      end
    end

    context "when the statement deadline is before the milestone acceptance window" do
      let(:statement) { create(:statement, lead_provider:, start_date: 1.month.ago.beginning_of_month) }
      let(:milestone) { create(:milestone, :started, course_cohort:, payment_amount: 60, acceptance_window_start_date: Time.zone.today) }

      before do
        create(:application, :accepted, :with_funded_place, course_cohort:, lead_provider:)
      end

      it "does not forecast expected declarations" do
        expect(calculator.row).to include(expected: 0, received: 0, outstanding: 0)
      end
    end
  end
end
