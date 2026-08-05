require "rails_helper"

RSpec::Matchers.define :be_a_contractual_match do |expected|
  match do |actual|
    actual.attribute_names.all? do |attribute|
      a_value = actual.public_send(attribute.to_sym)
      b_value = expected.public_send(attribute.to_sym)
      a_value == b_value
    end
  end
  description do |actual|
    expected_attrs = actual.attributes_from(expected)
    "be a contractual match of #{expected_attrs}"
  end
  failure_message do |actual|
    expected_attrs = actual.attributes_from(expected)
    "expected contract #{actual.attributes} to match #{expected_attrs}"
  end
end

RSpec.describe ComputedContract, type: :model do
  let(:nil_contract) do
    described_class.new(
      recruitment_target: nil,
      teacher_funding: nil,
      service_fee: nil,
    )
  end
  let(:course) { create(:course) }
  let(:lead_provider) { create(:lead_provider) }
  let(:academic_year) { 2026 }
  let(:course_cohort) { create(:course_cohort, course:, academic_year:) }

  describe "#.draw contract for service usage" do
    subject(:contract) { described_class.draw(lead_provider:, course_cohort:) }

    context "when a generic contract is setup" do
      let!(:generic) do
        create(
          :contract_year,
          :generic,
          lead_provider:,
          course:,
          teacher_funding: 600,
          service_fee: nil,
        )
      end

      context "without academic year nor course cohort provider" do
        it "raises an error as course_cohort_provider is required" do
          expect { contract }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "without academic_year amendment and with course_cohort empty course_cohort_provider" do
        before do
          course_cohort.course_cohort_providers.create(lead_provider: lead_provider)
        end

        it { is_expected.to be_a_contractual_match(generic) }
      end

      context "with only an academic year amendment" do
        before do
          create(
            :contract_year,
            lead_provider:,
            course:,
            academic_year: course_cohort.academic_year,
            teacher_funding: 123,
          )
        end

        it "raises an error as course_cohort_provider is required" do
          expect { contract }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "with only an course cohort amendment" do
        let(:expected_contract) do
          described_class.new(
            recruitment_target: 450,
            teacher_funding: 600,
            service_fee: nil,
          )
        end

        before do
          course_cohort
            .course_cohort_providers
            .create(lead_provider: lead_provider, recruitment_target: 450)
        end

        it { is_expected.to be_a_contractual_match(expected_contract) }
      end

      context "with both academic year and course cohort amendment" do
        before do
          course_cohort
            .course_cohort_providers
            .create!(lead_provider: lead_provider, recruitment_target: 450)

          create(
            :contract_year,
            lead_provider:,
            course:,
            academic_year: course_cohort.academic_year,
            teacher_funding: 123,
          )
          create(
            :contract_year,
            lead_provider:,
            course:,
            academic_year: course_cohort.academic_year + 1,
            teacher_funding: 777,
          )
        end

        let(:expected_contract) do
          described_class.new(
            recruitment_target: 450,
            teacher_funding: 123,
            service_fee: nil,
          )
        end

        it { is_expected.to be_a_contractual_match(expected_contract) }
      end
    end

    context "when no generic contract is setup" do
      context "without academic year nor course cohort amendment" do
        it "raises an error as course_cohort_provider is required" do
          expect { contract }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe "#.generic" do
    subject(:contract) { described_class.generic(lead_provider:, course:) }

    context "when setup" do
      let!(:generic) do
        create(
          :contract_year,
          lead_provider:,
          course:,
          academic_year: nil,
          teacher_funding: 140,
        )
      end

      before do
        create(
          :contract_year,
          lead_provider:,
          course:,
          academic_year: 2026,
          recruitment_target: 284,
          teacher_funding: 390,
          service_fee: 100,
        )
      end

      it { is_expected.to be_a_contractual_match(generic) }
    end
  end

  describe "#.academic_year_amendment" do
    subject(:contract) { described_class.academic_year_amendment(lead_provider:, course:, academic_year:) }

    let!(:contract_year) do
      create(
        :contract_year,
        lead_provider:,
        course:,
        academic_year: 2026,
        recruitment_target: 284,
        teacher_funding: 390,
        service_fee: 100,
      )
    end

    context "when academic year is present" do
      let(:academic_year) { contract_year.academic_year }

      it { is_expected.to be_a_contractual_match(contract_year) }
    end

    context "when academic year missing" do
      let(:academic_year) { nil }

      it { is_expected.to be_a_contractual_match(nil_contract) }
    end
  end

  describe "#.course_cohort_amendment" do
    subject(:contract) { described_class.course_cohort_amendment(lead_provider:, course_cohort:) }

    before do
      course_cohort
        .course_cohort_providers
        .create(
          lead_provider:,
          recruitment_target: 30,
          teacher_funding: 923,
        )
    end

    let(:expected_contract) do
      described_class.new(
        recruitment_target: 30,
        teacher_funding: 923,
        service_fee: nil,
      )
    end

    it { is_expected.to be_a_contractual_match(expected_contract) }
  end

  describe ".attributes_from" do
    subject(:attrs) { described_class.new.attributes_from(input) }

    context "when it is a contract year" do
      let(:input) { create(:contract_year, recruitment_target: 100) }

      it { is_expected.to eq({ "recruitment_target" => 100 }) }
    end

    context "when input nil" do
      let(:input) { nil }

      it { is_expected.to eq({}) }
    end
  end

  describe ".apply_amendment" do
    subject(:amended_contract) { a_contract.apply_amendment(b_contract) }

    context "when both generic and amendment contracts are nil" do
      let(:a_contract) { nil_contract }
      let(:b_contract) do
        described_class.new(
          recruitment_target: nil,
          teacher_funding: nil,
          service_fee: nil,
        )
      end
      let(:expected_contract) do
        described_class.new(
          recruitment_target: nil,
          teacher_funding: nil,
          service_fee: nil,
        )
      end

      it { is_expected.to be_a_contractual_match(expected_contract) }
    end

    context "when amendment contracts with nil values" do
      let(:a_contract) do
        described_class.new(
          recruitment_target: 500,
          teacher_funding: nil,
          service_fee: nil,
        )
      end
      let(:b_contract) do
        described_class.new(
          recruitment_target: nil,
          teacher_funding: 150,
          service_fee: nil,
        )
      end
      let(:expected_contract) do
        described_class.new(
          recruitment_target: 500,
          teacher_funding: 150,
          service_fee: nil,
        )
      end

      it { is_expected.to be_a_contractual_match(expected_contract) }
    end
  end
end
