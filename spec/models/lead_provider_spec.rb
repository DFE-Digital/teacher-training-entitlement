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

  describe "#cohort_start_years_by_delivery_partner" do
    subject(:years_by_partner) { lead_provider.cohort_start_years_by_delivery_partner }

    let(:lead_provider) { create(:lead_provider) }
    let(:course) { create(:course) }
    let(:cohort_2023) { create(:cohort, registration_starts_at: Date.new(2023, 9, 1)) }
    let(:cohort_2024) { create(:cohort, registration_starts_at: Date.new(2024, 9, 1)) }
    let!(:delivery_partner) { create(:delivery_partner, lead_providers: { course => lead_provider }) }

    before do
      create(:course_cohort, course:, cohort: cohort_2024, lead_provider:)
      create(:course_cohort, course:, cohort: cohort_2023, lead_provider:)
    end

    it "maps each delivery partner to its provided academic years" do
      expect(years_by_partner).to eq(delivery_partner.id => [2023, 2024])
    end

    context "when several of the partner's courses share an academic year" do
      let(:other_course) { create(:course) }

      before do
        create(:course_cohort, course: other_course, cohort: cohort_2023, lead_provider:)
        create(:delivery_partnership, delivery_partner:, course: other_course, lead_provider:)
      end

      it "lists the year once, sorted" do
        expect(years_by_partner[delivery_partner.id]).to eq([2023, 2024])
      end
    end

    context "when the partner has no provided cohorts" do
      let(:unprovided_course) { create(:course) }
      let!(:unprovided_partner) { create(:delivery_partner, lead_providers: { unprovided_course => lead_provider }) }

      before { create(:course_cohort, course: unprovided_course, cohort: cohort_2023, lead_provider: create(:lead_provider)) }

      it "omits the partner from the map" do
        expect(years_by_partner).not_to have_key(unprovided_partner.id)
      end
    end

    context "when the cohort is provided by another lead provider" do
      let(:other_lead_provider) { create(:lead_provider) }
      let(:other_course) { create(:course) }
      let!(:other_partner) { create(:delivery_partner, lead_providers: { other_course => lead_provider }) }

      before { create(:course_cohort, course: other_course, cohort: cohort_2023, lead_provider: other_lead_provider) }

      it "excludes the other lead provider's cohorts" do
        expect(years_by_partner).not_to have_key(other_partner.id)
      end
    end
  end
end
