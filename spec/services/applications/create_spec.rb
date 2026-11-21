require "rails_helper"

RSpec.describe Applications::Create, type: :model do
  subject(:service) do
    described_class.new(user:, course_cohort:, lead_provider:, institution:, funding_eligibility:, funding_choice:, registration_data:)
  end

  let(:user) { create(:user) }
  let(:cohort) { create(:cohort, :current) }
  let(:course) { Course.reception }
  let(:course_cohort) { create(:course_cohort, course:, cohort:) }
  let(:lead_provider) { LeadProvider.all.sample }
  let(:institution) { create(:school, :funding_eligible_establishment_type_code).institution }
  let(:funding_eligibility) { FundingEligibilities::FUNDED_ELIGIBILITY_RESULT }
  let(:funding_choice) { nil }
  let(:registration_data) { { "teacher_catchment" => "ENG" } }

  describe "validations" do
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:course_cohort) }
    it { is_expected.to validate_presence_of(:lead_provider) }
    it { is_expected.to validate_presence_of(:funding_eligibility) }

    context "when the user already has an application for the course cohort" do
      before { create(:application, user:, course_cohort:) }

      it { is_expected.to have_error(:application, :already_exists, "You already have an application for this course and start date.") }
    end
  end

  describe "#call" do
    let(:application) { user.applications.last }

    it "returns true" do
      expect(service.call).to be(true)
    end

    it "creates one application for the user" do
      expect { service.call }.to change { user.applications.count }.by(1)
    end

    it "exposes the created application" do
      service.call

      expect(service.application).to eq(application)
    end

    it "creates a pending application with the given values" do
      service.call

      expect(application).to have_attributes(
        course_cohort:,
        institution:,
        funding_eligibility: "funded",
        funding_choice: nil,
        status: Application::PENDING,
        registration_data: { "teacher_catchment" => "ENG" },
      )
    end

    it "assigns the current lead provider" do
      service.call

      expect(application.lead_provider).to eq(lead_provider)
    end

    it "records when the lead provider was assigned" do
      service.call

      expect(application.application_lead_providers.first.assigned_at).to be_present
    end

    it "queues the submission email once" do
      expect { service.call }.to have_enqueued_job(Emails::SendApplicationSubmissionEmailJob).once
    end

    it "does not change the user" do
      expect { service.call }.not_to(change { user.reload.attributes })
    end

    context "with a funding choice" do
      let(:funding_eligibility) { FundingEligibilities::INELIGIBLE_SETTING }
      let(:funding_choice) { "school" }

      it "saves the funding choice" do
        service.call

        expect(application.funding_choice).to eq("school")
      end
    end

    context "without an institution" do
      let(:institution) { nil }

      it "creates the application" do
        expect(service.call).to be(true)
      end
    end

    context "when the user already has an application for the course cohort" do
      before { create(:application, user:, course_cohort:) }

      it "returns false" do
        expect(service.call).to be(false)
      end

      it "creates nothing" do
        expect { service.call }.not_to(change { [Application.count, ApplicationLeadProvider.count] })
      end

      it "queues no email" do
        expect { service.call }.not_to have_enqueued_job(Emails::SendApplicationSubmissionEmailJob)
      end
    end

    context "when a concurrent request creates the application first" do
      let!(:existing) { create(:application, user:, course_cohort:) }

      before { allow(service).to receive(:valid?).and_return(true) } # rubocop:disable RSpec/SubjectStub

      it "returns false with a translated error" do
        expect(service.call).to be(false)
        expect(service.errors.full_messages.to_sentence).to eq("Application The application could not be saved.")
      end

      it "exposes the application that now exists" do
        service.call

        expect(service.concurrent_application).to eq(existing)
      end
    end

    context "when the application cannot be saved" do
      before { allow(ApplicationLeadProvider).to receive(:new).and_raise(ActiveRecord::RecordInvalid.new(Application.new)) }

      it "returns false with an error" do
        expect(service.call).to be(false)
        expect(service.errors[:application]).to be_present
      end

      it "creates nothing" do
        expect { service.call }.not_to(change(Application, :count))
      end
    end
  end
end
