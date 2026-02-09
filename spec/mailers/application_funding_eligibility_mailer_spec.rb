require "rails_helper"

RSpec.describe ApplicationFundingEligibilityMailer, type: :mailer do
  describe "#eligible_for_funding_mail" do
    let(:to) { "recipient@example.com" }
    let(:full_name) { "Example User" }
    let(:provider_name) { "Example Provider" }
    let(:course_name) { "Example Course" }
    let(:ecf_id) { "ABC123" }

    subject(:mail) do
      described_class.eligible_for_funding_mail(
        to:,
        full_name:,
        provider_name:,
        course_name:,
        ecf_id:,
      )
    end

    it do
      aggregate_failures do
        expect(subject).to use_template(GenericMailer::TEMPLATE_ID)
        expect(mail.to).to eq([to])
        expect(mail.personalisation[:subject]).to eq("Eligible for funding")

        body = mail.personalisation[:body]
        expect(body).to include(full_name)
        expect(body).to include(provider_name)
        expect(body).to include(course_name)
        expect(body).to include(ecf_id)
      end
    end

    it_behaves_like "a mailer with redacted logs"
  end
end
