# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Applications::ChangeTrainingStatusForm, type: :model do
  subject(:form) { described_class.new(id: application.id, training_status:, reason:) }

  let(:application) { create(:application, :accepted) }
  let(:training_status) { nil }
  let(:reason) { nil }

  describe "validation" do
    context "when provider approval status pending" do
      let(:application) { create(:application, :pending) }

      context "when training status is nil" do
        it "returns an error message" do
          expect(form).to have_error(:training_status, :unchanged)
        end
      end
    end

    context "when checking whether a reason is required based on training status" do
      context "with training_status set to blank" do
        let(:training_status) { nil }

        it { is_expected.to allow_values("").for(:reason) }
      end

      context "with training_status set to active" do
        let(:training_status) { "active" }

        it { is_expected.to allow_values("").for(:reason) }
      end

      context "with training_status set to deferred" do
        let(:training_status) { "deferred" }

        it do
          expect(subject).to validate_inclusion_of(:reason)
                          .in_array(Participants::Defer::DEFERRAL_REASONS)
                          .with_message("Choose a valid reason for the training status change")
        end
      end

      context "with training_status set to withdrawn" do
        let(:training_status) { "withdrawn" }

        it do
          expect(subject).to validate_inclusion_of(:reason)
                          .in_array(Participants::Withdraw::WITHDRAWAL_REASONS)
                          .with_message("Choose a valid reason for the training status change")
        end
      end
    end

    describe "checking for declarations" do
      subject { form.tap(&:valid?).errors[:training_status] }

      let(:training_status) { "deferred" }

      context "with declarations" do
        before { create(:declaration, application:) }

        it { is_expected.not_to include(/cannot defer/i) }
      end

      context "with withdrawn training_status" do
        let(:training_status) { "withdrawn" }

        it { is_expected.not_to include(/cannot defer/i) }
      end

      context "with active training_status" do
        let(:training_status) { "active" }

        it { is_expected.not_to include(/cannot defer/i) }
      end

      context "without pending lead_provider_approval_status on application" do
        let(:application) { create(:application, :pending) }

        it { is_expected.not_to include(/cannot defer/i) }
      end
    end
  end

  describe "#training_status_options" do
    context "when application set to active" do
      let(:application) { create(:application, :accepted, training_status: "active") }

      it { expect(subject.training_status_options).to match_array %w[deferred withdrawn] }
    end

    context "when application set to deferred" do
      let(:application) { create(:application, :accepted, :with_declaration, training_status: "deferred") }

      it { expect(subject.training_status_options).to match_array %w[active withdrawn] }
    end

    context "when application set to withdrawn" do
      let(:application) { create(:application, :accepted, training_status: "withdrawn") }

      it { expect(subject.training_status_options).to match_array %w[active deferred] }
    end
  end

  describe "#reason_options" do
    it "groups by training status" do
      expect(form.reason_options.keys).to match_array(%w[deferred withdrawn])
    end

    it "has reasons for deferral" do
      expect(form.reason_options["deferred"])
        .to match_array(Participants::Defer::DEFERRAL_REASONS)
    end

    it "has reasons for withdrawn" do
      expect(form.reason_options["withdrawn"])
        .to match_array(Participants::Withdraw::WITHDRAWAL_REASONS)
    end
  end
end
