# frozen_string_literal: true

require "rails_helper"

RSpec.describe Applications::Accept, :with_default_schedules, type: :model do
  let(:params) do
    {
      application:,
    }
  end

  subject(:service) do
    described_class.new(params)
  end

  describe "#accept" do
    let(:trn) { rand(1_000_000..9_999_999).to_s }
    let(:user) { create(:user, :with_verified_trn) }
    let(:course) { create(:course, :tte_early_years) }
    let(:lead_provider) { create(:lead_provider) }
    let(:cohort) { create(:cohort, :current, :without_funding_cap) }
    let(:cohort_next) { create(:cohort, :next, :without_funding_cap) }

    let(:application) do
      create(
        :application,
        user:,
        course:,
        lead_provider:,
        cohort:,
      )
    end

    it "reloads application after action" do
      allow(service.application).to receive(:reload)
      service.accept
      expect(service.application).to have_received(:reload)
    end

    describe "validations" do
      it { is_expected.to validate_presence_of(:application).with_message("The entered '#/application' is missing from your request. Check details and try again.") }

      context "when the npq application is already accepted" do
        let(:application) { create(:application, :accepted) }

        it { is_expected.to have_error(:application, :has_already_been_accepted, "This NPQ application has already been accepted") }
      end

      context "when the npq application is rejected" do
        let(:application) { create(:application, :rejected) }

        it { is_expected.to have_error(:application, :cannot_change_from_rejected, "Once rejected an application cannot change state") }
      end

      context "when the existing data is invalid" do
        let(:application) { create(:application, cohort:, course:) }

        it "throws ActiveRecord::RecordInvalid" do
          application.lead_provider_id = nil
          expect { service.accept }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context "when user applies for Recption but has accepted Send", :npq do
      let(:course) { create(:course, :additional_support_offer, course_group: "send") }
      let(:other_course) { create(:course, :tte_early_years, course_group: "send") }

      let(:other_application) do
        create(
          :application,
          user:,
          course: other_course,
          lead_provider:,
          cohort:,
        )
      end

      before do
        service.accept
      end

      context "and the applications are in the same cohort" do
        it "does not accept the EHCO application" do
          expect {
            described_class.new(application: other_application).accept
          }.not_to(change { other_application.reload.lead_provider_approval_status })
        end
      end

      context "and the applications are in different cohorts" do
        let(:other_application) do
          create(
            :application,
            user:,
            course: other_course,
            lead_provider:,
            cohort: cohort_next,
          )
        end

        it "accepts the EHCO application" do
          expect {
            described_class.new(application: other_application).accept
          }.to(change { other_application.reload.lead_provider_approval_status }.to("accepted"))
        end
      end
    end

    context "when user has applied for the same course with another provider in a different cohort" do
      let(:other_lead_provider) { create(:lead_provider) }

      let(:other_application) do
        create(:application,
               user:,
               course:,
               lead_provider: other_lead_provider,
               cohort: cohort_next)
      end

      before do
        application.save!
        other_application.save!
      end

      it "does not reject other_application in different cohort" do
        service.accept
        expect(application.reload.lead_provider_approval_status).to eql("accepted")
        expect(application.reload.accepted_at).to be_within(1.minute).of(Time.zone.now)
        expect(service.application).to be_active_training_status

        other_application.reload
        expect(other_application.lead_provider_approval_status).to eql("pending")
      end
    end

    context "when accepting an application for a course that has already been accepted by another provider" do
      let(:other_lead_provider) { create(:lead_provider) }

      context "when the other npq applicaton belongs to the same participant in a different cohort" do
        let(:other_application) do
          create(:application,
                 user:,
                 course:,
                 lead_provider: other_lead_provider,
                 cohort: cohort_next)
        end

        let(:params) do
          {
            application: other_application,
          }
        end

        before do
          application.update!(lead_provider_approval_status: "accepted")
        end

        it "allows both applications to be accepted when in different cohorts" do
          expect { service.accept }.to change { other_application.reload.lead_provider_approval_status }.to("accepted")
        end

        context "when one of the applications is withdrawn" do
          let(:application) do
            create(
              :application,
              :withdrawn,
              user:,
              course:,
              lead_provider:,
              cohort:,
            )
          end

          it "allows the other application to be accepted" do
            expect { service.accept }.to change { other_application.reload.lead_provider_approval_status }.to("accepted")
          end
        end
      end

      context "when the other npq applicaton belongs to a different user but with the same teacher profile TRN" do
        let(:another_user) { create(:user, :with_verified_trn, trn: user.trn) }

        let(:other_application) do
          create(:application,
                 user: another_user,
                 course:,
                 lead_provider: other_lead_provider,
                 cohort:)
        end

        let(:params) do
          {
            application: other_application,
          }
        end

        before do
          application.update!(lead_provider_approval_status: "accepted")
        end

        context "when both applications are in the same cohort" do
          it "does not allow 2 applications with same course and cohort to be accepted" do
            expect {
              service.accept
            }.not_to(change { other_application.reload.lead_provider_approval_status })
          end

          it "attaches errors to the object" do
            service.accept
            expect(service).to have_error(:application, :has_another_accepted_application, "The participant has already had an application accepted for this course.")
          end
        end

        context "when the applications are in different cohorts" do
          let(:other_application) do
            create(:application,
                   user: another_user,
                   course:,
                   lead_provider: other_lead_provider,
                   cohort: cohort_next)
          end

          it "allows both applications to be accepted" do
            expect { service.accept }.to change { other_application.reload.lead_provider_approval_status }.to("accepted")
          end
        end

        context "when one of the applications is withdrawn" do
          let(:application) do
            create(
              :application,
              :withdrawn,
              user:,
              course:,
              lead_provider:,
              cohort:,
            )
          end

          it "allows the other application to be accepted" do
            expect { service.accept }.to change { other_application.reload.lead_provider_approval_status }.to("accepted")
          end
        end
      end
    end

    context "when user has applied for different course", :npq do
      let(:other_lead_provider) { create(:lead_provider) }
      let(:other_course) { create(:course, :early_years_leadership) }

      let(:other_application) do
        create(:application,
               user:,
               course: other_course,
               lead_provider: other_lead_provider,
               cohort:)
      end

      before do
        application.save!
        other_application.save!
      end

      it "does not reject the other course" do
        service.accept
        expect(application.reload.lead_provider_approval_status).to eql("accepted")
        expect(application.reload.accepted_at).to be_within(1.minute).of(Time.zone.now)
        expect(service.application).to be_active_training_status
        expect(other_application.reload.lead_provider_approval_status).to eql("pending")
      end
    end

    context "when application has already been rejected" do
      before do
        application.lead_provider_approval_status = "rejected"
        application.save!
      end

      it "cannot then be accepted" do
        service.accept
        expect(application.reload).to be_rejected_lead_provider_approval_status
        expect(service).to have_error(:application, :cannot_change_from_rejected, "Once rejected an application cannot change state")
      end
    end

    context "when applying for 2022" do
      let!(:application) do
        create(:application,
               user:,
               course:,
               lead_provider:,
               cohort: cohort_next)
      end

      context "when there is a previous cohort pending application" do
        let!(:previous_application) do
          create(:application,
                 user:,
                 course:,
                 lead_provider:,
                 cohort:)
        end

        it "does not affect 2021 application" do
          expect {
            service.accept
          }.to change { application.reload.lead_provider_approval_status }
           .and(not_change { previous_application.reload.lead_provider_approval_status })
        end
      end
    end

    describe "NPQ capping" do
      let(:cohort) { create(:cohort, :current, :with_funding_cap) }

      before do
        application.update!(eligible_for_funding: true)
      end

      context "when funded_place is true" do
        let(:params) { { application:, funded_place: true } }

        it "sets the funded place to true" do
          service.accept

          expect(application.reload.funded_place).to be_truthy
        end

        it "does not set funded place if eligible for funding is false" do
          application.update!(eligible_for_funding: false)
          expect(service).to have_error(:application, :not_eligible_for_funded_place, "The participant is not eligible for funding, so '#/funded_place' cannot be set to true.")
        end
      end

      context "when funded_place is false" do
        let(:params) { { application:, funded_place: false } }

        it "sets the funded place to false" do
          service.accept

          expect(application.reload.funded_place).to be_falsey
        end
      end

      context "when funded_place is nil" do
        let(:params) { { application:, funded_place: nil } }

        context "when funding_cap is true" do
          it "returns funded_place is required error" do
            service.accept
            expect(service).to have_error(:funded_place, :inclusion, "Set '#/funded_place' to true or false.")
          end
        end

        context "when funding_cap is false" do
          let(:cohort) { create(:cohort, :current, :without_funding_cap) }

          it "does not validate funded_place" do
            service.accept
            expect(service.errors.messages_for(:funded_place)).to be_empty
          end
        end
      end

      context "when funded_place is a string" do
        context "when funded_place is `true`" do
          let(:params) { { application:, funded_place: "true" } }

          it "returns funded_place is required error" do
            service.accept
            expect(service).to have_error(:funded_place, :inclusion, "Set '#/funded_place' to true or false.")
          end
        end

        context "when funded_place is `false`" do
          let(:params) { { application:, funded_place: "false" } }

          it "returns funded_place is required error" do
            service.accept
            expect(service).to have_error(:funded_place, :inclusion, "Set '#/funded_place' to true or false.")
          end
        end

        context "when funded_place is `null`" do
          let(:params) { { application:, funded_place: "null" } }

          it "returns funded_place is required error" do
            service.accept
            expect(service).to have_error(:funded_place, :inclusion, "Set '#/funded_place' to true or false.")
          end
        end

        context "when funded_place is an empty string" do
          let(:params) { { application:, funded_place: "" } }

          it "returns funded_place is required error" do
            service.accept
            expect(service).to have_error(:funded_place, :inclusion, "Set '#/funded_place' to true or false.")
          end
        end
      end
    end
  end
end
