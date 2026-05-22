require "rails_helper"

RSpec.describe EmailUpdatesController, type: :request do
  let(:user) { create :user }

  describe "#create" do
    subject(:do_request) { post(email_updates_path) && response }

    context "when logged in" do
      before { allow(User).to receive(:find_by).and_return user }

      context "with valid request" do
        it "saves email update" do
          expect {
            do_request
          }.to change(user, :email_updates_status).to(User::EMAIL_NPD_REGISTRATION_OPEN.to_s)

          expect(do_request).to have_http_status(:success)
        end
      end
    end

    context "when not logged in" do
      it { is_expected.to redirect_to root_path }
    end
  end
end
