require "rails_helper"

RSpec.describe Registration::Operations::CreateApplication do
  subject(:operation) { described_class.new(repository:, step:) }

  let(:step) { wizard.step(:check_answers) }

  let(:repository) { DfE::Wizard::Repository::InMemory.new }
  let(:state_store) { Registration::StateStore.new(repository:) }
  let(:wizard) { Registration::Wizard.new(course:, current_user: user, current_step: :check_answers, state_store:) }
  let(:user) { create(:user) }
  let(:course) { create(:course) }
  let(:course_cohort) { course.course_cohorts.first }
  let(:provider) { course_cohort.lead_providers.first }
  let(:institution) { create(:institution, :with_address) }
  let(:answers) do
    {
      course_start_date: course_cohort.ecf_id,
      lead_provider_id: provider.id.to_s,
      teacher_catchment: Institution::ENGLAND_SUBDIVISION_CODE,
      work_setting: Institution::STATE_FUNDED_INSTITUTION,
      institution_id: institution.id.to_s,
      institution_name: "open",
      can_share_choices: "1",
    }
  end
  let(:application) { user.applications.last }

  before { repository.write(answers) }

  describe "#execute" do
    it "succeeds" do
      expect(operation.execute).to eq(success: true)
    end

    it "creates a pending application with the selected answers" do
      operation.execute

      expect(application).to have_attributes(course_cohort:, lead_provider: provider, institution:, status: Application::PENDING)
    end

    it "takes the funding result from the course rule set" do
      operation.execute

      expect(application.funding_eligibility).to eq("funded")
    end

    context "when a concurrent request has created the application" do
      let!(:existing) { create(:application, user:, course_cohort:) }

      before { allow_any_instance_of(Applications::Create).to receive(:valid?).and_return(true) }

      it "succeeds" do
        expect(operation.execute).to eq(success: true)
      end

      it "keeps the existing application to show the submitted page" do
        operation.execute

        expect(state_store.submitted_application).to eq(existing)
      end
    end

    it "queues the submission email once" do
      expect { operation.execute }.to have_enqueued_job(Emails::SendApplicationSubmissionEmailJob).once
    end

    it "clears the answers" do
      operation.execute

      expect(repository.read.keys.map(&:to_s)).to eq([Registration::StateStore::SUBMITTED_APPLICATION_KEY.to_s])
    end

    it "keeps the created application to show the submitted page" do
      operation.execute

      expect(state_store.submitted_application).to eq(application)
    end

    context "when the teacher picked a funding option, then went back to a funded route" do
      before { repository.write(funding: "school") }

      it "leaves the funding choice empty" do
        operation.execute

        expect(application.funding_choice).to be_nil
      end
    end

    context "when the teacher is not funded" do
      before { repository.write(teacher_catchment: Institution::OTHER, funding: "self") }

      it "saves the funding choice" do
        operation.execute

        expect(application).to have_attributes(funding_eligibility: "ineligible_setting", funding_choice: "self")
      end
    end

    describe "registration data" do
      let(:application_data) { application.registration_data }

      before { operation.execute }

      it "has the keys of the legacy journey" do
        expect(application_data).to eq(
          "can_share_choices" => "1",
          "course_cohort_ecf_id" => course_cohort.ecf_id,
          "course_start_date" => course_cohort.ecf_id,
          "funding_amount" => nil,
          "institution_id" => institution.id.to_s,
          "institution_name" => "open",
          "lead_provider_id" => provider.id.to_s,
          "submitted" => true,
          "teacher_catchment" => Institution::ENGLAND_SUBDIVISION_CODE,
          "work_setting" => Institution::STATE_FUNDED_INSTITUTION,
        )
      end

      context "with cleared answers and wizard internal keys" do
        let(:answers) { super().merge(work_setting: Institution::PRIVATE_INSTITUTION, funding: nil, institution_id: nil, funding_amount: 200, submitted_application_id: 1, something: "internal") }

        it "leaves them out, as the legacy journey deleted the cleared ones" do
          expect(application_data.keys).not_to include("funding", "institution_id", "submitted_application_id", "something")
        end

        it "empties the funding amount, as the legacy journey did" do
          expect(application_data).to include("funding_amount" => nil)
        end
      end
    end

    context "when the application cannot be created" do
      before { create(:application, user:, course_cohort:) }

      it "fails" do
        expect(operation.execute).to include(success: false)
      end

      it "adds an error to the step" do
        operation.execute

        expect(step.errors.full_messages).to eq(["We could not submit your registration. Check you have not already registered for this course and start date, or try again."])
      end

      it "creates nothing" do
        expect { operation.execute }.not_to(change(Application, :count))
      end

      it "keeps the answers" do
        operation.execute

        expect(repository.read[:course_start_date]).to eq(course_cohort.ecf_id)
      end
    end
  end
end
