# frozen_string_literal: true

require "rails_helper"

RSpec.describe Applications::ChangeFundedPlace, type: :model do
  subject(:service) { described_class.new(params) }

  let(:params) do
    {
      application:,
      funded_place:,
    }
  end

  let(:application) { create(:application, :accepted, lead_provider:, course_cohort:) }
  let(:funded_place) { true }
  let(:lead_provider) { create(:lead_provider) }
  let(:course_cohort) { create(:course_cohort, lead_provider:) }

  describe "#change happy path" do
    context "when application eligible for funding" do
      let(:application) do
        create(:application,
               :accepted,
               lead_provider:,
               course_cohort:,
               eligible_for_funding: true,
               funded_place: true)
      end

      context "with funded place" do
        let(:funded_place) { true }

        it "no application record changes" do
          expect { service.change }.not_to(change { application.reload.funded_place })
        end
      end

      context "without funded place" do
        let(:funded_place) { false }

        it "updates application record" do
          expect { service.change }.to change { application.reload.funded_place }.from(true).to(false)
        end
      end
    end

    context "when application not eligible for funding" do
      let(:application) do
        create(:application,
               :accepted,
               lead_provider:,
               course_cohort:,
               eligible_for_funding: false,
               funded_place: false)
      end

      context "with funded place" do
        let(:funded_place) { true }

        it "bad request error" do
          expect { service.change }.not_to(change { application.reload.funded_place })
        end
      end

      context "without funded place" do
        let(:funded_place) { false }

        it "no application record changes" do
          expect { service.change }.not_to(change { application.reload.funded_place })
        end
      end
    end
  end

  describe "#change errors scenarios" do
    before { service.change }

    context "when application is missing" do
      it { is_expected.to validate_presence_of(:application).with_message("The entered '#/application' is missing from your request. Check details and try again.") }
    end

    context "when application is in any other status than `accepted`" do
      let(:application) { create(:application, lead_provider:, course_cohort:) }

      it "returns an error" do
        expect(service).to have_error(
          :application,
          :cannot_change_funded_status_from_non_accepted,
          "You must accept the application before attempting to change the '#/funded_place' setting.",
        )
      end
    end

    context "when application is not eligible for funding" do
      let(:application) { create(:application, lead_provider:, course_cohort:, eligible_for_funding: false) }

      it "returns an error" do
        expect(service).to have_error(
          :application,
          :cannot_change_funded_status_non_eligible,
          "This participant is not eligible for funding. Contact us if you think this is wrong.",
        )
      end
    end

    context "when application training has started (application with status `started` and beyond)" do
      let(:application) do
        create(:application,
               :accepted,
               :with_declaration,
               lead_provider:,
               course_cohort:,
               eligible_for_funding: true,
               funded_place: true)
      end

      it "returns an error" do
        expect(service).to have_error(
          :application,
          :cannot_change_funded_place,
          "You cannot change the funded place because declarations have been submitted." \
          " You will need to void the existing declarations and resubmit them after changing the funded place.",
        )
      end
    end
  end
end
