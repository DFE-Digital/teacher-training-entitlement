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
      context "when the application has been completed and the declaration is started" do
        let(:declaration_type) { :started }
        let(:application) { create(:application, :completed) }

        it do
          expect(service).to have_error(:base, :application_status_completed,
                                        I18n.t("activemodel.errors.models.declarations/void.attributes.base.application_status_completed"))

          expect(service).to have_error(:base, :not_voidable_to_accepted_status,
                                        I18n.t("activemodel.errors.models.declarations/void.attributes.base.not_voidable_to_accepted_status"))
        end
      end

      context "when the application has been completed and the declaration is also completed" do
        let(:declaration_type) { :completed }
        let(:application) { create(:application, :started) }

        it do
          expect(service).to have_error(:base, :not_voidable_to_started_status,
                                        I18n.t("activemodel.errors.models.declarations/void.attributes.base.not_voidable_to_started_status"))
        end
      end

      context "when the application has been completed and the declaration is completed" do
        let(:declaration_type) { :completed }
        let(:declaration_state) { :paid }
        let(:application) { create(:application, :completed) }

        it {
          service.call
          expect(service.errors).to be_blank
        }
      end

      context "with a paid declaration" do
        context "when paid declaration already clawbacked" do
          let(:clawback_declaration) { create(:clawback_declaration) }

          before { declaration.update!(state: :paid, clawback_declaration:) }

          it { expect(service).to have_error(:base, :not_already_refunded, "The declaration will or has been be refunded.") }
        end

        context "when paid declaration not clawbacked" do
          before { declaration.update!(state: :paid) }

          it { expect(service.errors).to be_blank }
        end
      end
    end
  end

  describe "Updating application status" do
    context "when processing a started declaration" do
      let(:declaration_type) { :started }
      let(:declaration_state) { :paid }

      it "creates exactly one state change" do
        expect { subject.call }.to change { application.state_changes.count }.by(1)

        expect(application.reload.status).to eq(Application::ACCEPTED)
        expect(application.state_changes.last.status).to eq(Application::ACCEPTED)
        expect(application.state_changes.last.reason).to eq("started declaration voided")
      end
    end

    context "when processing a completed declaration" do
      let(:application) { create(:application, :completed) }
      let(:declaration_type) { :completed }
      let(:declaration_state) { :paid }

      it "creates exactly one state change" do
        expect { subject.call }.to change { application.state_changes.count }.by(1)

        expect(application.reload.status).to eq(Application::STARTED)
        expect(application.state_changes.last.status).to eq(Application::STARTED)
        expect(application.state_changes.last.reason).to eq("completed declaration voided")
      end
    end
  end
end
