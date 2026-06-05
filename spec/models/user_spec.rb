require "rails_helper"

RSpec.describe User do
  subject { create(:user) }

  describe "#active_applications_for(course:)" do
    let!(:cohort) { create(:cohort, :current) }
    let(:course) { create(:course) }
    let(:course_cohort) { create(:course_cohort, course:, cohort:) }
    let(:user) { create(:user) }
    let!(:application) { create(:application, :accepted, user:, course_cohort:) }

    context "when there are active applications for the current cohort and course" do
      it do
        expect(user.active_applications_for(course:, cohort:)).to eq([application])
      end
    end

    context "when there are active applications for a different cohort but same course" do
      let(:previous_cohort) { create(:cohort, :previous) }
      let(:course_cohort) { create(:course_cohort, course:, cohort: previous_cohort) }
      let!(:application) { create(:application, :accepted, user:, course_cohort:) }

      it do
        expect(user.active_applications_for(course:, cohort:)).to be_blank
      end
    end

    context "when there are active applications for the current cohort and but not the specified course" do
      let(:another_course) { create(:course) }

      it do
        expect(user.active_applications_for(course: another_course, cohort:)).to be_blank
      end
    end
  end

  describe "relationships" do
    it { is_expected.to have_many(:applications).dependent(:destroy) }
    it { is_expected.to have_many(:participant_id_changes).order("created_at desc") }
    it { is_expected.to have_many(:declarations).through(:applications) }
  end

  describe "paper_trail" do
    subject { create(:user, full_name: "Joe") }

    it "enables paper trail" do
      expect(subject).to be_versioned
    end

    it "creates a version with a note" do
      with_versioning do
        expect(PaperTrail).to be_enabled

        subject.update!(
          full_name: "Changed Name",
          version_note: "This is a test",
        )
        version = subject.versions.last
        expect(version.note).to eq("This is a test")
        expect(version.object_changes["full_name"]).to eq(["Joe", "Changed Name"])
      end
    end

    context "when user logs in" do
      it "does not create a new version when insignificant attributes remains unchanged" do
        with_versioning do
          expect(PaperTrail).to be_enabled

          expect {
            subject.update!(
              updated_at: 1.second.from_now,
              feature_flag_id: SecureRandom.uuid,
            )
          }.not_to(change { subject.reload.versions.count })
        end
      end

      it "creates a new version when one of significant attributes changes" do
        with_versioning do
          expect(PaperTrail).to be_enabled

          expect {
            subject.update!(
              updated_at: 1.second.from_now,
              updated_from_tra_at: 1.second.from_now,
              trn: "1212121",
              feature_flag_id: SecureRandom.uuid,
            )
          }.to(change { subject.reload.versions.count })
        end
      end
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:full_name).with_message("Enter a full name") }
    it { is_expected.to validate_presence_of(:email).with_message("Enter an email address in the correct format, like name@example.com") }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive.with_message("Email address must be unique") }
    it { is_expected.not_to allow_value("invalid-email").for(:email) }
    it { is_expected.to validate_uniqueness_of(:one_login_id).allow_blank }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF ID must be unique") }
  end

  describe "enums" do
    it {
      expect(subject).to define_enum_for(:email_updates_status).with_values(
        npd_registration_open: "npd_registration_open",
      ).backed_by_column_of_type(:enum).with_suffix
    }
  end

  describe "touch_significantly_updated_at" do
    let(:user) { travel_to(1.day.ago) { create(:user, :without_significantly_updated_at) } }
    let(:significant_change) { { full_name: "New Name" } }
    let(:insignificant_change) { { raw_tra_provider_data: { foo: :bar } } }

    it "sets significantly_updated_at on creation" do
      expect(user.significantly_updated_at).to be_present
    end

    it "sets significantly_updated_at when a significant change is made" do
      expect { user.update!(significant_change) }.to(change { user.reload.significantly_updated_at })
      expect(user.significantly_updated_at).to eq(user.updated_at)
    end

    it "sets significantly_updated_at when a significant change is made alongside an insignificant change" do
      expect { user.update!(significant_change.merge(insignificant_change)) }.to(change { user.reload.significantly_updated_at })
      expect(user.significantly_updated_at).to eq(user.updated_at)
    end

    it "does not update significantly_updated_at when an insignificant change is made" do
      expect { user.update!(insignificant_change) }.not_to(change { user.reload.significantly_updated_at })
    end

    it "updates significantly_updated_at when touched" do
      expect { user.touch(time: 1.day.from_now) }.to(change { user.reload.significantly_updated_at })
      expect(user.significantly_updated_at).to eq(user.updated_at)
    end

    it "does not override significantly_updated_at when setting it explicitly" do
      significantly_updated_at = 1.month.from_now
      user.update!(significant_change.merge(significantly_updated_at:))
      expect(user.significantly_updated_at).to be_within(1.second).of(significantly_updated_at)
    end

    context "when skip_touch_significantly_updated_at is true" do
      before { user.skip_touch_significantly_updated_at = true }

      it "does not update significantly_updated_at" do
        expect { user.touch(time: 1.day.from_now) }.not_to(change { user.reload.significantly_updated_at })
      end
    end
  end

  describe "#latest_participant_outcome" do
    let(:user) { create(:user) }
    let(:lead_provider) { create(:lead_provider) }
    let(:course_identifier) { ParticipantOutcomes::Create::PERMITTED_COURSES.first }
    let(:participant_outcome) { create(:participant_outcome, user:, course:, lead_provider:) }
    let(:course) { Course.find_by!(identifier: course_identifier) }

    subject { user.latest_participant_outcome(lead_provider, course_identifier) }

    before do
      # Older participant outcome.
      travel_to(1.day.ago) { create(:participant_outcome, user:, course:, lead_provider:) }

      travel_to(1.day.from_now) do
        # Not a completed declaration.
        create(:participant_outcome, user:, course:, lead_provider:).declaration.update!(declaration_type: "retained-1")

        # Declaration on another provider.
        create(:participant_outcome, user:, course:, lead_provider: LeadProvider.where.not(id: lead_provider.id).first)

        # Declaration with different course.
        create(:participant_outcome, user:, course: create(:course, identifier: "other-course"), lead_provider:)

        # Declarations that are not billable or voidable.
        Declaration.states.keys.excluding(Declaration::BILLABLE_STATES + Declaration::VOIDABLE_STATES).each do |state|
          create(:participant_outcome, user:, course:, lead_provider:).declaration.update!(state:)
        end
      end

      participant_outcome
    end

    it { is_expected.to eq(participant_outcome) }

    context "when there are no participant outcomes" do
      before { ParticipantOutcome.destroy_all }

      it { is_expected.to be_nil }
    end
  end

  describe "#archived?" do
    context "when user is archived" do
      subject(:user) { build(:user, :archived) }

      it "returns true" do
        expect(user.archived?).to be(true)
      end
    end

    context "when user is not archived" do
      subject(:user) { build(:user) }

      it "returns false" do
        expect(user.archived?).to be(false)
      end
    end
  end

  describe "#set_closed_registration_feature_flag" do
    before do
      Flipper.enable(Feature::CLOSED_REGISTRATION_ENABLED)
      Flipper.disable(Feature::REGISTRATION_OPEN)
    end

    let(:user) { create(:user) }

    context "when user is on the ClosedRegistrationUser list" do
      before do
        ClosedRegistrationUser.create!(email: user.email)
      end

      it "can be added" do
        expect { user.set_closed_registration_feature_flag }.to change { Feature.registration_closed?(user) }.from(true).to(false)
      end
    end

    context "when user is not on the ClosedRegistrationUser list" do
      it "can not be added" do
        expect { user.set_closed_registration_feature_flag }.not_to change { Feature.registration_closed?(user) }.from(true)
      end
    end
  end

  describe "#flipper_id" do
    let(:feature_flag_id) { SecureRandom.uuid }
    let(:user) { build(:user) }

    before do
      allow(user).to receive(:retrieve_or_persist_feature_flag_id).and_return(feature_flag_id)
    end

    it "returns the feature_flag_id prefixed with 'User;'" do
      expect(user.flipper_id).to eq("User;#{feature_flag_id}")
    end
  end

  describe "#set_updated_from_tra_at" do
    let(:user) { create(:user, updated_from_tra_at: nil).reload }

    context "when significant attribute does change" do
      before do
        user.trn = "1231234"
        user.set_updated_from_tra_at
      end

      it "changes updated_from_tra_at" do
        expect(user.updated_from_tra_at).to be_present
      end
    end

    context "when significant attribute does not change" do
      before do
        user.set_updated_from_tra_at
      end

      it "changes updated_from_tra_at" do
        expect(user.updated_from_tra_at).not_to be_present
      end
    end
  end

  describe "#change_unsubscribe_key_on_update_email_status" do
    let(:user) { create(:user, email_updates_unsubscribe_key: "old-key") }

    before do
      allow(SecureRandom).to receive(:uuid).and_return("new-key")
    end

    it "sets a new unsubscribe key when the email updates status changes" do
      expect {
        user.update!(email_updates_status: :npd_registration_open)
      }.to change { user.reload.email_updates_unsubscribe_key }.from("old-key").to("new-key")
    end

    it "clears the unsubscribe key when the email updates status is cleared" do
      user.update_columns(email_updates_status: "npd_registration_open", email_updates_unsubscribe_key: "old-key")

      expect {
        user.update!(email_updates_status: nil)
      }.to change { user.reload.email_updates_unsubscribe_key }.from("old-key").to(nil)
    end
  end

  describe "#retrieve_or_persist_feature_flag_id" do
    let(:feature_flag_id) { SecureRandom.uuid }

    context "when feature_flag_id is nil" do
      let(:user) { create(:user) }

      before do
        allow(SecureRandom).to receive(:uuid).and_return(feature_flag_id)
      end

      it "generates a new feature_flag_id and saves it" do
        expect(user.feature_flag_id).to be_nil

        expect(user.retrieve_or_persist_feature_flag_id).to eq(feature_flag_id)
      end
    end

    context "when feature_flag_id is already present" do
      let(:feature_flag_id) { SecureRandom.uuid }
      let(:user) { create(:user, feature_flag_id:) }

      it "returns the correct flag id" do
        expect(user.retrieve_or_persist_feature_flag_id).to eq(feature_flag_id)
      end
    end
  end

  context "when email has upcase characters" do
    let(:user) { build(:user, email: "Foo@example.com") }

    before do
      user.save
    end

    it "downcases email during saving" do
      expect(user.reload.email).to eq("foo@example.com")
    end
  end

  describe "#requires_token_refresh?" do
    subject { user.requires_token_refresh? }

    context "when user has no TRN, has refresh token, and no trn_requested_at" do
      let(:user) { create(:user, trn: nil, refresh_token: "token", trn_requested_at: nil) }

      it { is_expected.to be true }
    end

    context "when user has TRN" do
      let(:user) { create(:user, trn: "1234567", refresh_token: "token", trn_requested_at: nil) }

      it { is_expected.to be false }
    end

    context "when user has no refresh token" do
      let(:user) { create(:user, trn: nil, refresh_token: nil, trn_requested_at: nil) }

      it { is_expected.to be false }
    end

    context "when user has trn_requested_at set" do
      let(:user) { create(:user, trn: nil, refresh_token: "token", trn_requested_at: 1.hour.ago) }

      it { is_expected.to be false }
    end
  end

  describe ".requiring_token_refresh" do
    subject { described_class.requiring_token_refresh }

    let!(:user_needing_refresh) { create(:user, trn: nil, refresh_token: "token", refresh_token_updated_at: 2.days.ago) }

    it "includes users without TRN, with refresh token, and stale refresh" do
      expect(subject).to include(user_needing_refresh)
    end

    it "excludes users with TRN" do
      user_with_trn = create(:user, trn: "1234567", refresh_token: "token", refresh_token_updated_at: 2.days.ago)
      expect(subject).not_to include(user_with_trn)
    end

    it "excludes users without refresh token" do
      user_no_token = create(:user, trn: nil, refresh_token: nil)
      expect(subject).not_to include(user_no_token)
    end

    it "excludes users with recent refresh" do
      user_recent_refresh = create(:user, trn: nil, refresh_token: "token", refresh_token_updated_at: 1.hour.ago)
      expect(subject).not_to include(user_recent_refresh)
    end

    it "excludes users with TRN already requested" do
      user_trn_requested = create(:user, trn: nil, refresh_token: "token", refresh_token_updated_at: 2.days.ago, trn_requested_at: 1.hour.ago)
      expect(subject).not_to include(user_trn_requested)
    end
  end
end
