require "rails_helper"

RSpec.describe RegistrationQueryStore do
  subject(:query_store) { described_class.new(store:) }

  let(:store) { {} }

  describe "#teacher_catchment_humanized" do
    subject { query_store.teacher_catchment_humanized }

    context "when the teacher catchment is England" do
      let(:store) { { "teacher_catchment" => Institution::ENGLAND_SUBDIVISION_CODE } }

      it { is_expected.to eq("Yes") }
    end

    context "when the teacher catchment is not England" do
      let(:store) { { "teacher_catchment" => "another" } }

      it { is_expected.to eq("No") }
    end
  end

  describe "#teacher_catchment_england?" do
    subject { query_store.teacher_catchment_england? }

    context "when the teacher catchment is England" do
      let(:store) { { "teacher_catchment" => Institution::ENGLAND_SUBDIVISION_CODE } }

      it { is_expected.to be true }
    end

    context "when the teacher catchment is not England" do
      let(:store) { { "teacher_catchment" => "another" } }

      it { is_expected.to be false }
    end
  end

  describe "#course_cohort" do
    context "when the store has a valid course_cohort_id" do
      let(:course_cohort) { create(:course_cohort) }
      let(:store) { { "course_cohort_ecf_id" => course_cohort.ecf_id } }

      it "returns the stored course cohort" do
        expect(query_store.course_cohort).to eq(course_cohort)
      end
    end

    context "when the store has a stale course_cohort_id" do
      let(:store) { { "course_cohort_ecf_id" => "999999" } }

      it "returns nil" do
        expect(query_store.course_cohort).to be_nil
      end
    end

    context "when there is no open course cohort" do
      it "returns nil" do
        expect(query_store.course_cohort).to be_nil
      end
    end
  end
end
