require "rails_helper"

RSpec.describe Emails::SendApplicationSubmissionEmailJob, type: :job do
  let(:course) { create(:course, :npd_eirt) }
  let(:application) { create(:application, course:, raw_application_data: { "funding_amount" => "123" }) }

  subject(:job) { described_class.new(application:) }

  describe "#perform" do
    let(:message) { instance_double(ActionMailer::MessageDelivery) }
    let(:mailer) { instance_double(GenericMailer, application_submitted: message) }

    before do
      allow(GenericMailer).to receive(:with).and_return(mailer)
      allow(message).to receive(:deliver_now)
    end

    it "calls `ApplicationSubmissionMailer`" do
      expect(GenericMailer).to receive(:with).with(
        to: application.user.email,
        full_name: application.user.full_name,
        provider_name: application.lead_provider.name,
        course_name: course.name,
        cohort_date: application.cohort.name,
        ecf_id: application.ecf_id,
        sign_in_link: Rails.configuration.sign_in_link,
        feedback_link: Rails.configuration.feedback_link,
      )

      subject.perform_now
    end
  end
end
