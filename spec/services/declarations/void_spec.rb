# frozen_string_literal: true

require "rails_helper"

RSpec.describe Declarations::Void, type: :model do
  let(:application) { create(:application, :started) }
  let(:statement) { create(:statement, :next_output_fee) }
  let(:declaration_type) { :started }
  let(:declaration) { create(:declaration, declaration_type, application:, lead_provider: statement.lead_provider, cohort: statement.cohort) }

  subject(:service) { described_class.new(declaration:) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:declaration) }

    context "when voiding the declaration" do
      Declaration::VOIDABLE_STATES.each do |state|
        context "with a #{state} declaration" do
          before { declaration.update!(state:) }

          context "when the declaration is already voided" do
            before { declaration.update!(state: :voided) }

            it { expect(service).to have_error(:declaration, :already_voided, "This declaration has already been voided.") }
          end
        end
      end
    end

    context "when clawing back the declaration" do
      described_class::CLAWBACK_STATES.each do |state|
        context "with a #{state} declaration" do
          before { declaration.update!(state: :paid) }

          StatementItem::REFUNDABLE_STATES.each do |ineligible_state|
            context "when the declaration already has a #{ineligible_state} statement item" do
              before { create(:statement_item, declaration:, state: ineligible_state) }

              it { expect(service).to have_error(:declaration, :not_already_refunded, "The declaration will or has been be refunded.") }
            end
          end

          context "when there is no output fee statement" do
            before { statement.update!(output_fee: false) }

            it { expect(service).to have_error(:declaration, :no_output_fee_statement, "You cannot submit or void declarations for the #{declaration.cohort.start_year} cohort. The funding contract for this cohort has ended. Get in touch if you need to discuss this with us.") }
          end
        end
      end

      described_class::CLAWBACK_STATES.excluding("paid").each do |state|
        context "when the declaration is #{state}" do
          before { declaration.update!(state:) }

          it { expect(service).to have_error(:declaration, :must_be_paid, "The declaration must be paid before it can be clawed back.") }

          context "when there are other declaration errors" do
            before { create(:statement_item, declaration:, state: StatementItem::REFUNDABLE_STATES.sample) }

            it { expect(service).to have_error(:declaration) }
            it { expect(service).not_to have_error(:declaration, :must_be_paid) }
          end
        end
      end
    end
  end

  describe "#void" do
    subject(:void) { service.void }

    it { is_expected.to be(true) }

    it "reloads declaration after action" do
      allow(service.declaration).to receive(:reload)
      void
      expect(service.declaration).to have_received(:reload)
    end

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

    context "when clawing back the declaration" do
      before { declaration.update!(state: :paid) }

      it { expect { void }.to change { declaration.reload.state }.from("paid").to("awaiting_clawback") }

      it "creates a statement item" do
        expect { void }.to change { statement.reload.statement_items.count }.by(1)
        created_statement_item = statement.statement_items.last
        expect(created_statement_item).to have_attributes(declaration:, state: declaration.reload.state)
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

    context "when not valid" do
      before { declaration.update!(state: :voided) }

      it { is_expected.to be(false) }
      it { expect { void }.not_to(change { declaration.reload.state }) }
    end
  end

  describe "Updating application status when voiding" do
    context "when voiding a started declaration" do
      let(:declaration_type) { :started }

      before do
        create(:application_state, :accepted, application:)
        subject.void
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
        subject.void
      end

      it do
        expect(application.reload.status).to eq(Application::STARTED)
        expect(application.application_states.count).to eq 1
        expect(application.application_states.first.status).to eq(Application::STARTED)
      end
    end
  end
end
