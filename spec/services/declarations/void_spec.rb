# frozen_string_literal: true

require "rails_helper"

RSpec.describe Declarations::Void, type: :model do
  let(:application) { create(:application, :started) }
  let(:statement) { create(:statement, :next_output_fee) }
  let(:declaration_type) { :started }
  let(:declaration) { create(:declaration, declaration_type, application:, lead_provider: statement.lead_provider, cohort: statement.cohort) }

  subject(:service) { described_class.new(declaration:) }

  describe "validations" do
    context "when voiding the declaration" do
      context "when the application has been completed and the declaration is started" do
        let(:declaration_type) { :started }
        let(:application) { create(:application, :completed) }

        it { expect(service).to have_error(:base, :application_status_completed, I18n.t("declaration.application_status_completed")) }
      end

      context "when the application has been completed and the declaration is completed" do
        let(:declaration_type) { :completed }
        let(:application) { create(:application, :completed) }

        it {
          service.call
          expect(service.errors).to be_blank
        }
      end

      Declaration::VOIDABLE_STATES.each do |state|
        context "with a #{state} declaration" do
          before { declaration.update!(state:) }

          context "when the declaration is already voided" do
            before do
              declaration.update!(state: :voided)
              service.call
            end

            it { expect(service).to have_error(:base, :already_voided, "This declaration has already been voided.") }
          end
        end
      end
    end
  end

  describe "#void" do
    subject(:void) { service.call }

    it { is_expected.to be(true) }

    Declaration::VOIDABLE_STATES.each do |declaration_state|
      context "when voiding a #{declaration_state} declaration" do
        before { declaration.update!(state: declaration_state) }

        it { expect { void }.to change { declaration.reload.state }.from(declaration_state).to("voided") }

        %w[eligible ineligible payable].each do |statement_item_state|
          context "when the declaration has a #{statement_item_state} statement item" do
            let(:statement_item) { create(:statement_item, declaration:, state: statement_item_state) }

            it { expect { void }.to change { statement_item.reload.state }.from(statement_item_state).to("voided") }
          end
        end

        it "calls the void participant outcome service" do
          service_double = instance_double(ParticipantOutcomes::Void)
          allow(service_double).to receive(:void_outcome)
          expect(service_double).to receive(:void_outcome)

          allow(ParticipantOutcomes::Void).to receive(:new).with(declaration:).and_return(service_double)
          expect(ParticipantOutcomes::Void).to receive(:new).with(declaration:)

          void
        end
      end
    end

    context "when not valid" do
      before { declaration.update!(state: :voided) }

      it { expect { void }.not_to(change { declaration.reload.state }) }
    end
  end

  describe "Updating application status when voiding" do
    context "when voiding a started declaration" do
      let(:declaration_type) { :started }

      before do
        create(:application_state, :accepted, application:)
        subject.call
      end

      it do
        expect(application.reload.status).to eq(Application::ACCEPTED)
        expect(application.application_states.count).to eq 1
        expect(application.application_states.first.status).to eq(Application::ACCEPTED)
      end
    end

    context "when voiding a completed declaration" do
      let(:declaration_type) { :completed }

      before do
        create(:application_state, :accepted, application:)
        create(:application_state, :started, application:)
        subject.call
      end

      it do
        expect(application.reload.status).to eq(Application::STARTED)
        expect(application.application_states.count).to eq 1
        expect(application.application_states.first.status).to eq(Application::STARTED)
      end
    end
  end
end
