require "rails_helper"

RSpec.describe Application do
  subject(:application) { create(:application) }

  describe "relationships" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:institution).optional }
    it { is_expected.to have_many(:participant_id_changes).through(:user) }
    it { is_expected.to have_many(:state_changes) }
    it { is_expected.to have_many(:declarations) }
    it { is_expected.to have_one(:contract).through(:course_cohort) }
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
          subject.eligible_for_funding = false

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
      expect(subject).to define_enum_for(:kind_of_nursery).with_values(
        local_authority_maintained_nursery: "local_authority_maintained_nursery",
        preschool_class_as_part_of_school: "preschool_class_as_part_of_school",
        private_nursery: "private_nursery",
        another_early_years_setting: "another_early_years_setting",
        childminder: "childminder",
      ).backed_by_column_of_type(:enum).with_suffix
    }

    it {
      expect(subject).to define_enum_for(:funding_choice).with_values(
        school: "school",
        trust: "trust",
        self: "self",
        another: "another",
        employer: "employer",
      ).backed_by_column_of_type(:enum).with_suffix
    }

    it "defines an enum for review_status" do
      expect(subject).to define_enum_for(:review_status).with_values(
        "Needs review" => "needs_review",
        "Awaiting information" => "awaiting_information",
        "Re-register" => "reregister",
        "Decision made" => "decision_made",
      ).backed_by_column_of_type(:enum).with_suffix
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
        create(:application, eligible_for_funding: false)

        expect(described_class.eligible_for_funding).to contain_exactly(application_eligible_for_funding)
      end
    end

    describe ".for_manual_review" do
      subject { described_class.for_manual_review.to_a }

      before { application }

      let(:application) { create(:application, review_status:) }
      let(:review_status) { nil }

      it { is_expected.not_to include(application) }

      Application.review_statuses.each_value do |enum_value|
        context "with review_status of #{enum_value}" do
          let(:review_status) { enum_value }

          it { is_expected.to include(application) }
        end
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
      let!(:withdrawn_application) { create(:application, :withdrawn) }

      it "excludes withdrawn applications" do
        expect(subject).to contain_exactly(pending_application, accepted_application)
        expect(subject).not_to include(withdrawn_application)
      end
    end
  end

  describe "#inside_catchment?" do
    subject { application.inside_catchment? }

    let(:application) do
      if school
        create(:application, course_cohort:, school_record: school, teacher_catchment:)
      else
        create(:application, course_cohort:, institution: nil, teacher_catchment:, works_in_school: false)
      end
    end
    let(:course_cohort) { create(:course_cohort, cohort:) }

    context "when the application is in the 2023 cohort or earlier" do
      let(:cohort) { create(:cohort, registration_starts_at: Date.new(2023, 4, 1)) }

      context "when the teacher_catchment is not set" do
        let(:teacher_catchment) { nil }

        context "when the application has an English school" do
          let(:school) { create(:school, urn: "100000") }

          it { is_expected.to be true }
        end

        context "when the application has a Welsh school" do
          let(:school) { create(:school, urn: "401344") }

          it { is_expected.to be false }
        end

        context "when the application has a school that is a children's centre" do
          let(:school) { create(:school, urn: "20001") }

          it { is_expected.to be false }
        end

        context "when the application has no school" do
          let(:school) { nil }

          it { is_expected.to be false }
        end
      end
    end

    context "when the application is in the 2024 cohort or later" do
      let(:cohort) { create(:cohort, registration_starts_at: Date.new(2024, 4, 1)) }
      let(:school) { nil }

      context "when the teacher_catchment is not set" do
        let(:teacher_catchment) { nil }

        context "when the application has an English school" do
          let(:school) { create(:school, urn: "100000") }

          it { is_expected.to be false }
        end
      end

      context "when the teacher_catchment is set to England" do
        let(:teacher_catchment) { "england" }

        it { is_expected.to be true }
      end

      context "when the teacher_catchment is set to Scotland" do
        let(:teacher_catchment) { "scotland" }

        it { is_expected.to be false }
      end
    end
  end

  describe "#inside_uk_catchment?" do
    it { expect(build(:application, teacher_catchment: "england")).to be_inside_uk_catchment }
    it { expect(build(:application, teacher_catchment: "scotland")).to be_inside_uk_catchment }
    it { expect(build(:application, teacher_catchment: "wales")).to be_inside_uk_catchment }
    it { expect(build(:application, teacher_catchment: "northern_ireland")).to be_inside_uk_catchment }
    it { expect(build(:application, teacher_catchment: "jersey_guernsey_isle_of_man")).to be_inside_uk_catchment }
    it { expect(build(:application, teacher_catchment: "other")).not_to be_inside_uk_catchment }
  end

  describe "#employer_name" do
    shared_examples "employer_name" do
      it "displays proper employer_name" do
        expect(application.employer_name_to_display).to eq(name)
      end
    end

    context "when the application has school attached" do
      let(:school) { create(:school) }
      let(:name) { school.name }
      let(:application) { build(:application, school_record: school) }

      include_examples "employer_name"
    end

    context "when the application has private childcare provider" do
      let(:private_childcare_provider) { create(:private_childcare_provider) }
      let(:name) { private_childcare_provider.name }
      let(:application) { build(:application, :with_private_childcare_provider, provider_record: private_childcare_provider) }

      include_examples "employer_name"
    end

    context "when no institution is available" do
      let(:name) { "" }
      let(:application) { build(:application, institution: nil, works_in_school: false) }

      include_examples "employer_name"
    end
  end

  describe "versioning", :versioning do
    context "when changing versioned fields" do
      let(:application) { create(:application, status: Application::PENDING, participant_outcome_state: nil) }

      before do
        application.update!(status: Application::ACCEPTED, participant_outcome_state: "passed", funded_place: false)
      end

      it "has history of changes" do
        previous_application = application.versions.last.reify
        expect(application.status).to eq(Application::ACCEPTED)
        expect(application.participant_outcome_state).to eq("passed")

        expect(previous_application.status).to eq(Application::PENDING)
        expect(previous_application.participant_outcome_state).to be_nil
      end
    end
  end

  describe "#eligible_for_dfe_funding?" do
    let(:user) { create(:user) }

    subject { application }

    context "when application has been previously funded" do
      let(:application) { create(:application, :previously_funded, user:, course:) }
      let(:course) { create(:course) }

      it { is_expected.not_to be_eligible_for_dfe_funding }
    end

    context "when application has not been previously funded" do
      let(:application) { create(:application, user:, course:) }
      let(:course) { create(:course) }

      it "is not eligible for DfE funding if not eligible for funding" do
        application.update!(eligible_for_funding: false)

        expect(application).not_to be_eligible_for_dfe_funding
      end

      it "is eligible for DfE funding if the application is eligible for funding" do
        application.update!(eligible_for_funding: true)

        expect(application).to be_eligible_for_dfe_funding
      end
    end
  end

  describe "#previously_funded?" do
    let(:user) { create(:user) }
    let(:course) { create(:course) }
    let(:course_cohort) { create(:course_cohort, course:, cohort: cohort_with_funding_cap) }
    let(:application) { create(:application, :previously_funded, user:, course_cohort:) }
    let(:cohort_with_funding_cap) { create(:cohort, :with_funding_cap, registration_starts_at: Date.new(2024, 5, 1)) }
    let(:cohort_without_funding_cap) { create(:cohort, :without_funding_cap, registration_starts_at: Date.new(2024, 6, 1)) }
    let(:previous_application) { user.applications.where.not(id: application.id).first! }
    let(:course_cohort_no_cap) { create(:course_cohort, course:, cohort: cohort_without_funding_cap) }

    subject { application }

    context "when the application has been previously funded" do
      it { is_expected.to be_previously_funded }

      context "when funded place is `nil`" do
        before do
          previous_application.update!(
            course_cohort: course_cohort_no_cap,
            funded_place: nil,
          )
        end

        it { is_expected.to be_previously_funded }
      end

      context "when funded place is `false`" do
        before { previous_application.update!(funded_place: false) }

        it { is_expected.not_to be_previously_funded }
      end

      context "when funded place is `true`" do
        before { previous_application.update!(funded_place: true) }

        it { is_expected.to be_previously_funded }
      end
    end

    context "when the application has not been previously funded (previous application not accepted)" do
      before { previous_application.update_column(:status, Application::REJECTED) }

      it { is_expected.not_to be_previously_funded }
    end

    context "when the application has not been previously funded (previous application is not eligible for funding)" do
      before { previous_application.update!(eligible_for_funding: false, funded_place: false) }

      it { is_expected.not_to be_previously_funded }
    end

    context "when transient_previously_funded is declared on the model" do
      subject { create(:application, eligible_for_funding: false) }

      before do
        def subject.transient_previously_funded
          false
        end
      end

      it "does not make a query to determine the previously_funded status" do
        expect(Application).not_to receive(:connection)
        expect(subject).not_to be_previously_funded
      end

      context "when transient_previously_funded is true" do
        before do
          def subject.transient_previously_funded
            true
          end
        end

        it "does not make a query to determine the previously_funded status" do
          expect(Application).not_to receive(:connection)
          expect(subject).to be_previously_funded
        end
      end
    end
  end

  describe "#ineligible_for_funding_reason" do
    subject { application.ineligible_for_funding_reason }

    context "when not previously funded or eligible_for_funding" do
      let(:application) { create(:application) }

      it { is_expected.to eq("establishment-ineligible") }
    end

    context "when not previously funded and eligible_for_funding" do
      let(:application) { create(:application, :eligible_for_funding) }

      it { is_expected.to be_nil }
    end

    context "when previously funded" do
      let(:application) { create(:application, :previously_funded) }

      it { is_expected.to eq("previously-funded") }
    end

    context "when transient_previously_funded is declared on the model" do
      subject { create(:application, eligible_for_funding: false) }

      before do
        def subject.transient_previously_funded
          false
        end
      end

      it "does not make a query to determine the previously_funded status" do
        expect(Application).not_to receive(:connection)
        expect(subject.ineligible_for_funding_reason).to eq("establishment-ineligible")
      end

      context "when transient_previously_funded is true" do
        before do
          def subject.transient_previously_funded
            true
          end
        end

        it "does not make a query to determine the previously_funded status" do
          expect(Application).not_to receive(:connection)
          expect(subject.ineligible_for_funding_reason).to eq("previously-funded")
        end
      end
    end
  end

  describe "#fundable?" do
    context "when it is eligible_for_funding" do
      subject { create(:application, eligible_for_funding: true, funded_place: nil) }

      it { is_expected.to be_fundable }
    end

    context "when it is not eligible_for_funding" do
      subject { create(:application, eligible_for_funding: false, funded_place: nil) }

      it { is_expected.not_to be_fundable }
    end

    context "when it is eligible_for_funding but has no funded place" do
      subject { create(:application, eligible_for_funding: true, funded_place: false) }

      it { is_expected.not_to be_fundable }
    end

    context "when it is eligible_for_funding but and has a funded place" do
      subject { create(:application, eligible_for_funding: true, funded_place: true) }

      it { is_expected.to be_fundable }
    end

    context "when it is not eligible_for_funding but and has a funded false" do
      subject { create(:application, eligible_for_funding: false, funded_place: false) }

      it { is_expected.not_to be_fundable }
    end

    context "when it was previously funded" do
      subject(:application) { create(:application, :eligible_for_funding, :previously_funded, user:, course:) }

      let(:user) { create(:user) }
      let(:course) { create(:course) }

      it { is_expected.not_to be_fundable }

      context "when is marked eligible by policy" do
        before { application.update!(funding_eligiblity_status_code: :marked_funded_by_policy) }

        it { is_expected.to be_fundable }
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

  describe "#latest_participant_outcome_state" do
    subject { application.latest_participant_outcome_state }

    let(:application) { create(:application, :accepted, participant_outcome_state: "anything") }
    let(:declaration) { create(:declaration, :completed, application:) }
    let!(:participant_outcome) { create(:participant_outcome, declaration:) }

    it "returns the state from latest outcome" do
      expect(subject).to eq("passed")
    end

    context "when no completed declaration exists" do
      before { declaration.update!(application: create(:application)) }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when other type of declaration exists" do
      before { declaration.update!(declaration_type: "retained-1") }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when completed declaration is voided" do
      before do
        declaration.update!(state: "voided")
        participant_outcome.update!(state: "voided")
      end

      it "returns nil" do
        expect(subject).to be_nil
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
end
