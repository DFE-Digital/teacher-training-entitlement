# frozen_string_literal: true

require "rails_helper"

RSpec.describe Declarations::Void, type: :model do
  let(:application) { create(:application, :started) }
  let(:statement) { create(:statement, :next_output_fee) }
  let(:declaration_trait) { :started }
  let(:declaration) { create(:declaration, declaration_trait, application:, lead_provider: statement.lead_provider, cohort: statement.cohort) }

  subject(:service) { described_class.new(declaration:) }

  describe "validations" do
    context "when voiding the declaration" do
      context "when the application has been completed and the declaration is started" do
        let(:declaration_trait) { :started }
        let(:application) { create(:application, :completed) }

        it do
          expect(service).to have_error(:base, :application_status_completed,
                                        I18n.t("activemodel.errors.models.declarations/void.attributes.base.application_status_completed"))

          expect(service).to have_error(:base, :not_voidable_to_accepted_status,
                                        I18n.t("activemodel.errors.models.declarations/void.attributes.base.not_voidable_to_accepted_status"))
        end
      end

      context "when the application has been completed and the declaration is also completed" do
        let(:declaration_trait) { :completed }
        let(:application) { create(:application, :started) }

        it do
          expect(service).to have_error(:base, :not_voidable_to_started_status,
                                        I18n.t("activemodel.errors.models.declarations/void.attributes.base.not_voidable_to_started_status"))
        end
      end

      context "when the application has been completed and the declaration is completed" do
        let(:declaration_trait) { :completed }
        let(:application) { create(:application, :completed) }

        it {
          service.call
          expect(service.errors).to be_blank
        }
      end

      context "when the declaration is already voided" do
        let(:declaration_trait) { :voided }

        it {
          service.call
          expect(service).to have_error(:base, :already_voided, "This declaration has already been voided.")
        }
      end
    end
  end

  Declaration::VOIDABLE_STATES.each do |declaration_state|
    context "when voiding a #{declaration_state} declaration" do
      let(:declaration_trait) { declaration_state }

      it { expect { service.call }.to change { declaration.reload.state }.from(declaration_state).to("voided") }

      %w[eligible ineligible payable].each do |statement_item_state|
        context "when the declaration has a #{statement_item_state} statement item" do
          let(:statement_item) { create(:statement_item, declaration:, state: statement_item_state) }

          it { expect { service.call }.to change { statement_item.reload.state }.from(statement_item_state).to("voided") }
        end
      end

      it "calls the void participant outcome service" do
        service_double = instance_double(ParticipantOutcomes::Void)
        allow(service_double).to receive(:void_outcome)
        expect(service_double).to receive(:void_outcome)

        allow(ParticipantOutcomes::Void).to receive(:new).with(declaration:).and_return(service_double)
        expect(ParticipantOutcomes::Void).to receive(:new).with(declaration:)

        service.call
      end
    end
  end

  describe "Updating application status when voiding" do
    context "when voiding a started declaration" do
      let(:declaration_trait) { :started }

      it "creates exactly one state change" do
        expect { subject.call }.to change { application.state_changes.count }.by(1)

        expect(application.reload.status).to eq(Application::ACCEPTED)
        expect(application.state_changes.last.status).to eq(Application::ACCEPTED)
        expect(application.state_changes.last.reason).to eq("started declaration voided")
      end
    end

    context "when voiding a completed declaration" do
      let(:declaration_trait) { :completed }
      let(:application) { create(:application, :completed) }

      it "creates exactly one state change" do
        expect { subject.call }.to change { application.state_changes.count }.by(1)

        expect(application.reload.status).to eq(Application::STARTED)
        expect(application.state_changes.count).to eq 2
        expect(application.state_changes.last.status).to eq(Application::STARTED)
        expect(application.state_changes.last.reason).to eq("completed declaration voided")
      end
    end
  end
end
