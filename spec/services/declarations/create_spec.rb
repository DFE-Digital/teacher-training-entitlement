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
  let(:declaration_date) { started_milestone.acceptance_window_start_date + 1.hour }
  let(:course_cohort) { create(:course_cohort, schedule:) }
  let!(:started_milestone) { create(:milestone, :started, course_cohort:, acceptance_window_start_date: 2.days.ago) }
  let!(:completed_milestone) { create(:milestone, :completed, course_cohort:, acceptance_window_start_date: 1.day.ago) }
  let(:lead_provider) { create(:lead_provider) }
  let(:schedule) { create(:schedule, training_starts_at: 1.day.ago, training_ends_at: 1.day.from_now) }
  let(:has_passed) { true }
  let(:delivery_partner_id) do
    create(:delivery_partner, lead_providers: { course_cohort.cohort => lead_provider }).ecf_id
  end
  let(:secondary_delivery_partner_id) do
    create(:delivery_partner, lead_providers: { course_cohort.cohort => lead_provider }).ecf_id
  end
  let!(:statement) { create(:statement, lead_provider:) }

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

        context "when the application is DfE funded" do
          let(:application) { create(:application, :accepted, :with_funded_place, course_cohort:, lead_provider:) }

          it { expect(declaration.declaration_type).to eq(declaration_type) }
          it { expect(declaration.application).to eq(application) }
          it { expect(declaration.declaration_date).to eq(declaration_date) }
          it { expect(declaration.lead_provider).to eq(application.lead_provider) }
          it { expect(declaration.milestone).to eq(started_milestone) }
          it { expect(declaration.delivery_partner.ecf_id).to eq(delivery_partner_id) }
          it { expect(declaration.secondary_delivery_partner.ecf_id).to eq(secondary_delivery_partner_id) }
          it { expect(declaration.value).to eq(started_milestone.payment_amount) }
          it { expect(declaration.statement).to eq(statement) }
        end

        it "sets the application to started" do
          expect(application.reload).to be_started_status
          expect(application.state_changes.last&.event).to eq(Application::STARTED)
        end

        context "when the application is not DfE funded" do
          let(:application) { create(:application, :accepted, :without_funded_place, course_cohort:, lead_provider:) }

          it { expect(declaration.value).to be_nil }
        end
      end

      it "does not create an participant outcome" do
        expect { service.call }.not_to change(ParticipantOutcome, :count)
      end

      context "when no statement exist" do
        let(:statement) { nil }

        before { service.call }

        it { expect(service.declaration.statement).to be_present }
      end

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

        it { is_expected.to have_error(:declaration_type, :out_of_order) }
      end

      context "when application already has a started declaration" do
        let(:application) { create(:application, :accepted, :with_declaration, course_cohort:, lead_provider:) }

        it { is_expected.to validate_param(:base).with_message("A declaration has already been submitted that will be, or has been, paid for this event") }
      end

      context "when declaration_date is before milestone acceptance_window_start_date" do
        let(:declaration_date) { started_milestone.acceptance_window_start_date - 1.hour }

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
    let(:declaration_date) { completed_milestone.acceptance_window_start_date + 1.hour }
    let!(:application) do
      create(:application, :started, :with_declaration, course_cohort:, lead_provider:)
    end

    describe "happy paths" do
      it { expect { service.call }.to change(Declaration, :count).by(1) }
      it { expect { service.call }.to change(ParticipantOutcome, :count).by(1) }

      context "when no statement exist" do
        let(:statement) { nil }

        before { service.call }

        it { expect(service.declaration.statement).to be_present }
      end

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
        let(:resume_cohort) { create(:cohort, :next) }
        let(:course_cohort) { create(:course_cohort, cohort: resume_cohort) }
        let(:started_declaration) { application.declarations.started_declaration_type.first }
        let(:started_cohort) { resume_cohort }
        let!(:completed_milestone) { create(:milestone, :completed, course_cohort: started_milestone.course_cohort) }
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

        it "uses the correct milestone" do
          expect { service.call }.to change(Declaration, :count).by(1)
          expect(service.declaration.milestone).to eq(completed_milestone)
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

      context "when no started declaration exists" do
        let!(:application) { create(:application, :accepted, course_cohort:, lead_provider:) }

        it { is_expected.to have_error(:declaration_type, :out_of_order) }
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

    context "when declaration_type is out of order" do
      let(:declaration_type) { "retained-1" }
      let(:declaration_date) { retained_milestone.acceptance_window_start_date + 1.hour }
      let!(:retained_milestone) do
        create(:milestone, declaration_type: "retained-1", course_cohort:,
                           acceptance_window_start_date: started_milestone.acceptance_window_start_date + 1.day)
      end

      context "when previous milestone has no declaration" do
        it { is_expected.to have_error(:declaration_type, :out_of_order) }

        it_behaves_like "does not update the application"
      end

      context "when previous milestone has a billable declaration" do
        before do
          application.declarations << create(:declaration, :eligible, declaration_type: "started", application:, milestone: started_milestone)
        end

        it { is_expected.to be_valid }
      end
    end
  end
end
