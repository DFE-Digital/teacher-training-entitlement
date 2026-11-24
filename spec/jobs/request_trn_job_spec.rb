require "rails_helper"

RSpec.describe RequestTrnJob, type: :job do
  describe "#perform" do
    let(:teacher) { create(:teacher, trn: nil, refresh_token: "old-token", refresh_token_updated_at: 1.day.ago) }
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

      it "updates teacher with TRN and clears refresh token" do
        described_class.perform_now(teacher)
        expect(teacher.reload).to have_attributes(trn: "1234567", refresh_token: nil)
      end

      it "sets trn_requested_at" do
        freeze_time do
          described_class.perform_now(teacher)
          expect(teacher.reload.trn_requested_at).to eq(Time.current)
        end
      end
    end

    context "when TRN is pending" do
      before { stub_trn_services(trn: nil) }

      it "updates refresh token and sets trn_requested_at" do
        freeze_time do
          described_class.perform_now(teacher)
          teacher.reload
          expect(teacher.trn).to be_nil
          expect(teacher.refresh_token).to eq("new-refresh-token")
          expect(teacher.trn_requested_at).to eq(Time.current)
        end
      end
    end

    context "when teacher already has TRN" do
      let(:teacher) { create(:teacher, trn: "1234567", refresh_token: "token") }

      it "does not call refresh service" do
        expect(TeacherAuth::RefreshToken).not_to receive(:new)
        described_class.perform_now(teacher)
      end
    end

    context "when teacher has no refresh_token" do
      let(:teacher) { create(:teacher, trn: nil, refresh_token: nil) }

      it "does not call refresh service" do
        expect(TeacherAuth::RefreshToken).not_to receive(:new)
        described_class.perform_now(teacher)
      end
    end

    context "when TRN was already requested" do
      let(:teacher) { create(:teacher, trn: nil, refresh_token: "token", trn_requested_at: 1.hour.ago) }

      before { stub_trn_services(trn: "1234567") }

      it "checks again and updates TRN if found" do
        described_class.perform_now(teacher)
        expect(teacher.reload).to have_attributes(trn: "1234567", refresh_token: nil)
      end
    end

    context "when refresh token fails" do
      before { stub_trn_services(refresh_fails: true) }

      it "raises RefreshTokenError" do
        expect { described_class.new.perform(teacher) }.to raise_error(RequestTrnJob::RefreshTokenError)
        expect(teacher.reload.trn_requested_at).to be_nil
      end
    end

    context "when the token is invalid" do
      before do
        allow(TeacherAuth::RefreshToken).to receive(:new).and_return(refresh_service)
        allow(refresh_service).to receive(:call).and_return(:invalid_token)
      end

      it "clears the teacher's auth tokens" do
        expect(teacher).to receive(:clear_auth_tokens!)
        described_class.perform_now(teacher)
      end

      it "does not raise an error" do
        expect { described_class.perform_now(teacher) }.not_to raise_error
      end
    end

    context "when activate TRN returns nil" do
      before { stub_trn_services(trn: nil) }

      it "updates refresh token without setting TRN" do
        freeze_time do
          described_class.perform_now(teacher)
          teacher.reload
          expect(teacher.refresh_token).to eq("new-refresh-token")
          expect(teacher.trn_requested_at).to eq(Time.current)
          expect(teacher.trn).to be_nil
        end
      end
    end
  end
end
