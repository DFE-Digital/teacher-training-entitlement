require "rails_helper"

RSpec.describe Application do
  subject(:application) { create(:application) }

  describe "relationships" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:institution).optional }
    it { is_expected.to have_many(:participant_id_changes).through(:user) }
    it { is_expected.to have_many(:state_changes) }
    it { is_expected.to have_many(:declarations) }
  end

  describe "callbacks" do
    let(:course_cohort) { create(:course_cohort, training_starts_at: Date.new(2026, 9, 1)) }
    let(:new_course_cohort) do
      create(
        :course_cohort,
        course: create(:course),
        cohort: create(:cohort, registration_starts_at: Date.new(2027, 1, 1)),
        training_starts_at: Date.new(2027, 3, 1),
      )
    end

    it "sets training_starts_at from the course cohort on create" do
      application = create(:application, course_cohort:)

      expect(application.training_starts_at).to eq(Date.new(2026, 9, 1))
    end

    it "updates training_starts_at when the course cohort changes" do
      application = create(:application, course_cohort:)

      application.update!(course_cohort: new_course_cohort)

      expect(application.reload.training_starts_at).to eq(Date.new(2027, 3, 1))
    end
  end

  describe "contract" do
    it { expect(application.contract).to be_a(CourseCohortProvider) }
    it { expect(application.contract.lead_provider).to eq(application.lead_provider) }
    it { expect(application.contract.course_cohort).to eq(application.course_cohort) }
  end

  describe "#transition_status!" do
    subject(:application) { create(:application, :started) }

    it "updates the status and records a state change with the reason" do
      expect {
        application.transition_status!(Application::DEFERRED, reason: "other")
      }.to change { application.state_changes.count }.by(1)

      expect(application).to be_deferred_status
      expect(application.state_changes.last.status).to eq(Application::DEFERRED)
      expect(application.state_changes.last.reason).to eq("other")
    end

    it "does not leak the reason into later state changes" do
      application.transition_status!(Application::DEFERRED, reason: "other")

      expect {
        application.transition_status!(Application::STARTED)
      }.to change { application.state_changes.count }.by(1)

      expect(application.state_changes.last.reason).to be_nil
    end
  end

  describe "paper_trail" do
    subject { create(:application, status: Application::PENDING) }

    it "enables paper trail" do
      expect(subject).to be_versioned
    end

    it "creates a version with a note" do
      with_versioning do
        expect(PaperTrail).to be_enabled

        subject.update!(
          status: Application::REJECTED,
          version_note: "This is a test",
        )
        version = subject.versions.last
        expect(version.note).to eq("This is a test")
        expect(version.object_changes["status"]).to eq(%w[pending rejected])
      end
    end
  end

  describe "validations" do
    describe "Status change" do
      context "when invalid transition" do
        it do
          subject.status = Application::COMPLETED
          expect(subject).to have_error(:status, :invalid_status_transition, I18n.t("activerecord.errors.models.application.invalid_status_transition"))
        end
      end

      context "when valid transition" do
        it do
          subject.status = Application::PENDING
          expect(subject).not_to have_error(:status)
        end
      end
    end

    it {
      expect(subject).to validate_uniqueness_of(:ecf_id)
        .case_insensitive
        .with_message("ECF ID must be unique")
    }

    context "when the cohort has a funding cap" do
      let(:cohort) { create(:cohort, :current, :with_funding_cap) }

      context "when accepted" do
        subject { build(:application, :accepted, cohort:) }

        it "validates funded_place is boolean" do
          subject.funded_place = nil

          expect(subject).to have_error(:funded_place, :inclusion, "Set '#/funded_place' to true or false.")
        end

        it "validates funded_place eligibility" do
          subject.funded_place = true
          subject.funding_eligibility = FundingEligibility::INELIGIBLE_SETTING

          expect(subject).to have_error(:funded_place, :not_eligible, "The participant is not eligible for funding, so '#/funded_place' cannot be set to true.")
        end
      end
    end

    context "when the cohort does not have a funding cap" do
      let(:cohort) { create(:cohort, :without_funding_cap, registration_starts_at: Date.new(2024, 5, 1)) }
      let(:course_cohort) { create(:course_cohort, cohort:) }

      subject { build(:application, :accepted, course_cohort:) }

      it "validates funded_place is nil" do
        subject.funded_place = false

        expect(subject).to have_error(:funded_place, :should_not_be_set, "The '#//funded_place' field should not be set for cohorts that do not have a funding cap.")
      end
    end
  end

  describe "enums" do
    it {
      expect(subject).to define_enum_for(:funding_choice).with_values(
        school: "school",
        trust: "trust",
        self: "self",
        another: "another",
        employer: "employer",
      ).backed_by_column_of_type(:enum).with_suffix
    }
  end

  describe "#email" do
    it "returns the user's email" do
      application = build(:application)

      expect(application.email).to eq(application.user.email)
    end
  end

  describe "#can_change_provider?" do
    subject { application.can_change_provider? }

    let(:application) { build(:application, status:) }

    [
      Application::PENDING,
      Application::REJECTED,
    ].each do |application_status|
      context "when the application has #{application_status} status" do
        let(:status) { application_status }

        it { is_expected.to be true }
      end
    end

    [
      Application::ACCEPTED,
      Application::STARTED,
      Application::COMPLETED,
      Application::DEFERRED,
      Application::WITHDRAWN,
    ].each do |application_status|
      context "when the application has #{application_status} status" do
        let(:status) { application_status }

        it { is_expected.to be false }
      end
    end
  end

  describe "scopes" do
    describe ".accepted" do
      it "returns accepted applications" do
        accepted_application = create(:application, :accepted)
        create(:application)

        expect(described_class.has_been_accepted).to contain_exactly(accepted_application)
      end
    end

    describe ".eligible_for_funding" do
      it "returns applications that are eligible for funding" do
        application_eligible_for_funding = create(:application, :eligible_for_funding)
        create(:application, funding_eligibility: :ineligible_setting)

        expect(described_class.eligible_for_funding).to contain_exactly(application_eligible_for_funding)
      end
    end

    describe ".with_email" do
      it "returns applications whose email matches" do
        application = create(:application)
        create(:application)

        expect(described_class.with_email(application.email)).to contain_exactly(application)
      end
    end

    describe ".not_withdrawn" do
      subject { described_class.not_withdrawn.to_a }

      let!(:no_status_application) { create(:application, status: nil) }
      let!(:active_application) { create(:application, :accepted) }
      let!(:deferred_application) { create(:application, :deferred) }

      before do
        create(:application, :withdrawn)
      end

      it { is_expected.to contain_exactly(no_status_application, active_application, deferred_application) }
    end

    describe ".active_applications" do
      subject { described_class.active_applications.to_a }

      let!(:pending_application) { create(:application, :pending) }
      let!(:accepted_application) { create(:application, :accepted) }
      let!(:no_status_application) { create(:application, status: nil) }
      let!(:rejected_application) { create(:application, :rejected) }
      let!(:withdrawn_application) { create(:application, :withdrawn) }

      it "excludes rejected and withdrawn applications" do
        expect(subject).to contain_exactly(pending_application, accepted_application, no_status_application)
        expect(subject).not_to include(rejected_application, withdrawn_application)
      end
    end
  end

  describe "versioning", :versioning do
    context "when changing versioned fields" do
      let(:application) { create(:application, status: Application::PENDING) }

      before do
        application.update!(status: Application::ACCEPTED, funded_place: false)
      end

      it "has history of changes" do
        expect(application.status).to eq(Application::ACCEPTED)

        previous_application = application.versions.last.reify
        expect(previous_application.status).to eq(Application::PENDING)
      end
    end
  end

  describe "updating the user when application changes" do
    let!(:old_datetime) { 6.months.ago }
    let(:user) { create(:user, updated_at: old_datetime) }
    let(:application) { create(:application, :pending, user:) }

    context "when application is updated" do
      before do
        travel_to(old_datetime) do
          user
          application
        end
      end

      context "when status is changed" do
        it "does not update user.updated_at" do
          freeze_time do
            expect(user.updated_at).to be_within(1.second).of(old_datetime)
            expect(application.updated_at).to be_within(1.second).of(old_datetime)

            application.rejected_status!

            expect(application.updated_at).to eq(Time.zone.now)
            expect(user.reload.updated_at).to be_within(1.second).of(old_datetime)
          end
        end
      end
    end
  end

  describe "#deferred_at" do
    subject { application.deferred_at }

    context "when application is not deferred" do
      let(:application) { create(:application, :accepted) }

      it { is_expected.to be_nil }
    end

    context "when application is deferred" do
      let(:application) { create(:application, :deferred) }

      it "returns the created_at of the deferred application event" do
        deferred_event = application.application_events.find { |e| e.status == "deferred" }
        expect(subject).to eq(deferred_event.created_at)
      end
    end
  end

  describe "#withdrawn_at" do
    subject { application.withdrawn_at }

    context "when application is not withdrawn" do
      let(:application) { create(:application, :accepted) }

      it { is_expected.to be_nil }
    end

    context "when application is withdrawn" do
      let(:application) { create(:application, :withdrawn) }

      it "returns the created_at of the withdrawn application event" do
        withdrawn_event = application.application_events.find { |e| e.status == "withdrawn" }
        expect(subject).to eq(withdrawn_event.created_at)
      end
    end
  end

  describe "#reason_for_rejection" do
    subject { application.reason_for_rejection }

    context "when application is not rejected" do
      let(:application) { create(:application, :accepted) }

      it { is_expected.to be_nil }
    end

    context "when application is rejected" do
      let(:application) { create(:application, :rejected, :with_state_change) }

      it { is_expected.to eq("rejected-by-provider") }
    end
  end

  describe "#work_setting" do
    it "reads the work setting from registration_data" do
      application = build(:application, registration_data: { "work_setting" => Institution::OTHER })

      expect(application.work_setting).to eq(Institution::OTHER)
    end
  end

  describe ".with_work_setting" do
    it "filters on the registration_data work setting" do
      school_application = create(:application, registration_data: { "work_setting" => "a_school" })
      create(:application, registration_data: { "work_setting" => Institution::OTHER })

      expect(described_class.with_work_setting("a_school")).to contain_exactly(school_application)
    end
  end

  describe "auditable field for change provider" do
    context "when set" do
      let(:application_lead_provider) { create(:application_lead_provider, :unassigned) }

      before do
        subject.assignment = application_lead_provider
      end

      it { expect(subject.assigned_at).to be_present }
      it { expect(subject.assigned_at).to eq(application_lead_provider.assigned_at) }
      it { expect(subject.unassigned_at).to be_present }
      it { expect(subject.unassigned_at).to eq(application_lead_provider.unassigned_at) }
    end

    context "when omitted" do
      it { expect(subject.assigned_at).to be_nil }
      it { expect(subject.unassigned_at).to be_nil }
    end
  end

  describe "#change_provider!" do
    let(:lead_provider) { create(:lead_provider) }
    let(:another_lead_provider) { create(:lead_provider) }
    let(:assignment_date) { 1.day.ago }
    let(:application) do
      travel_to(assignment_date) { create(:application, lead_provider:) }
    end

    it "marks the current provider as previous and creates a new current provider link" do
      expect(application.application_lead_providers.count).to eq(1)
      expect(application.current_application_lead_provider.lead_provider).to eq(lead_provider)
      expect(application.current_application_lead_provider.current).to be(true)
      expect(application.current_application_lead_provider.assigned_at.to_fs).to eq(assignment_date.to_fs)
      expect(application.current_application_lead_provider.unassigned_at).to be_nil

      application.change_provider!(to: another_lead_provider)

      application_lead_providers = application.application_lead_providers.reload

      expect(application_lead_providers.count).to eq(2)
      previous = application_lead_providers.first
      current = application_lead_providers.last

      expect(previous.lead_provider).to eq(lead_provider)
      expect(previous.current).to be(false)
      expect(previous.assigned_at).to be_present
      expect(previous.unassigned_at).to be_present

      expect(current.lead_provider).to eq(another_lead_provider)
      expect(current.current).to be(true)
      expect(current.assigned_at).to be_present
      expect(current.unassigned_at).to be_nil

      expect(application.reload.lead_provider).to eq(another_lead_provider)
    end

    it "touches the application later" do
      expect(application).to receive(:touch_later).and_call_original

      application.change_provider!(to: another_lead_provider)
    end

    it "does nothing when setting the same lead provider" do
      expect {
        application.change_provider!(to: lead_provider)
      }.not_to change(application.application_lead_providers, :count)

      expect(application.reload.current_application_lead_provider.lead_provider).to eq(lead_provider)
      expect(application.application_lead_providers.current.count).to eq(1)
    end
  end

  describe "#eligible_for_funding?" do
    it "is true when funding_eligibility is funded" do
      expect(build(:application, funding_eligibility: :funded)).to be_eligible_for_funding
    end

    it "is false for any other funding_eligibility" do
      expect(build(:application, funding_eligibility: :ineligible_setting)).not_to be_eligible_for_funding
      expect(build(:application, funding_eligibility: nil)).not_to be_eligible_for_funding
    end
  end

  describe "#funding_ineligible_reason" do
    it "is nil when funded" do
      expect(build(:application, funding_eligibility: :funded).funding_ineligible_reason).to be_nil
    end

    it "is the funding_eligibility otherwise" do
      expect(build(:application, funding_eligibility: :previously_funded).funding_ineligible_reason).to eq("previously_funded")
    end
  end
end
