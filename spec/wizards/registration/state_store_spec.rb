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

  describe "#registerable_lead_providers" do
    it "is the providers of the open course cohorts of the course, alphabetically" do
      expect(state_store.registerable_lead_providers).to eq(course_cohort.lead_providers.alphabetical)
    end

    it "excludes providers of other courses" do
      other_provider = create(:lead_provider)
      create(:course_cohort, course: create(:course), cohort: create(:cohort, :current, registration_starts_at: 2.days.ago.to_date), lead_provider: other_provider)

      expect(state_store.registerable_lead_providers).not_to include(other_provider)
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

  describe "funding answers" do
    it "reads the work setting" do
      state_store.write(work_setting: "other")

      expect(state_store.work_setting).to eq("other")
    end

    it "reads the funding choice" do
      state_store.write(funding: "self")

      expect(state_store.funding).to eq("self")
    end
  end

  describe "#institution" do
    let(:institution) { create(:institution) }

    it "is the picked institution" do
      state_store.write(institution_id: institution.id.to_s)

      expect(state_store.institution).to eq(institution)
    end

    it "is nil when nothing was picked" do
      expect(state_store.institution).to be_nil
    end

    it "is nil when other was picked" do
      state_store.write(institution_id: "other")

      expect(state_store.institution).to be_nil
    end
  end

  describe "#funding_eligibility_result" do
    let(:rule_set) { instance_double(FundingEligibilities::StateFundedSchool, evaluate: :funded) }

    before { allow(FundingEligibilities).to receive(:for_course).with(course).and_return(rule_set) }

    it "is the result of the course rule set" do
      expect(state_store.funding_eligibility_result).to eq(:funded)
    end

    it "is evaluated once for the same answers" do
      2.times { state_store.funding_eligibility_result }

      expect(rule_set).to have_received(:evaluate).once
    end

    it "is evaluated again when the answers change" do
      state_store.funding_eligibility_result
      state_store.write(work_setting: "other")
      state_store.funding_eligibility_result

      expect(rule_set).to have_received(:evaluate).twice
    end
  end
end
