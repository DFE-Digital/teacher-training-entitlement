require "rails_helper"

RSpec.describe Emails::SendApplicationSubmissionEmailJob, type: :job do
  let(:course) { create(:course, :npd_eirt) }
  let(:application) { create(:application, course:, raw_application_data: { "funding_amount" => "123" }) }

  subject(:job) { described_class.new(application:) }

  describe "#perform" do
    before do
      allow(GenericMailer).to receive(:with).and_call_original
    end

    it "calls `ApplicationSubmissionMailer`" do
      expect(GenericMailer).to receive(:with).with(
        amount: "123",
        to: application.user.email,
        full_name: application.user.full_name,
        provider_name: application.lead_provider.name,
        course_name: course.name,
        ecf_id: application.ecf_id,
      )

      subject.perform_now
    end
  end
end
