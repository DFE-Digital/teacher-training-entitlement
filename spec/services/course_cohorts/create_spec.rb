# frozen_string_literal: true

require "rails_helper"

RSpec.describe CourseCohorts::Create, type: :model do
  subject(:service) do
    described_class.new(
      cohort:,
      course:,
      training_dates:,
      lead_providers:,
    )
  end

  let(:cohort) { create(:cohort, :next) }
  let!(:course) { create(:course) }
  let(:training_dates) { { start: Date.new(2025, 9, 1), end: nil } }
  let!(:lead_provider) { create(:lead_provider) }
  let(:lead_providers) do
    [
      [
        lead_provider,
        {
          "id" => lead_provider.id.to_s,
          "teacher_funding" => "1000",
          "recruitment_target" => "50",
        },
      ],
    ]
  end

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
      it "creates a course cohort for the given cohort and course" do
        expect { service.call }.to change(CourseCohort, :count).by(1)

        expect(cohort.course_cohorts.find_by(course:)).to be_present
      end

      it "sets the academic_year to the cohort's start_year" do
        service.call

        expect(service.course_cohort.academic_year).to eq(cohort.start_year)
      end

      it "sets service.course_cohort to the created record" do
        service.call
        expect(service.course_cohort).to eq(cohort.course_cohorts.find_by(course:))
      end

      context "when training_starts_at falls in autumn" do
        let(:training_dates) { { start: Date.new(2025, 9, 1), end: nil } }

        it "sets the term_identifier to autumn" do
          service.call

          expect(service.course_cohort.term_identifier).to eq("autumn")
        end
      end

      context "when training_starts_at falls in spring" do
        let(:training_dates) { { start: Date.new(2025, 2, 1), end: nil } }

        it "sets the term_identifier to spring" do
          service.call

          expect(service.course_cohort.term_identifier).to eq("spring")
        end
      end

      it "creates a started milestone with the given training_starts_at" do
        expect { service.call }.to change(Milestone.started, :count).by(1)

        milestone = service.course_cohort.milestones.started.sole
        expect(milestone.acceptance_window_start_date).to eq(training_dates[:start])
      end

      context "when training_ends_at is present" do
        let(:training_dates) { { start: Date.new(2025, 9, 1), end: Date.new(2026, 3, 1)} }

        it "creates a completed milestone" do
          expect { service.call }.to change(Milestone.completed, :count).by(1)
          milestone = service.course_cohort.milestones.completed.sole
          expect(milestone.acceptance_window_start_date).to be_present
          expect(milestone.acceptance_window_end_date).to eq(Date.new(2026, 3, 1))
        end
      end

      context "when training_ends_at is blank" do
        let(:training_dates) { { start: Date.new(2025, 9, 1), end: nil} }

        it "does not create a completed milestone" do
          expect { service.call }.not_to change(Milestone.completed, :count)
        end
      end

      it "creates a course cohort provider for the selected lead provider" do
        expect { service.call }.to change(CourseCohortProvider, :count).by(1)

        provider = service.course_cohort.course_cohort_providers.find_by(lead_provider:)
        expect(provider).to have_attributes(teacher_funding: 1000, recruitment_target: 50)
      end

      context "when teacher_funding and recruitment_target are blank strings" do
        let(:lead_providers) do
          [
            [
              lead_provider,
              {
                "id" => lead_provider.id.to_s,
                "teacher_funding" => "",
                "recruitment_target" => "",
              },
            ],
          ]
        end

        it "stores them as nil" do
          service.call

          provider = service.course_cohort.course_cohort_providers.find_by(lead_provider:)
          expect(provider.teacher_funding).to be_nil
          expect(provider.recruitment_target).to be_nil
        end
      end

      context "when the selected lead provider has delivery partners" do
        let(:delivery_partner) { create(:delivery_partner) }
        let(:lead_provider) { create(:lead_provider, delivery_partner:) }

        it "creates a delivery partnership linking the lead provider and delivery partner to the new course cohort" do
          expect { service.call }.to change(DeliveryPartnership, :count).by(1)

          partnership = service.course_cohort.delivery_partnerships.find_by(lead_provider:, delivery_partner:)
          expect(partnership).to be_present
        end
      end

      context "when there are multiple selected lead providers" do
        let(:other_lead_provider) { create(:lead_provider) }
        let(:lead_providers) do
          [
            [
              lead_provider,
              {
                "id" => lead_provider.id.to_s,
                "teacher_funding" => "",
                "recruitment_target" => "",
              },
            ],
            [
              other_lead_provider,
              {
                "id" => other_lead_provider.id.to_s,
                "teacher_funding" => "2000",
                "recruitment_target" => "100",
              },
            ],
          ]
        end

        it "creates a course cohort provider for each selected lead provider" do
          expect { service.call }.to change(CourseCohortProvider, :count).by(2)

          expect(service.course_cohort.course_cohort_providers.pluck(:lead_provider_id))
            .to contain_exactly(lead_provider.id, other_lead_provider.id)
        end
      end

      context "when a lead provider is present but not selected" do
        let(:unselected_lead_provider) { create(:lead_provider) }
        let(:another_unselected_lead_provider) { create(:lead_provider) }
        let(:lead_providers) { [] }

        it "does not create a course cohort provider for the unselected lead providers" do
          service.call

          course_cohort_providers = service.course_cohort.course_cohort_providers
          expect(course_cohort_providers.find_by(lead_provider: unselected_lead_provider)).to be_nil
          expect(course_cohort_providers.find_by(lead_provider: another_unselected_lead_provider)).to be_nil
        end
      end
    end
  end
end
