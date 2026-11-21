require "rails_helper"

RSpec.describe Registration::StateStore do
  subject(:state_store) { described_class.new(repository: DfE::Wizard::Repository::InMemory.new) }

  let(:course) { create(:course) }
  let(:course_cohort) { course.course_cohorts.first }

  before { state_store.course = course }

  describe "#start_later?" do
    it "is true when later is picked" do
      state_store.write(course_start_date: "later")

      expect(state_store.start_later?).to be(true)
    end

    it "is false otherwise" do
      state_store.write(course_start_date: course_cohort.ecf_id)

      expect(state_store.start_later?).to be(false)
    end
  end

  describe "#course_cohort" do
    it "is the picked open course cohort" do
      state_store.write(course_start_date: course_cohort.ecf_id)

      expect(state_store.course_cohort).to eq(course_cohort)
    end

    it "is nil when later is picked" do
      state_store.write(course_start_date: "later")

      expect(state_store.course_cohort).to be_nil
    end

    it "is nil for a course cohort of another course" do
      other = create(:course_cohort, course: create(:course), cohort: create(:cohort, :current, registration_starts_at: 2.days.ago.to_date))
      state_store.write(course_start_date: other.ecf_id)

      expect(state_store.course_cohort).to be_nil
    end
  end

  describe "#registerable_course_cohorts" do
    it "only includes the selected course" do
      create(:course_cohort, course: create(:course), cohort: create(:cohort, :current, registration_starts_at: 2.days.ago.to_date))

      expect(state_store.registerable_course_cohorts).to eq([course_cohort])
    end
  end

  describe "#lead_provider" do
    it "is the picked provider" do
      provider = course_cohort.lead_providers.first
      state_store.write(lead_provider_id: provider.id.to_s)

      expect(state_store.lead_provider).to eq(provider)
    end
  end
end
