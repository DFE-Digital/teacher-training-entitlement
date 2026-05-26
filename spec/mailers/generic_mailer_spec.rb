require "rails_helper"

RSpec.describe GenericMailer, type: :mailer do
  describe "#email_updates_confirmation" do
    let(:to) { "recipient@example.com" }
    let(:name) { "Some One" }
    let(:unsubscribe_link) { "https://example.com/unsubscribe" }

    subject(:mail) do
      described_class.with(
        to:,
        unsubscribe_link:,
        name:,
      ).email_updates_confirmation
    end

    it do
      aggregate_failures do
        expect(subject).to use_template(GenericMailer::TEMPLATE_ID)
        expect(mail.to).to eq([to])
        expect(mail.personalisation[:subject]).to eq(I18n.t("mailers.email_updates_confirmation"))

        body = mail.personalisation[:body]
        expect(body).to include(unsubscribe_link)
      end
    end

    it_behaves_like "a mailer with redacted logs"
  end

  describe "#application_submitted" do
    let(:to) { "recipient@example.com" }
    let(:full_name) { "Example User" }
    let(:provider_name) { "Example Provider" }
    let(:course_name) { "Example Course" }
    let(:amount) { "Example Amount" }
    let(:ecf_id) { "ABC123" }

    subject(:mail) do
      described_class.with(
        to:,
        full_name:,
        provider_name:,
        course_name:,
        amount:,
        ecf_id:,
      ).application_submitted
    end

    it do
      aggregate_failures do
        expect(subject).to use_template(GenericMailer::TEMPLATE_ID)
        expect(mail.to).to eq([to])
        expect(mail.personalisation[:subject]).to eq(I18n.t("mailers.application_submitted"))

        body = mail.personalisation[:body]
        expect(body).to include(full_name)
        expect(body).to include(provider_name)
        expect(body).to include(course_name)
        expect(body).to include(ecf_id)
      end
    end

    it_behaves_like "a mailer with redacted logs"
  end

  describe "#confirmation_code" do
    let(:to) { "recipient@example.com" }
    let(:code) { "ABC123" }

    subject(:mail) do
      described_class.with(
        to:,
        code:,
      ).confirmation_code
    end

    it do
      aggregate_failures do
        expect(subject).to use_template(GenericMailer::TEMPLATE_ID)
        expect(mail.to).to eq([to])
        expect(mail.personalisation[:subject]).to eq(I18n.t("mailers.confirmation_code"))

        body = mail.personalisation[:body]
        expect(body).to include(code)
      end
    end

    it_behaves_like "a mailer with redacted logs"
  end

  describe "#eligible_for_funding" do
    let(:to) { "recipient@example.com" }
    let(:full_name) { "Example User" }
    let(:provider_name) { "Example Provider" }
    let(:course_name) { "Example Course" }
    let(:ecf_id) { "ABC123" }

    subject(:mail) do
      described_class.with(
        to:,
        full_name:,
        provider_name:,
        course_name:,
        ecf_id:,
      ).eligible_for_funding
    end

    it do
      aggregate_failures do
        expect(subject).to use_template(GenericMailer::TEMPLATE_ID)
        expect(mail.to).to eq([to])
        expect(mail.personalisation[:subject]).to eq(I18n.t("mailers.eligible_for_funding"))

        body = mail.personalisation[:body]
        expect(body).to include(full_name)
        expect(body).to include(provider_name)
        expect(body).to include(course_name)
        expect(body).to include(ecf_id)
      end
    end

    it_behaves_like "a mailer with redacted logs"
  end

  describe "#change_provider" do
    let(:to) { "recipient@example.com" }
    let(:full_name) { "Example User" }
    let(:provider_name) { "Example Provider" }
    let(:course_name) { "Example Course" }
    let(:cohort_date) { "autumn 2026" }
    let(:ecf_id) { "ABC123" }
    let(:sign_in_link) { "sign_in_link" }
    let(:feedback_link) { "feedback_link" }

    subject(:mail) do
      described_class.with(
        to:,
        full_name:,
        provider_name:,
        course_name:,
        cohort_date:,
        ecf_id:,
        sign_in_link:,
        feedback_link:,
      ).change_provider
    end

    it do
      aggregate_failures do
        expect(subject).to use_template(GenericMailer::TEMPLATE_ID)
        expect(mail.to).to eq([to])
        expect(mail.personalisation[:subject]).to eq(I18n.t("mailers.change_provider", course_name:))

        body = mail.personalisation[:body]
        expect(body).to include(full_name)
        expect(body).to include(provider_name)
        expect(body).to include(course_name)
        expect(body).to include(cohort_date)
        expect(body).to include(sign_in_link)
        expect(body).to include(feedback_link)
        expect(body).to include(ecf_id)
      end
    end

    it_behaves_like "a mailer with redacted logs"
  end

  describe "notification logging" do
    let(:application) { create(:application) }
    let(:to) { "recipient@example.com" }

    it "creates an application event when ecf_id matches an application" do
      expect {
        described_class.with(to:, ecf_id: application.ecf_id, full_name: "Test", provider_name: "Test", course_name: "Test").application_submitted.deliver_now
      }.to change { application.notifications.count }.by(1)

      event = application.notifications.last
      expect(event.event).to eq("application_submitted")
      expect(event.metadata).to include("ecf_id" => application.ecf_id)
      expect(event.metadata).not_to include("to", "full_name")
    end

    it "does not create an event when ecf_id is missing" do
      expect {
        described_class.with(to:, code: "123").confirmation_code.deliver_now
      }.not_to change(ApplicationEvent, :count)
    end

    it "includes cohort_id in metadata when provided" do
      described_class.with(
        to:,
        ecf_id: application.ecf_id,
        full_name: "Test",
        course_name: "Test",
        next_course_start_date: "February 2027",
        deferral_date: "1 January 2026",
        cohort_id: 123,
      ).registration_open_notification.deliver_now

      event = application.notifications.last
      expect(event.metadata).to include("cohort_id" => 123)
      expect(event.metadata).not_to include("to", "full_name")
    end
  end

  describe "#deferral_notification" do
    let(:to) { "recipient@example.com" }
    let(:full_name) { "Example User" }
    let(:provider_name) { "Example Provider" }
    let(:course_name) { "Early Years TTE" }
    let(:deferral_date) { "10 November 2026" }
    let(:ecf_id) { "ABC123" }

    subject(:mail) do
      described_class.with(
        to:,
        full_name:,
        provider_name:,
        course_name:,
        deferral_date:,
        ecf_id:,
      ).deferral_notification
    end

    it do
      aggregate_failures do
        expect(subject).to use_template(GenericMailer::TEMPLATE_ID)
        expect(mail.to).to eq([to])
        expect(mail.personalisation[:subject]).to eq("Notification of deferral - #{course_name}")

        body = mail.personalisation[:body]
        expect(body).to include(full_name)
        expect(body).to include(provider_name)
        expect(body).to include(course_name)
        expect(body).to include(deferral_date)
        expect(body).to include(ecf_id)
      end
    end

    it_behaves_like "a mailer with redacted logs"
  end

  describe "#registration_open_notification" do
    let(:to) { "recipient@example.com" }
    let(:full_name) { "Example User" }
    let(:course_name) { "Early Years TTE" }
    let(:next_course_start_date) { "February 2027" }
    let(:deferral_date) { "10 November 2026" }
    let(:ecf_id) { "ABC123" }

    subject(:mail) do
      described_class.with(
        to:,
        full_name:,
        course_name:,
        next_course_start_date:,
        deferral_date:,
        ecf_id:,
      ).registration_open_notification
    end

    it do
      aggregate_failures do
        expect(subject).to use_template(GenericMailer::TEMPLATE_ID)
        expect(mail.to).to eq([to])
        expect(mail.personalisation[:subject]).to eq("Registration open - #{course_name}")

        body = mail.personalisation[:body]
        expect(body).to include(full_name)
        expect(body).to include(course_name)
        expect(body).to include(next_course_start_date)
        expect(body).to include(deferral_date)
        expect(body).to include(ecf_id)
      end
    end

    it_behaves_like "a mailer with redacted logs"
  end

  describe "#deferral_expiring_notification" do
    let(:to) { "recipient@example.com" }
    let(:full_name) { "Example User" }
    let(:course_name) { "Early Years TTE" }
    let(:deferral_date) { "10 November 2026" }
    let(:ecf_id) { "ABC123" }

    subject(:mail) do
      described_class.with(
        to:,
        full_name:,
        course_name:,
        deferral_date:,
        ecf_id:,
      ).deferral_expiring_notification
    end

    it do
      aggregate_failures do
        expect(subject).to use_template(GenericMailer::TEMPLATE_ID)
        expect(mail.to).to eq([to])
        expect(mail.personalisation[:subject]).to eq("Registration about to expire - #{course_name}")

        body = mail.personalisation[:body]
        expect(body).to include(full_name)
        expect(body).to include(course_name)
        expect(body).to include(deferral_date)
        expect(body).to include(ecf_id)
      end
    end

    it_behaves_like "a mailer with redacted logs"
  end

  describe "#provider_rejected" do
    let(:to) { "recipient@example.com" }
    let(:full_name) { "Example User" }
    let(:provider_name) { "Example Provider" }
    let(:course_name) { "Early Years TTE" }
    let(:cohort_date) { "autumn 2026" }
    let(:sign_in_link) { "https://example.com/sign-in" }
    let(:ecf_id) { "ABC123" }

    subject(:mail) do
      described_class.with(
        to:,
        full_name:,
        provider_name:,
        course_name:,
        cohort_date:,
        sign_in_link:,
        ecf_id:,
      ).provider_rejected
    end

    it do
      aggregate_failures do
        expect(subject).to use_template(GenericMailer::TEMPLATE_ID)
        expect(mail.to).to eq([to])
        expect(mail.personalisation[:subject]).to eq("Registration status updated for #{course_name} – next steps")

        body = mail.personalisation[:body]
        expect(body).to include(full_name)
        expect(body).to include(provider_name)
        expect(body).to include(course_name)
        expect(body).to include(cohort_date)
        expect(body).to include(sign_in_link)
        expect(body).to include(ecf_id)
      end
    end

    it_behaves_like "a mailer with redacted logs"
  end

  describe "sandbox environment", :sandbox do
    before { allow(Rails.env).to receive(:sandbox?).and_return(true) }

    it "sends confirmation_code emails" do
      mail = described_class.with(to: "test@example.com", code: "123").confirmation_code
      expect(mail.to).to eq(["test@example.com"])
    end

    it "skips other notification emails" do
      mail = described_class.with(to: "test@example.com", full_name: "Test", provider_name: "Test", course_name: "Test", ecf_id: "123").application_submitted
      expect(mail.to).to be_nil
    end
  end
end
