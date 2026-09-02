require "rails_helper"

RSpec.describe RegistrationQueryStore do
  subject(:query_store) { described_class.new(store:) }

  let(:store) { {} }

  describe "#course_cohort" do
    context "when the store has a valid course_cohort_id" do
      let(:course_cohort) { create(:course_cohort) }
      let(:store) { { "course_cohort_id" => course_cohort.id } }

      it "returns the stored course cohort" do
        expect(query_store.course_cohort).to eq(course_cohort)
      end
    end

    context "when the store has no course_cohort_id" do
      let(:course) { build_stubbed(:course, :npd_eirt) }
      let(:course_cohort) { build_stubbed(:course_cohort, course:) }

      before do
        allow(Course).to receive(:reception).and_return(course)
        allow(CourseCohort).to receive(:next_open_for).with(course:).and_return(course_cohort)
      end

      it "returns the next open course cohort" do
        expect(query_store.course_cohort).to eq(course_cohort)
      end

      it "stores the course_cohort_id" do
        query_store.course_cohort

        expect(store["course_cohort_id"]).to eq(course_cohort.id)
      end
    end

    context "when the store has a stale course_cohort_id" do
      let(:store) { { "course_cohort_id" => "999999" } }

      before do
        allow(CourseCohort).to receive(:next_open_for)
      end

      it "returns nil" do
        expect(query_store.course_cohort).to be_nil
      end

      it "does not try to assign a course cohort" do
        query_store.course_cohort

        expect(CourseCohort).not_to have_received(:next_open_for)
      end
    end

    context "when there is no open course cohort" do
      let(:course) { build_stubbed(:course, :npd_eirt) }

      before do
        allow(Course).to receive(:reception).and_return(course)
        allow(CourseCohort).to receive(:next_open_for).with(course:).and_return(nil)
      end

      it "returns nil" do
        expect(query_store.course_cohort).to be_nil
      end

      it "does not store a course_cohort_id" do
        query_store.course_cohort

        expect(store).not_to have_key("course_cohort_id")
      end
    end
  end
end
