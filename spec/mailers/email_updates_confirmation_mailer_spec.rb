require "rails_helper"

RSpec.describe EmailUpdatesConfirmationMailer, type: :mailer do
  describe "#email_updates_confirmation_mail" do
    let(:to) { "recipient@example.com" }
    let(:service_link) { "https://example.com/service" }
    let(:unsubscribe_link) { "https://example.com/unsubscribe" }
    let(:expected_body) do
      <<~TEXT
        Your service link  #{service_link}.
        You can unsubscribe from this service using the following link: #{unsubscribe_link}.
      TEXT
    end

    subject(:mail) do
      described_class.email_updates_confirmation_mail(
        to:,
        service_link:,
        unsubscribe_link:,
      )
    end

    it do
      aggregate_failures do
        expect(subject).to use_template(GenericMailer::TEMPLATE_ID)
        expect(mail.to).to eq([to])
        expect(mail.personalisation[:subject]).to eq("Email Updates Confirmation")
        expect(mail.personalisation[:body]).to eq(expected_body)
      end
    end

    it_behaves_like "a mailer with redacted logs"
  end
end
