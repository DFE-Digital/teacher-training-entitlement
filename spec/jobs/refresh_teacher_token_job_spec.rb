require "rails_helper"

RSpec.describe RefreshTeacherTokenJob, type: :job do
  describe "#perform" do
    let(:teacher) { create(:teacher, trn: nil, refresh_token: "old-token", refresh_token_updated_at: 8.days.ago) }

    context "when refresh is successful" do
      let(:refresh_service) { instance_double(TeacherAuth::RefreshToken) }

      before do
        allow(TeacherAuth::RefreshToken).to receive(:new).and_return(refresh_service)
        allow(refresh_service).to receive(:call).and_return(
          access_token: "new-access-token",
          refresh_token: "new-refresh-token",
        )
      end

      it "updates the teacher's refresh_token" do
        described_class.perform_now(teacher)
        expect(teacher.reload.refresh_token).to eq("new-refresh-token")
      end

      it "updates refresh_token_updated_at" do
        freeze_time do
          described_class.perform_now(teacher)
          expect(teacher.reload.refresh_token_updated_at).to eq(Time.current)
        end
      end
    end

    context "when teacher has TRN" do
      let(:teacher) { create(:teacher, trn: "1234567", refresh_token: "token") }

      it "does nothing" do
        expect(TeacherAuth::RefreshToken).not_to receive(:new)
        described_class.perform_now(teacher)
      end
    end

    context "when teacher has no refresh_token" do
      let(:teacher) { create(:teacher, trn: nil, refresh_token: nil) }

      it "does nothing" do
        expect(TeacherAuth::RefreshToken).not_to receive(:new)
        described_class.perform_now(teacher)
      end
    end

    context "when TRN was already requested" do
      let(:teacher) { create(:teacher, trn: nil, refresh_token: "token", trn_requested_at: 1.hour.ago) }

      it "does nothing" do
        expect(TeacherAuth::RefreshToken).not_to receive(:new)
        described_class.perform_now(teacher)
      end
    end

    context "when refresh fails" do
      let(:refresh_service) { instance_double(TeacherAuth::RefreshToken) }

      before do
        allow(TeacherAuth::RefreshToken).to receive(:new).and_return(refresh_service)
        allow(refresh_service).to receive(:call).and_return(nil)
      end

      it "does not update the teacher" do
        expect {
          described_class.perform_now(teacher)
        }.not_to(change { teacher.reload.refresh_token })
      end
    end

    context "when the token is invalid" do
      let(:refresh_service) { instance_double(TeacherAuth::RefreshToken) }

      before do
        allow(TeacherAuth::RefreshToken).to receive(:new).and_return(refresh_service)
        allow(refresh_service).to receive(:call).and_return(:invalid_token)
      end

      it "clears the teacher's auth tokens" do
        expect(teacher).to receive(:clear_auth_tokens!)
        described_class.perform_now(teacher)
      end
    end
  end
end
