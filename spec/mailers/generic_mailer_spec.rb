require "rails_helper"

RSpec.describe GenericMailer, type: :mailer do
  describe "#email_updates_confirmation" do
    let(:to) { "recipient@example.com" }
    let(:service_link) { "https://example.com/service" }
    let(:unsubscribe_link) { "https://example.com/unsubscribe" }

    subject(:mail) do
      described_class.with(
        to:,
        service_link:,
        unsubscribe_link:,
      ).email_updates_confirmation
    end

    it do
      aggregate_failures do
        expect(subject).to use_template(GenericMailer::TEMPLATE_ID)
        expect(mail.to).to eq([to])
        expect(mail.personalisation[:subject]).to eq("Email Updates Confirmation")

        body = mail.personalisation[:body]
        expect(body).to include(service_link)
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
        expect(mail.personalisation[:subject]).to eq("Application submitted")

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
        expect(mail.personalisation[:subject]).to eq("Confirmation Code")

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

  describe "notification logging" do
    let(:application) { create(:application) }
    let(:to) { "recipient@example.com" }

    it "creates an application event when ecf_id matches an application" do
      expect {
        described_class.with(to:, ecf_id: application.ecf_id, full_name: "Test", provider_name: "Test", course_name: "Test").application_submitted.deliver_now
      }.to change { application.notifications.count }.by(1)

      event = application.notifications.last
      expect(event.event).to eq("application_submitted")
      expect(event.metadata).to include("to" => to)
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
      expect(event.metadata).to include("to" => to, "cohort_id" => 123)
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
end
