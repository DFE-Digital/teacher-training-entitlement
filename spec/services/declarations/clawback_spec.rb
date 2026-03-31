# frozen_string_literal: true

require "rails_helper"

RSpec.describe Declarations::Clawback, type: :model do
  let(:application) { create(:application, :started) }
  let(:statement) { create(:statement, :next_output_fee) }
  let(:declaration_type) { :started }
  let(:declaration_state) { :submitted }
  let(:declaration) { create(:declaration, declaration_type, state: declaration_state, application:, lead_provider: statement.lead_provider, cohort: statement.cohort) }

  subject(:service) { described_class.new(declaration:) }

  describe "validations" do
    context "when clawing back the declaration" do
      Declaration::CLAWBACK_STATES.each do |state|
        context "with a #{state} declaration" do
          before { declaration.update!(state: :paid) }

          StatementItem::REFUNDABLE_STATES.each do |ineligible_state|
            context "when the declaration already has a #{ineligible_state} statement item" do
              before do
                create(:statement_item, declaration:, state: ineligible_state)
                service.call
              end

              it { expect(service).to have_error(:base, :not_already_refunded, "The declaration will or has been be refunded.") }
            end
          end

          context "when there is no output fee statement" do
            before { statement.update!(output_fee: false) }

            it { expect(service).to have_error(:base, :no_output_fee_statement, "You cannot submit or void declarations for the #{declaration.cohort.start_year} cohort. The funding contract for this cohort has ended. Get in touch if you need to discuss this with us.") }
          end
        end
      end

      Declaration::CLAWBACK_STATES.excluding("paid").each do |state|
        context "when the declaration is #{state}" do
          before { declaration.update!(state:) }

          it { expect(service).to have_error(:base, :must_be_paid, "The declaration must be paid before it can be clawed back.") }

          context "when there are other declaration errors" do
            before { create(:statement_item, declaration:, state: StatementItem::REFUNDABLE_STATES.sample) }

            it { expect(service).to have_error(:base) }
            it { expect(service).not_to have_error(:base, :must_be_paid) }
          end
        end
      end
    end
  end

  describe "Updating application status" do
    context "when processing a started declaration" do
      let(:declaration_type) { :started }
      let(:declaration_state) { :paid }

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

    context "when processing a completed declaration" do
      let(:declaration_type) { :completed }
      let(:declaration_state) { :paid }

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
