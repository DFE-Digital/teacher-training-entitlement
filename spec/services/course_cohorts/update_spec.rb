# frozen_string_literal: true

require "rails_helper"

RSpec.describe CourseCohorts::Update, type: :model do
  subject(:service) do
    described_class.new(
      course_cohort:,
      selected_lead_providers:,
    )
  end

  let(:course_cohort_provider) { create(:course_cohort_provider) }
  let(:course_cohort) { course_cohort_provider.course_cohort }
  let(:lead_provider) { course_cohort_provider.lead_provider }
  let(:new_lead_provider) { create(:lead_provider) }
  let(:selected_lead_providers) do
    [
      [
        lead_provider,
        {
          "id" => lead_provider.id.to_s,
          "teacher_funding" => "1000",
          "recruitment_target" => "50",
        },
      ],
      [
        new_lead_provider,
        {
          "id" => new_lead_provider.id.to_s,
          "teacher_funding" => "33",
          "recruitment_target" => "880",
        },
      ],
    ]
  end

  describe "validations" do
    it { is_expected.to be_valid }

    context "when course_cohort missing" do
      let(:course_cohort) { nil }

      it { is_expected.to be_invalid }
      it { expect(service).to have_error(:course_cohort, :blank) }
    end
  end

  describe "#call" do
    context "when the service is invalid" do
      let(:course_cohort) { nil }

      it "service has errors" do
        service.call
        expect(service.errors).to be_present
      end
    end

    context "when the service is valid" do
      it "creates a course cohort providers" do
        expect { service.call }.to change(course_cohort.course_cohort_providers, :count).by(1)

        existing_ccp = course_cohort.course_cohort_providers.detect { |a| a.lead_provider == lead_provider }
        new_ccp = course_cohort.course_cohort_providers.detect { |a| a.lead_provider == new_lead_provider }

        expect(existing_ccp.teacher_funding).to eq(1000)
        expect(existing_ccp.recruitment_target).to eq(50)

        expect(new_ccp.teacher_funding).to eq(33)
        expect(new_ccp.recruitment_target).to eq(880)
      end
    end
  end
end
