require "rails_helper"

RSpec.describe Admin::LeadProviderShowQuery do
  subject(:service) { described_class.new(lead_provider:, cohort:) }

  let(:lead_provider) { create(:lead_provider) }
  let(:other_lead_provider) { create(:lead_provider) }
  let(:cohort) { create(:cohort, registration_starts_at: Date.new(2024, 9, 1)) }
  let(:course) { create(:course) }
  let(:course_cohort) { create(:course_cohort, course:, cohort:) }
  let!(:delivery_partner) { create(:delivery_partner, lead_providers: { course => lead_provider }) }
  let(:other_delivery_partner) { create(:delivery_partner, lead_providers: { course => other_lead_provider }) }

  before do
    course_cohort
    other_delivery_partner
  end

  describe "#call" do
    before { service.call }

    it "returns the lead provider's delivery partners for the partnership's course" do
      expect(service.details[:delivery_partners]).to contain_exactly(delivery_partner)
    end

    context "when filtering by academic year and the course has several cohorts in that year" do
      subject(:service) { described_class.new(lead_provider:, academic_year: cohort.start_year) }

      before do
        create(:course_cohort, course:, cohort: create(:cohort, registration_starts_at: Date.new(2024, 10, 1)))
        service.call
      end

      it "returns the delivery partner once" do
        expect(service.details[:delivery_partners]).to eq([delivery_partner])
      end
    end

    context "when a partnership is archived" do
      before do
        delivery_partner.delivery_partnerships.each(&:archive!)
        service.call
      end

      it "does not return the delivery partner" do
        expect(service.details[:delivery_partners]).to be_empty
      end
    end

    context "when the partner has an archived partnership and another lead provider has an active one on the same cohort" do
      let(:archived_partner) { create(:delivery_partner) }

      before do
        create(:delivery_partnership, delivery_partner: archived_partner, lead_provider:, course:, archived_at: 1.day.ago)
        create(:delivery_partnership, delivery_partner: archived_partner, lead_provider: other_lead_provider, course:)
        service.call
      end

      it "returns only the lead provider's active partners" do
        expect(service.details[:delivery_partners]).to contain_exactly(delivery_partner)
      end
    end

    context "when the partnership's course has no course cohort matching the filter" do
      subject(:service) { described_class.new(lead_provider:, cohort: other_cohort) }

      let(:other_cohort) { create(:cohort, registration_starts_at: Date.new(2022, 9, 1)) }

      it "returns no delivery partners" do
        expect(service.details[:delivery_partners]).to be_empty
      end
    end
  end
end
