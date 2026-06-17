# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Applications::ChangeStatusForm, type: :model do
  subject(:form) { described_class.new(id: application.id, status:, reason:) }

  let(:application) { create(:application, :accepted) }
  let(:status) { nil }
  let(:reason) { nil }

  describe "validation" do
    context "when checking whether a reason is required based on status" do
      context "with status set to blank" do
        let(:status) { nil }

        it { is_expected.to allow_values("").for(:reason) }
      end

      context "with status set to active" do
        let(:status) { Application::ACCEPTED }

        it { is_expected.to allow_values("").for(:reason) }
      end

      context "with status set to deferred" do
        let(:status) { Application::DEFERRED }

        it do
          expect(subject).to validate_inclusion_of(:reason)
                          .in_array(::Applications::Defer::DEFERRAL_REASONS)
                          .with_message("Choose a valid reason for the status change")
        end
      end

      context "with status set to withdrawn" do
        let(:status) { Application::WITHDRAWN }
        let(:application) { create(:application, :started) }

        it do
          expect(subject).to validate_inclusion_of(:reason)
                          .in_array(::Applications::Withdraw::WITHDRAWAL_REASONS)
                          .with_message("Choose a valid reason for the status change")
        end
      end
    end

    describe "checking for declarations" do
      subject { form.tap(&:valid?).errors[:status] }

      let(:status) { Application::DEFERRED }

      context "with declarations" do
        before { create(:declaration, application:) }

        it { is_expected.not_to include(/cannot defer/i) }
      end

      context "with withdrawn status" do
        let(:status) { Application::WITHDRAWN }

        it { is_expected.not_to include(/cannot defer/i) }
      end

      context "with active status" do
        let(:status) { Application::ACCEPTED }

        it { is_expected.not_to include(/cannot defer/i) }
      end

      context "without pending status on application" do
        let(:application) { create(:application, :pending) }

        it { is_expected.not_to include(/cannot defer/i) }
      end
    end
  end

  describe "#status_options" do
    context "when application set to active" do
      let(:application) { create(:application, :accepted, status: Application::ACCEPTED) }

      it { expect(subject.status_options).to contain_exactly(Application::DEFERRED) }
    end

    context "when application set to started" do
      let(:application) { create(:application, :started) }

      it { expect(subject.status_options).to contain_exactly(Application::DEFERRED, Application::WITHDRAWN) }
    end

    context "when application set to deferred" do
      let(:application) { create(:application, :accepted, :with_declaration, status: Application::DEFERRED) }

      it { expect(subject.status_options).to contain_exactly(Application::ACCEPTED, Application::WITHDRAWN) }
    end

    context "when application set to withdrawn" do
      let(:application) { create(:application, :accepted, status: Application::WITHDRAWN) }

      it { expect(subject.status_options).to contain_exactly(Application::ACCEPTED, Application::DEFERRED) }
    end
  end

  describe "#reason_options" do
    context "when application set to active" do
      it "only includes deferral reasons" do
        expect(form.reason_options.keys).to contain_exactly(Application::DEFERRED)
      end

      it "has reasons for deferral" do
        expect(form.reason_options[Application::DEFERRED])
          .to match_array(::Applications::Defer::DEFERRAL_REASONS)
      end
    end

    context "when application set to started" do
      let(:application) { create(:application, :started) }

      it "groups by training status" do
        expect(form.reason_options.keys).to contain_exactly(Application::DEFERRED, Application::WITHDRAWN)
      end

      it "has reasons for deferral" do
        expect(form.reason_options[Application::DEFERRED])
          .to match_array(::Applications::Defer::DEFERRAL_REASONS)
      end

      it "has reasons for withdrawn" do
        expect(form.reason_options[Application::WITHDRAWN])
          .to match_array(::Applications::Withdraw::WITHDRAWAL_REASONS)
      end
    end
  end
end
