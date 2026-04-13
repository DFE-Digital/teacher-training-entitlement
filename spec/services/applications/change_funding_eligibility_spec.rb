# frozen_string_literal: true

require "rails_helper"

RSpec.describe Applications::ChangeFundingEligibility, type: :model do
  let(:eligible_for_funding) { false }
  let(:application) { create(:application, :accepted) }

  subject(:service) { described_class.new(application:, eligible_for_funding:) }

  before do
    allow(GenericMailer).to receive(:eligible_for_funding).and_call_original
  end

  describe "validations" do
    before { service.call }

    context "with application with billable declarations" do
      subject { service.tap(&:valid?).errors.full_messages }

      let(:service) { described_class.new(application:, eligible_for_funding: false) }

      let :application do
        create(:application, :accepted, eligible_for_funding: false).tap do |application|
          create(:declaration, :eligible, application:)
        end
      end

      it { is_expected.to eq [I18n.t("activemodel.errors.models.applications/change_funding_eligibility.attributes.base.declaration_exists")] }
    end

    context "with application with submitted declarations" do
      subject { service.tap(&:valid?).errors.full_messages }

      let(:service) { described_class.new(application:, eligible_for_funding: false) }

      let :application do
        create(:application, :accepted, eligible_for_funding: false).tap do |application|
          create(:declaration, :submitted, application:)
        end
      end

      it { is_expected.to eq [I18n.t("activemodel.errors.models.applications/change_funding_eligibility.attributes.base.declaration_exists")] }
    end

    context "with application with funded place" do
      subject { service.tap(&:valid?).errors.full_messages }

      let(:service) { described_class.new(application:, eligible_for_funding: false) }

      let :application do
        create(:application, :accepted, funded_place: true, eligible_for_funding: true)
      end

      it { is_expected.to include(/application is funded/i) }
    end

    context "when application was superceded" do
      let(:application) { build(:application, :superceded) }

      it { is_expected.to have_error(:application, :application_was_superceded, I18n.t("application.application_was_superceded")) }
    end
  end

  describe "#call" do
    context "with valid update from false to true" do
      let(:eligible_for_funding) { true }

      it do
        aggregate_failures do
          expect(GenericMailer).to receive(:with).with(
            to: application.user.email,
            full_name: application.user.full_name,
            provider_name: application.lead_provider.name,
            course_name: application.course.name,
            ecf_id: application.ecf_id,
          ).and_call_original

          service.call

          expect(subject.errors).to be_blank
          expect(application.reload.eligible_for_funding).to be_truthy
          expect(application.funding_eligiblity_status_code).to eq("marked_funded_by_policy")
        end
      end
    end

    context "with valid update from true to false" do
      let(:eligible_for_funding) { false }
      let(:application) { create(:application, :pending, :eligible_for_funding, funded_place: false) }

      it do
        aggregate_failures do
          expect(GenericMailer).not_to receive(:eligible_for_funding)

          service.call

          expect(subject.errors).to be_blank
          expect(application.reload.eligible_for_funding).to be_falsey
          expect(application.funding_eligiblity_status_code).to eq("marked_ineligible_by_policy")
        end
      end
    end

    context "with a valid update from true to true" do
      let(:application) { create(:application, :pending, :eligible_for_funding) }

      let(:eligible_for_funding) { true }

      it do
        aggregate_failures do
          expect(GenericMailer).not_to receive(:eligible_for_funding)

          service.call

          expect(subject.errors).to be_blank
          expect(application.reload.eligible_for_funding).to be_truthy
          expect(application.funding_eligiblity_status_code).to eq("marked_funded_by_policy")
        end
      end
    end
  end
end
