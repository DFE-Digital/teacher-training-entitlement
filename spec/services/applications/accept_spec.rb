# frozen_string_literal: true

require "rails_helper"

RSpec.describe Applications::Accept, :with_default_schedules, type: :model do
  subject(:service) { described_class.new(params) }

  let(:params) do
    {
      application:,
      funded_place:,
    }
  end

  let(:application) { create(:application, lead_provider:, course_cohort:) }
  let(:funded_place) { true }
  let(:lead_provider) { create(:lead_provider) }
  let(:course_cohort) { create(:course_cohort, lead_provider:) }

  describe "#accept happy path" do
    context "when application eligible for funding" do
      let(:application) { create(:application, lead_provider:, course_cohort:, eligible_for_funding: true) }

      context "with funded place" do
        let(:funded_place) { true }

        it "updates application record" do
          expect(service.call).to be true

          expect(service.application.status).to eq(Application::ACCEPTED)
          expect(service.funded_place).to be true
        end

        it "creates applications state" do
          expect { service.call }.to change(ApplicationEvent, :count).by(1)
        end
      end

      context "without funded place" do
        let(:funded_place) { false }

        it "updates application record" do
          expect(service.call).to be true

          expect(service.application.status).to eq(Application::ACCEPTED)
          expect(service.funded_place).to be false
        end

        it "creates applications state" do
          expect { service.call }.to change(ApplicationEvent, :count).by(1)
        end
      end
    end

    context "when application not eligible for funding" do
      let(:application) { create(:application, lead_provider:, course_cohort:, eligible_for_funding: false) }

      context "with funded place" do
        let(:funded_place) { true }

        it "bad request error" do
          expect(service.call).to be false

          expect(service.application.status).to eq(Application::PENDING)
        end

        it "does not create applications state" do
          expect { service.call }.not_to change(ApplicationEvent, :count)
        end
      end

      context "without funded place" do
        let(:funded_place) { false }

        it "updates application record" do
          expect(service.call).to be true

          expect(service.application.status).to eq(Application::ACCEPTED)
          expect(service.application.eligible_for_funding).to be false
          expect(service.funded_place).to be false
        end

        it "creates applications state" do
          expect { service.call }.to change(ApplicationEvent, :count).by(1)
        end
      end
    end
  end

  describe "#accept errors scenarios" do
    context "when application missing" do
      let(:application) { nil }

      it { expect(service.call).to be false }
    end

    context "with bad funded place value" do
      let(:funded_place) { "something else" }

      it { expect(service.call).to be false }
      it { expect(service.application.status).to eq(Application::PENDING) }
    end

    context "when application already accepted" do
      let(:application) { create(:application, :accepted, lead_provider:, course_cohort:) }

      it { expect(service.call).to be false }
      it { expect(service.application.status).to eq(Application::ACCEPTED) }
    end

    context "when application already rejected" do
      let(:application) { create(:application, :rejected, lead_provider:, course_cohort:) }

      it { expect(service.call).to be false }
      it { expect(service.application.status).to eq(Application::REJECTED) }
    end

    context "when application cannot transition to accepted" do
      let(:application) { create(:application, :completed, :eligible_for_funding, lead_provider:, course_cohort:) }

      it { expect(service.call).to be false }
      it { is_expected.to have_error(:application, :invalid_status_transition) }
      it { expect { service.call }.not_to change(application.reload, :status) }
    end
  end
end
