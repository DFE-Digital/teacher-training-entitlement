require "rails_helper"

RSpec.describe EmailUpdatesController, type: :request do
  let(:user) { create :user }

  describe "#create" do
    subject(:do_request) { post(email_updates_path) && response }

    context "when logged in" do
      before { allow(User).to receive(:find_by).and_return user }

      it "subscribes the user's email" do
        expect { do_request }.to change(EmailUpdateSubscription, :count).by(1)

        expect(EmailUpdateSubscription.last).to have_attributes(
          email: user.email,
          full_name: user.full_name,
          status: EmailUpdateSubscription::NPD_REGISTRATION_OPEN,
        )
        expect(response).to have_http_status(:success)
      end

      it "sends a confirmation email with the unsubscribe link" do
        expect { do_request }.to have_enqueued_mail(GenericMailer, :email_updates_confirmation)
          .with(a_hash_including(params: a_hash_including(
            to: user.email,
            unsubscribe_link: satisfy { |link| link.include?(EmailUpdateSubscription.last.unsubscribe_key) },
          )))
      end

      context "when the email is already subscribed" do
        let!(:subscription) { create(:email_update_subscription, email: user.email) }

        it "keeps the existing subscription and unsubscribe key" do
          expect { do_request }.to not_change(EmailUpdateSubscription, :count)
            .and(not_change { subscription.reload.unsubscribe_key })
        end

        it "refreshes the name" do
          expect { do_request }.to change { subscription.reload.full_name }.to(user.full_name)
        end
      end
    end

    context "when not logged in" do
      it { is_expected.to redirect_to root_path }
    end
  end

  describe "#unsubscribe" do
    let!(:subscription) { create(:email_update_subscription) }

    it "removes the subscription matching the key" do
      expect { post unsubscribe_email_updates_path(unsubscribe_key: subscription.unsubscribe_key) }
        .to change(EmailUpdateSubscription, :count).by(-1)

      expect(response).to redirect_to(unsubscribed_email_updates_path)
    end

    it "rejects an unknown key" do
      expect { post unsubscribe_email_updates_path(unsubscribe_key: "unknown") }
        .not_to change(EmailUpdateSubscription, :count)

      expect(response).to redirect_to(root_path)
    end
  end
end
