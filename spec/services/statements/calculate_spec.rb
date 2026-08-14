require "rails_helper"

RSpec.describe Statements::Calculate do
  let(:cohort) { create(:cohort, :with_funding_cap) }
  let(:lead_provider) { create(:lead_provider) }
  let(:statement) { create(:statement, :next_output_fee, lead_provider:) }
  let(:course) { create(:course, :npd_eirt) }
  let(:course_cohort) { create(:course_cohort, course:, cohort:) }
  let(:application) { create(:application, :accepted, :eligible_for_funding, course_cohort:, lead_provider:) }

  subject { described_class.new(statement:) }

  before do
    create(:schedule, :tte_reception_autumn, cohort:)
  end

  describe "#expected_starts" do
    it "counts accepted applications for course_cohorts with started milestones" do
      create(:declaration, :eligible, declaration_type: "started", application:, statement:)
      create(:application, :accepted, course_cohort:, lead_provider:)

      expect(subject.expected_starts).to eq(2)
    end

    it "only counts applications for this lead_provider" do
      create(:declaration, :eligible, declaration_type: "started", application:, statement:)
      create(:application, :accepted, course_cohort:, lead_provider: create(:lead_provider))

      expect(subject.expected_starts).to eq(1)
    end

    it "returns zero when no started milestones" do
      expect(subject.expected_starts).to eq(0)
    end
  end

  describe "#expected_completed" do
    it "counts started applications for course_cohorts with completed milestones" do
      started_app = create(:application, :started, course_cohort:, lead_provider:)
      create(:declaration, :eligible, declaration_type: "completed", application: started_app, statement:)
      create(:application, :started, course_cohort:, lead_provider:)

      expect(subject.expected_completed).to eq(2)
    end

    it "only counts applications for this lead_provider" do
      started_app = create(:application, :started, course_cohort:, lead_provider:)
      create(:declaration, :eligible, declaration_type: "completed", application: started_app, statement:)
      create(:application, :started, course_cohort:, lead_provider: create(:lead_provider))

      expect(subject.expected_completed).to eq(1)
    end

    it "returns zero when no completed milestones" do
      expect(subject.expected_completed).to eq(0)
    end
  end

  describe "#total_starts" do
    it "counts billable started declarations" do
      create(:declaration, :eligible, declaration_type: "started", application:, statement:)

      expect(subject.total_starts).to eq(1)
    end

    it "returns zero when no declarations" do
      expect(subject.total_starts).to eq(0)
    end
  end

  describe "#total_completed" do
    it "counts billable completed declarations" do
      started_app = create(:application, :started, course_cohort:, lead_provider:)
      create(:declaration, :eligible, declaration_type: "completed", application: started_app, statement:)

      expect(subject.total_completed).to eq(1)
    end
  end

  describe "#outstanding_starts" do
    it "returns expected minus received" do
      create(:declaration, :eligible, declaration_type: "started", application:, statement:)
      create(:application, :accepted, course_cohort:, lead_provider:)

      expect(subject.outstanding_starts).to eq(1)
    end

    it "returns zero when received exceeds expected" do
      create(:declaration, :eligible, declaration_type: "started", application:, statement:)

      expect(subject.outstanding_starts).to eq(0)
    end
  end

  describe "#outstanding_completed" do
    it "returns expected minus received" do
      started_app = create(:application, :started, course_cohort:, lead_provider:)
      create(:declaration, :eligible, declaration_type: "completed", application: started_app, statement:)
      create(:application, :started, course_cohort:, lead_provider:)

      expect(subject.outstanding_completed).to eq(1)
    end
  end

  describe "#total_declarations" do
    it "returns sum of starts and completed" do
      create(:declaration, :eligible, declaration_type: "started", application:, statement:)

      expect(subject.total_declarations).to eq(1)
    end
  end

  describe "#expected_total" do
    it "returns sum of expected starts and expected completed" do
      create(:declaration, :eligible, declaration_type: "started", application:, statement:)

      expect(subject.expected_total).to eq(1)
    end
  end

  describe "#outstanding_total" do
    it "returns sum of outstanding starts and outstanding completed" do
      create(:declaration, :eligible, declaration_type: "started", application:, statement:)
      create(:application, :accepted, course_cohort:, lead_provider:)

      expect(subject.outstanding_total).to eq(1)
    end
  end

  describe "#total_output_payment" do
    it "sums billable declaration values" do
      create(:declaration, :eligible, application:, statement:, value: 100)
      create(:declaration, :eligible, application: create(:application, :accepted, course_cohort:, lead_provider:), statement:, value: 50)

      expect(subject.total_output_payment).to eq(150.0)
    end

    it "returns zero when no declarations" do
      expect(subject.total_output_payment).to eq(0.0)
    end
  end

  describe "#total_clawbacks" do
    it "sums clawback declaration values" do
      create(:clawback_declaration, statement:, value: 100)
      create(:clawback_declaration, statement:, value: 60)

      expect(subject.total_clawbacks).to eq(160.0)
    end

    it "returns zero when no clawbacks" do
      expect(subject.total_clawbacks).to eq(0.0)
    end
  end

  describe "#total_adjustments" do
    it "sums adjustment amounts" do
      create(:adjustment, statement:, amount: 100)
      create(:adjustment, statement:, amount: 200)

      expect(subject.total_adjustments).to eq(300)
    end
  end

  describe "#total_voided" do
    it "counts voided declarations" do
      create(:declaration, :voided, application:, statement:)

      expect(subject.total_voided).to eq(1)
    end
  end

  describe "#expected_output_payment" do
    it "sums recruitment_target × teacher_funding from ComputedContract" do
      course_cohort.course_cohort_providers.create!(lead_provider:, recruitment_target: 10, teacher_funding: 100)
      create(:declaration, :eligible, declaration_type: "started", application:, statement:)

      expect(subject.expected_output_payment).to eq(1000)
    end

    it "returns zero when no course_cohort_providers" do
      expect(subject.expected_output_payment).to eq(0)
    end
  end

  describe "#total_payment" do
    it "calculates total as output - clawbacks + adjustments + reconcile" do
      create(:declaration, :eligible, application:, statement:, value: 500)
      create(:clawback_declaration, statement:, value: 100)
      create(:adjustment, statement:, amount: 50)
      statement.update!(reconcile_amount: 25)

      expect(subject.total_payment).to eq(475.0)
    end
  end
end
