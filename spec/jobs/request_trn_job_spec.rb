require "rails_helper"

RSpec.describe RequestTrnJob, type: :job do
  describe "#perform" do
    let(:user) { create(:user, trn: nil, refresh_token: "old-token", refresh_token_updated_at: 1.day.ago) }
    let(:refresh_service) { instance_double(TeacherAuth::RefreshToken) }
    let(:activate_service) { instance_double(TeacherAuth::ActivateTrn) }

    def stub_trn_services(trn: nil, refresh_fails: false)
      allow(TeacherAuth::RefreshToken).to receive(:new).and_return(refresh_service)
      allow(refresh_service).to receive(:call).and_return(
        refresh_fails ? nil : { access_token: "new-access-token", refresh_token: "new-refresh-token" },
      )
      allow(TeacherAuth::ActivateTrn).to receive(:new).and_return(activate_service)
      allow(activate_service).to receive(:call).and_return(trn ? { trn: trn } : nil)
    end

    context "when TRN is returned immediately" do
      before { stub_trn_services(trn: "1234567") }

      it "updates user with TRN and clears refresh token" do
        described_class.perform_now(user)
        expect(user.reload).to have_attributes(trn: "1234567", refresh_token: nil)
      end

      it "sets trn_requested_at" do
        freeze_time do
          described_class.perform_now(user)
          expect(user.reload.trn_requested_at).to eq(Time.current)
        end
      end
    end

    context "when TRN is pending" do
      before { stub_trn_services(trn: nil) }

      it "updates refresh token and sets trn_requested_at" do
        freeze_time do
          described_class.perform_now(user)
          user.reload
          expect(user.trn).to be_nil
          expect(user.refresh_token).to eq("new-refresh-token")
          expect(user.trn_requested_at).to eq(Time.current)
        end
      end
    end

    context "when user already has TRN" do
      let(:user) { create(:user, trn: "1234567", refresh_token: "token") }

      it "does not call refresh service" do
        expect(TeacherAuth::RefreshToken).not_to receive(:new)
        described_class.perform_now(user)
      end
    end

    context "when user has no refresh_token" do
      let(:user) { create(:user, trn: nil, refresh_token: nil) }

      it "does not call refresh service" do
        expect(TeacherAuth::RefreshToken).not_to receive(:new)
        described_class.perform_now(user)
      end
    end

    context "when TRN was already requested" do
      let(:user) { create(:user, trn: nil, refresh_token: "token", trn_requested_at: 1.hour.ago) }

      before { stub_trn_services(trn: "1234567") }

      it "checks again and updates TRN if found" do
        described_class.perform_now(user)
        expect(user.reload).to have_attributes(trn: "1234567", refresh_token: nil)
      end
    end

    context "when refresh token fails" do
      before { stub_trn_services(refresh_fails: true) }

      it "raises RefreshTokenError" do
        expect { described_class.new.perform(user) }.to raise_error(RequestTrnJob::RefreshTokenError)
        expect(user.reload.trn_requested_at).to be_nil
      end
    end

    context "when activate TRN returns nil" do
      before { stub_trn_services(trn: nil) }

      it "updates refresh token without setting TRN" do
        freeze_time do
          described_class.perform_now(user)
          user.reload
          expect(user.refresh_token).to eq("new-refresh-token")
          expect(user.trn_requested_at).to eq(Time.current)
          expect(user.trn).to be_nil
        end
      end
    end
  end
end
