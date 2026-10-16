require "rails_helper"

RSpec.describe LeadProvider do
  describe "relationships" do
    it { is_expected.to have_many(:applications) }
    it { is_expected.to have_many(:statements) }
    it { is_expected.to have_many(:delivery_partnerships) }
    it { is_expected.to have_many(:delivery_partners).through(:delivery_partnerships) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF ID must be unique").allow_nil }
  end

  describe "#delivery_partners_for_course_cohort" do
    subject { lead_provider.delivery_partners_for_course_cohort(course_cohort:) }

    let(:course) { create(:course) }
    let(:course_cohort) { create(:course_cohort, course:) }
    let(:other_course_cohort) { create(:course_cohort, course: create(:course)) }
    let(:course_cohort_partner) { create(:delivery_partner) }
    let(:other_course_cohort_partner) { create(:delivery_partner) }
    let(:lead_provider) do
      create(:lead_provider, delivery_partners: {
        course => course_cohort_partner,
        other_course_cohort.course => other_course_cohort_partner,
      })
    end

    before { create(:course_cohort_provider, course_cohort:, lead_provider:) }

    it { is_expected.to contain_exactly(course_cohort_partner) }

    context "when the course has several course cohorts" do
      let(:other_cohort) { create(:cohort, registration_starts_at: Date.new(2024, 5, 1)) }
      let(:other_course_cohort_same_course) { create(:course_cohort, course:, cohort: other_cohort) }

      before { create(:course_cohort_provider, course_cohort: other_course_cohort_same_course, lead_provider:) }

      it "lists the partner for every course cohort of the course" do
        expect(lead_provider.delivery_partners_for_course_cohort(course_cohort: other_course_cohort_same_course))
          .to contain_exactly(course_cohort_partner)
      end
    end

    context "when the lead provider has no course cohort provider for the cohort" do
      subject { lead_provider.delivery_partners_for_course_cohort(course_cohort: course_cohort_without_provider) }

      let(:course_cohort_without_provider) { create(:course_cohort, course:, cohort: create(:cohort, registration_starts_at: Date.new(2024, 5, 1))) }

      before { course_cohort_without_provider.course_cohort_providers.delete_all }

      it { is_expected.to be_empty }
    end
  end
end
