# frozen_string_literal: true

require "rails_helper"

RSpec.describe CourseCohorts::Create, type: :model do
  subject(:service) do
    described_class.new(
      cohort:,
      course:,
      training_starts_at:,
    )
  end

  let(:cohort) { create(:cohort, :next) }
  let!(:course) { create(:course) }
  let(:training_starts_at) { Date.new(2025, 9, 1) }

  describe "validations" do
    it { is_expected.to be_valid }

    context "when course missing" do
      let(:course) { nil }

      it { is_expected.to be_invalid }
      it { expect(service).to have_error(:course, :blank) }
    end
  end

  describe "#call" do
    context "when the service is invalid" do
      let(:cohort) { nil }

      before { course }

      it "does not create a course cohort" do
        expect { service.call }.not_to change(CourseCohort, :count)
      end

      it "does not create any milestones" do
        expect { service.call }.not_to change(Milestone, :count)
      end

      it "does not create any course cohort providers" do
        expect { service.call }.not_to change(CourseCohortProvider, :count)
      end

      it "does not create any delivery partnerships" do
        expect { service.call }.not_to change(DeliveryPartnership, :count)
      end

      it "returns nil" do
        expect(service.call).to be_nil
      end
    end

    context "when the service is valid" do
      let(:lead_provider) { create(:lead_provider) }

      before do
        create(
          :contract_year,
          :generic,
          course:,
          lead_provider:,
          teacher_funding: 650,
          recruitment_target: 3000,
        )
      end

      it "creates a course cohort for the given cohort and course" do
        expect { service.call }.to change(CourseCohort, :count).by(1)

        expect(cohort.course_cohorts.find_by(course:)).to be_present
      end

      it "sets the academic_year from the cohort registration start date" do
        service.call

        expect(service.course_cohort.academic_year).to eq(CourseCohort.academic_year_for(cohort.registration_starts_at))
      end

      it "sets service.course_cohort to the created record" do
        service.call

        expect(service.course_cohort).to eq(cohort.course_cohorts.find_by(course:))
      end

      it "sets the training start date" do
        service.call

        expect(service.course_cohort.training_starts_at).to eq(training_starts_at)
      end

      context "when training_starts_at falls in autumn" do
        let(:training_starts_at) { Date.new(2025, 9, 1) }
        let(:cohort) { create(:cohort, registration_starts_at: Date.new(2025, 9, 1)) }

        it "sets the term_identifier to autumn" do
          service.call

          expect(service.course_cohort.term_identifier).to eq("autumn")
        end
      end

      context "when training_starts_at falls in spring" do
        let(:training_starts_at) { Date.new(2025, 2, 1) }
        let(:cohort) { create(:cohort, registration_starts_at: Date.new(2025, 2, 1)) }

        it "sets the term_identifier to spring" do
          service.call

          expect(service.course_cohort.term_identifier).to eq("spring")
        end
      end

      it "does not create a milestone" do
        expect { service.call }.not_to change(Milestone.started, :count)
      end

      context "when training_starts_at is blank" do
        let(:training_starts_at) { nil }

        it "does not create a completed milestone" do
          expect { service.call }.not_to change(Milestone.completed, :count)
        end
      end

      it "creates a course cohort provider from the generic contract year template" do
        expect { service.call }.to change(CourseCohortProvider, :count).by(1)

        provider = service.course_cohort.course_cohort_providers.find_by(lead_provider:)
        expect(provider).to have_attributes(teacher_funding: 650, recruitment_target: 3000)
      end

      context "when the contract year lead provider has delivery partners" do
        let(:delivery_partner) { create(:delivery_partner) }
        let(:lead_provider) { create(:lead_provider, delivery_partner:) }

        it "creates a delivery partnership linking the lead provider and delivery partner to the new course cohort" do
          expect { service.call }.to change(DeliveryPartnership, :count).by(1)

          partnership = service.course_cohort.delivery_partnerships.find_by(lead_provider:, delivery_partner:)
          expect(partnership).to be_present
        end
      end
    end
  end
end
