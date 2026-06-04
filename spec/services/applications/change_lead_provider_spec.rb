require "rails_helper"

RSpec.describe Applications::ChangeLeadProvider, type: :model do
  let(:old_provider) { create(:lead_provider) }
  let(:new_provider) { create(:lead_provider) }
  let(:application) { create(:application, :pending, lead_provider: old_provider) }
  let(:new_assignment_date) { Time.zone.now }
  let(:old_application_lead_provider) { build(:application_lead_provider, :unassigned, application:, lead_provider: old_provider) }

  subject(:service) { described_class.new(application:, new_provider:) }

  describe ".call" do
    before do
      travel_to(new_assignment_date) do
        subject.call
      end
    end

    it do
      application.assignment = old_application_lead_provider
      expect(application.reload.lead_provider).to eq(new_provider)
      expect(application.assigned_at).to be_within(5.seconds).of(new_assignment_date)
      expect(application.unassigned_at).to be_within(5.seconds).of(new_assignment_date)
      expect(application.status).to eq(Application::PENDING)
      expect(application.application_lead_providers.previous.last.lead_provider).to eq(old_provider)

      expect(application.application_events.last&.reason).to eq("Changed lead provider from #{old_provider.name} to #{new_provider.name}")
    end

    context "when application not pending or accepted" do
      let(:application) { create(:application, :started, lead_provider: old_provider) }

      it do
        expect(subject).to have_error(:application, :application_cannot_change_provider)
      end
    end

    context "when application provider is same as new provider" do
      let(:application) { create(:application, :pending, lead_provider: new_provider) }

      it do
        expect(subject).to have_error(:base, :provider_must_be_different)
      end
    end

    context "when application has previously been assigned to new provider" do
      let(:application) do
        create(:application, :pending,
               :with_application_lead_provider,
               old_lead_provider: new_provider,
               lead_provider: old_provider)
      end

      it do
        expect(subject).to have_error(:base, :previously_changed_to_provider)
      end
    end
  end

  describe "notification" do
    context "when participants" do
      let(:email_attrs) do
        {
          to: application.user.email,
          full_name: application.user.full_name,
          provider_name: new_provider.name,
          course_name: application.course.name,
          cohort_date: application.cohort.name,
          ecf_id: application.ecf_id,
          sign_in_link: Rails.configuration.sign_in_link,
          feedback_link: Rails.configuration.feedback_link,
        }
      end
      let(:job_attrs) do
        [
          "GenericMailer",
          "change_provider",
          "deliver_now",
          {
            params: email_attrs,
            args: [],
          },
        ]
      end

      it do
        expect { service.call }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with(*job_attrs)
      end
    end

    context "when previous provider" do
      let(:email_attrs) do
        {
          to: old_provider.email,
          provider_name: old_provider.name,
          course_name: application.course.name,
          participant_trn: application.user.trn,
          particitpant_name: application.user.full_name,
          change_date: application.previous_application_lead_provider&.updated_at&.to_fs(:govuk_short),
          ecf_id: application.ecf_id,
        }
      end
      let(:job_attrs) do
        [
          "GenericMailer",
          "previous_provider",
          "deliver_now",
          {
            params: email_attrs,
            args: [],
          },
        ]
      end

      it do
        expect { service.call }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with(*job_attrs)
      end
    end
  end
end
