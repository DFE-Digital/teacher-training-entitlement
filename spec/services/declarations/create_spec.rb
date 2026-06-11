# frozen_string_literal: true

require "rails_helper"

RSpec.describe Declarations::Create, type: :model do
  subject(:service) { described_class.new(**params) }

  let(:params) do
    {
      application:,
      declaration_type:,
      declaration_date: declaration_date.rfc3339,
      has_passed:,
      delivery_partner_id:,
      secondary_delivery_partner_id:,
    }
  end
  let(:application) { create(:application, :accepted, course_cohort:, lead_provider:) }
  let(:declaration_date) { schedule.training_starts_at + 1.hour }
  let(:course_cohort) { create(:course_cohort, schedule:) }
  let(:lead_provider) { create(:lead_provider) }
  let(:schedule) { create(:schedule, training_starts_at: 1.day.ago, training_ends_at: 1.day.from_now) }
  let(:has_passed) { true }
  let(:delivery_partner_id) do
    create(:delivery_partner, lead_providers: { course_cohort.cohort => lead_provider }).ecf_id
  end
  let(:secondary_delivery_partner_id) do
    create(:delivery_partner, lead_providers: { course_cohort.cohort => lead_provider }).ecf_id
  end

  RSpec.shared_examples "does not update the application" do
    it do
      expect { service.call }
        .to not_change(ApplicationEvent, :count)
        .and not_change(application, :status)
    end
  end

  describe "started declaration" do
    let(:declaration_type) { "started" }
    let(:params) do
      {
        application:,
        declaration_type:,
        declaration_date: declaration_date.rfc3339,
        delivery_partner_id:,
        secondary_delivery_partner_id:,
      }
    end

    describe "happy paths" do
      it { expect { service.call }.to change(Declaration, :count).by(1) }

      describe "created started declaration" do
        let(:declaration) { service.declaration }

        before { service.call }

        it { expect(declaration.declaration_type).to eq(declaration_type) }
        it { expect(declaration.application).to eq(application) }
        it { expect(declaration.declaration_date).to eq(declaration_date) }
        it { expect(declaration.lead_provider).to eq(application.lead_provider) }
        it { expect(declaration.cohort).to eq(application.cohort) }
        it { expect(declaration.delivery_partner.ecf_id).to eq(delivery_partner_id) }
        it { expect(declaration.secondary_delivery_partner.ecf_id).to eq(secondary_delivery_partner_id) }

        it "sets the application to started" do
          expect(application.reload).to be_started_status
          expect(application.state_changes.last&.event).to eq(Application::STARTED)
        end
      end

      it "does not create an participant outcome" do
        expect { service.call }.not_to change(ParticipantOutcome, :count)
      end

      it "creates a statement when none exists"

      context "when secondary delivery partner omitted" do
        let(:secondary_delivery_partner_id) { nil }

        before { service.call }

        it { expect(service.declaration.secondary_delivery_partner).to be_nil }
      end

      context "when application has a voided started declaration" do
        let(:application) do
          create(:application, :accepted, :with_declaration, course_cohort:, lead_provider:)
        end

        before { application.declarations.where(declaration_type:).first.mark_voided! }

        it { expect { service.call }.to change(Declaration, :count).by(1) }
      end
    end

    describe "error scenarios" do
      context "when application already started" do
        before { application.update_column(:status, :started) }

        it { is_expected.to have_error(:application, :not_startable) }
      end

      context "when delivery_partner_id is omitted" do
        let(:delivery_partner_id) { nil }

        it { is_expected.to validate_param(:delivery_partner_id).with_message("The property '#/delivery_partner_id' is missing") }
      end

      context "when application receives `completed declaration` before `started declaration`" do
        let(:declaration_type) { "completed" }

        it { is_expected.to validate_param(:declaration_type).with_message("A completed declaration cannot be submitted before a started declaration.") }
      end

      context "when application already has a started declaration" do
        let(:application) { create(:application, :accepted, :with_declaration, course_cohort:, lead_provider:) }

        it { is_expected.to validate_param(:base).with_message("A declaration has already been submitted that will be, or has been, paid for this event") }
      end

      context "when application declaration-date is before schedule.training_start date" do
        let(:declaration_date) { schedule.training_starts_at - 1.hour }

        it { is_expected.to validate_param(:declaration_date).with_message("Enter a '#/declaration_date' that's on or after the schedule start.") }
      end

      context "when delivery-partner is not found" do
        let(:delivery_partner_id) { "bad-id" }

        it { is_expected.to validate_param(:delivery_partner_id).with_message("The property '#/delivery_partner_id' does not exist") }
      end

      context "when secondary delivery partner is not found" do
        let(:secondary_delivery_partner_id) { "bad-id" }

        it { is_expected.to validate_param(:secondary_delivery_partner_id).with_message("The property '#/secondary_delivery_partner_id' does not exist") }
      end
    end
  end

  describe "completed declaration" do
    let(:declaration_type) { "completed" }
    let!(:application) do
      create(:application, :started, :with_declaration, course_cohort:, lead_provider:)
    end

    describe "happy paths" do
      it { expect { service.call }.to change(Declaration, :count).by(1) }
      it { expect { service.call }.to change(ParticipantOutcome, :count).by(1) }

      it "creates a statement when none exists"

      context "when application has a voided completed declaration" do
        before do
          application.declarations << create(:declaration, :voided, declaration_type:, application:)
        end

        it "sets the application to completed" do
          service.call

          expect(application.reload).to be_completed_status
          expect(application.state_changes.last&.event).to eq(Application::COMPLETED)
        end

        it { expect { service.call }.to change(Declaration, :count).by(1) }
      end

      context "when the application has resumed in a different cohort" do
        let(:resume_cohort) { create(:cohort, suffix: "b") }
        let(:course_cohort) { create(:course_cohort, cohort: resume_cohort) }
        let(:started_declaration) { application.declarations.started_declaration_type.first }
        let(:started_cohort) { started_declaration.cohort }
        let(:delivery_partner_id) do
          create(:delivery_partner,
                 lead_providers: {
                   started_cohort => lead_provider,
                   resume_cohort => lead_provider,
                 }).ecf_id
        end
        let(:secondary_delivery_partner_id) do
          create(:delivery_partner,
                 lead_providers: {
                   started_cohort => lead_provider,
                   resume_cohort => lead_provider,
                 }).ecf_id
        end

        before do
          application.update!(course_cohort:)
        end

        it "uses the started declaration cohort" do
          expect { service.call }.to change(Declaration, :count).by(1)
          expect(service.declaration.cohort).to eq(started_declaration.cohort)
        end
      end
    end

    describe "error scenarios" do
      context "when application already completed" do
        before { application.update_column(:status, :completed) }

        it { is_expected.to have_error(:application, :not_completable) }
      end

      context "when application already have a completed declaration" do
        before do
          application.declarations << create(:declaration, :eligible, declaration_type:, application:)
        end

        it { is_expected.to validate_param(:base).with_message("A declaration has already been submitted that will be, or has been, paid for this event") }

        it_behaves_like "does not update the application"
      end

      context "when application `has_passed` field has wrong value" do
        let(:has_passed) { "bad-value" }
        let(:error_message) { "Enter 'true' or 'false' in the '#/has_passed' field to indicate whether this participant has passed or failed their course." }

        it { is_expected.to validate_presence_of(:has_passed).with_message(error_message) }
      end
    end
  end

  describe "common error scenarios" do
    let(:declaration_type) { "started" }

    context "when application missing" do
      let(:application) { nil }

      it { is_expected.to validate_presence_of(:application).with_message("The entered '#/application' is missing from your request. Check details and try again.") }
    end

    context "when application has status different from `accepted`" do
      context "when pending" do
        let(:application) { create(:application, :pending, course_cohort:, lead_provider:) }

        it { is_expected.to validate_param(:application).with_message("The application current state does not allow declaration creation.") }

        it_behaves_like "does not update the application"
      end

      context "when rejected" do
        let(:application) { create(:application, :rejected, course_cohort:, lead_provider:) }

        it { is_expected.to validate_param(:application).with_message("The application current state does not allow declaration creation.") }

        it_behaves_like "does not update the application"
      end

      context "when deferred" do
        let(:application) { create(:application, :deferred, course_cohort:, lead_provider:) }

        it { is_expected.to validate_param(:application).with_message("The application current state does not allow declaration creation.") }

        it_behaves_like "does not update the application"
      end

      context "when withdrawn" do
        let(:application) { create(:application, :withdrawn, course_cohort:, lead_provider:) }

        it { is_expected.to validate_param(:application).with_message("The application current state does not allow declaration creation.") }

        it_behaves_like "does not update the application"
      end
    end

    context "when application declaration-type is wrong" do
      context "when value missing" do
        let(:declaration_type) { nil }

        it { is_expected.to validate_presence_of(:declaration_type).with_message("Enter a '#/declaration_type'.") }

        it_behaves_like "does not update the application"
      end

      context "when value unknown" do
        let(:declaration_type) { "foo" }

        it { is_expected.to validate_inclusion_of(:declaration_type).in_array(%w[started completed]).with_message("The entered '#/declaration_type' is not recognised.") }

        it_behaves_like "does not update the application"
      end
    end
  end
end
