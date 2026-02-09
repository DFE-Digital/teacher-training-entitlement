require "rails_helper"

RSpec.describe ConfirmEmailMailer, type: :mailer do
  describe "#confirmation_code_mail" do
    let(:to) { "recipient@example.com" }
    let(:code) { "ABC123" }
    let(:expected_body) do
      <<~TEXT
        Your confirmation code is #{code}.
        It will expire in 10 minutes.
      TEXT
    end

    subject(:mail) do
      described_class.confirmation_code_mail(
        to:,
        code:,
      )
    end

    it do
      aggregate_failures do
        expect(subject).to use_template(GenericMailer::TEMPLATE_ID)
        expect(mail.to).to eq([to])
        expect(mail.personalisation[:subject]).to eq("Confirmation Code")

        body = mail.personalisation[:body]
        expect(body).to include(code)
      end
    end

    it_behaves_like "a mailer with redacted logs"
  end
end
