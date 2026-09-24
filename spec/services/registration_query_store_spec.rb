require "rails_helper"

RSpec.describe RegistrationQueryStore do
  subject(:query_store) { described_class.new(store:) }

  let(:store) { {} }

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
