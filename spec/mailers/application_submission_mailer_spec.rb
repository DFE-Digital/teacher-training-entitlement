require "rails_helper"

RSpec.describe ApplicationSubmissionMailer, type: :mailer do
  describe "#application_submitted_mail" do
    let(:to) { "recipient@example.com" }
    let(:full_name) { "Example User" }
    let(:provider_name) { "Example Provider" }
    let(:course_name) { "Example Course" }
    let(:amount) { "Example Amount" }
    let(:ecf_id) { "ABC123" }
    let(:expected_body) do
      <<~TEXT
        Your application has been submitted.
        Full name: #{full_name}
        Provider name: #{provider_name}
        Course name: #{course_name}
        Amount: #{amount}
        ECF ID: #{ecf_id}
      TEXT
    end

    subject(:mail) do
      described_class.application_submitted_mail(
        to:,
        full_name:,
        provider_name:,
        course_name:,
        amount:,
        ecf_id:,
      )
    end

    it do
      aggregate_failures do
        expect(subject).to use_template(GenericMailer::TEMPLATE_ID)
        expect(mail.to).to eq([to])
        expect(mail.personalisation[:subject]).to eq("Application submitted")
        expect(mail.personalisation[:body]).to eq(expected_body)
      end
    end

    it_behaves_like "a mailer with redacted logs"
  end
end
