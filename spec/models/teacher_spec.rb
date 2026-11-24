require "rails_helper"

RSpec.describe Teacher do
  subject { create(:teacher) }

  describe "relationships" do
    it { is_expected.to have_many(:applications).dependent(:destroy) }
    it { is_expected.to have_many(:participant_id_changes).order("created_at desc") }
    it { is_expected.to have_many(:declarations).through(:applications) }
  end

  describe "paper_trail" do
    subject { create(:teacher, full_name: "Joe") }

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

    context "when teacher logs in" do
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
    let(:teacher) { travel_to(1.day.ago) { create(:teacher, :without_significantly_updated_at) } }
    let(:significant_change) { { full_name: "New Name" } }
    let(:insignificant_change) { { raw_tra_provider_data: { foo: :bar } } }

    it "sets significantly_updated_at on creation" do
      expect(teacher.significantly_updated_at).to be_present
    end

    it "sets significantly_updated_at when a significant change is made" do
      expect { teacher.update!(significant_change) }.to(change { teacher.reload.significantly_updated_at })
      expect(teacher.significantly_updated_at).to eq(teacher.updated_at)
    end

    it "sets significantly_updated_at when a significant change is made alongside an insignificant change" do
      expect { teacher.update!(significant_change.merge(insignificant_change)) }.to(change { teacher.reload.significantly_updated_at })
      expect(teacher.significantly_updated_at).to eq(teacher.updated_at)
    end

    it "does not update significantly_updated_at when an insignificant change is made" do
      expect { teacher.update!(insignificant_change) }.not_to(change { teacher.reload.significantly_updated_at })
    end

    it "updates significantly_updated_at when touched" do
      expect { teacher.touch(time: 1.day.from_now) }.to(change { teacher.reload.significantly_updated_at })
      expect(teacher.significantly_updated_at).to eq(teacher.updated_at)
    end

    it "does not override significantly_updated_at when setting it explicitly" do
      significantly_updated_at = 1.month.from_now
      teacher.update!(significant_change.merge(significantly_updated_at:))
      expect(teacher.significantly_updated_at).to be_within(1.second).of(significantly_updated_at)
    end

    context "when skip_touch_significantly_updated_at is true" do
      before { teacher.skip_touch_significantly_updated_at = true }

      it "does not update significantly_updated_at" do
        expect { teacher.touch(time: 1.day.from_now) }.not_to(change { teacher.reload.significantly_updated_at })
      end
    end
  end

  describe "#archived?" do
    context "when teacher is archived" do
      subject(:teacher) { build(:teacher, :archived) }

      it "returns true" do
        expect(teacher.archived?).to be(true)
      end
    end

    context "when teacher is not archived" do
      subject(:teacher) { build(:teacher) }

      it "returns false" do
        expect(teacher.archived?).to be(false)
      end
    end
  end

  describe "#set_closed_registration_feature_flag" do
    before do
      Flipper.enable(Feature::CLOSED_REGISTRATION_ENABLED)
      Flipper.disable(Feature::REGISTRATION_OPEN)
    end

    let(:teacher) { create(:teacher) }

    context "when teacher is on the ClosedRegistrationUser list" do
      before do
        ClosedRegistrationUser.create!(email: teacher.email)
      end

      it "can be added" do
        expect { teacher.set_closed_registration_feature_flag }.to change { Feature.registration_closed?(teacher) }.from(true).to(false)
      end
    end

    context "when teacher is not on the ClosedRegistrationUser list" do
      it "can not be added" do
        expect { teacher.set_closed_registration_feature_flag }.not_to change { Feature.registration_closed?(teacher) }.from(true)
      end
    end
  end

  describe "#flipper_id" do
    let(:feature_flag_id) { SecureRandom.uuid }
    let(:teacher) { build(:teacher) }

    before do
      allow(teacher).to receive(:retrieve_or_persist_feature_flag_id).and_return(feature_flag_id)
    end

    it "returns the feature_flag_id prefixed with 'Teacher;'" do
      expect(teacher.flipper_id).to eq("Teacher;#{feature_flag_id}")
    end
  end

  describe "#set_updated_from_tra_at" do
    let(:teacher) { create(:teacher, updated_from_tra_at: nil).reload }

    context "when significant attribute does change" do
      before do
        teacher.trn = "1231234"
        teacher.set_updated_from_tra_at
      end

      it "changes updated_from_tra_at" do
        expect(teacher.updated_from_tra_at).to be_present
      end
    end

    context "when significant attribute does not change" do
      before do
        teacher.set_updated_from_tra_at
      end

      it "changes updated_from_tra_at" do
        expect(teacher.updated_from_tra_at).not_to be_present
      end
    end
  end

  describe "#change_unsubscribe_key_on_update_email_status" do
    let(:teacher) { create(:teacher, email_updates_unsubscribe_key: "old-key") }

    before do
      allow(SecureRandom).to receive(:uuid).and_return("new-key")
    end

    it "sets a new unsubscribe key when the email updates status changes" do
      expect {
        teacher.update!(email_updates_status: :npd_registration_open)
      }.to change { teacher.reload.email_updates_unsubscribe_key }.from("old-key").to("new-key")
    end

    it "clears the unsubscribe key when the email updates status is cleared" do
      teacher.update_columns(email_updates_status: "npd_registration_open", email_updates_unsubscribe_key: "old-key")

      expect {
        teacher.update!(email_updates_status: nil)
      }.to change { teacher.reload.email_updates_unsubscribe_key }.from("old-key").to(nil)
    end
  end

  describe "#retrieve_or_persist_feature_flag_id" do
    let(:feature_flag_id) { SecureRandom.uuid }

    context "when feature_flag_id is nil" do
      let(:teacher) { create(:teacher) }

      before do
        allow(SecureRandom).to receive(:uuid).and_return(feature_flag_id)
      end

      it "generates a new feature_flag_id and saves it" do
        expect(teacher.feature_flag_id).to be_nil

        expect(teacher.retrieve_or_persist_feature_flag_id).to eq(feature_flag_id)
      end
    end

    context "when feature_flag_id is already present" do
      let(:feature_flag_id) { SecureRandom.uuid }
      let(:teacher) { create(:teacher, feature_flag_id:) }

      it "returns the correct flag id" do
        expect(teacher.retrieve_or_persist_feature_flag_id).to eq(feature_flag_id)
      end
    end
  end

  context "when email has upcase characters" do
    let(:teacher) { build(:teacher, email: "Foo@example.com") }

    before do
      teacher.save
    end

    it "downcases email during saving" do
      expect(teacher.reload.email).to eq("foo@example.com")
    end
  end

  describe "#requires_token_refresh?" do
    subject { teacher.requires_token_refresh? }

    context "when teacher has no TRN, has refresh token, and no trn_requested_at" do
      let(:teacher) { create(:teacher, trn: nil, refresh_token: "token", trn_requested_at: nil) }

      it { is_expected.to be true }
    end

    context "when teacher has TRN" do
      let(:teacher) { create(:teacher, trn: "1234567", refresh_token: "token", trn_requested_at: nil) }

      it { is_expected.to be false }
    end

    context "when teacher has no refresh token" do
      let(:teacher) { create(:teacher, trn: nil, refresh_token: nil, trn_requested_at: nil) }

      it { is_expected.to be false }
    end

    context "when teacher has trn_requested_at set" do
      let(:teacher) { create(:teacher, trn: nil, refresh_token: "token", trn_requested_at: 1.hour.ago) }

      it { is_expected.to be false }
    end
  end

  describe ".requiring_token_refresh" do
    subject { described_class.requiring_token_refresh }

    let!(:teacher_needing_refresh) { create(:teacher, trn: nil, refresh_token: "token", refresh_token_updated_at: 2.days.ago) }

    it "includes teachers without TRN, with refresh token, and stale refresh" do
      expect(subject).to include(teacher_needing_refresh)
    end

    it "excludes teachers with TRN" do
      teacher_with_trn = create(:teacher, trn: "1234567", refresh_token: "token", refresh_token_updated_at: 2.days.ago)
      expect(subject).not_to include(teacher_with_trn)
    end

    it "excludes teachers without refresh token" do
      teacher_no_token = create(:teacher, trn: nil, refresh_token: nil)
      expect(subject).not_to include(teacher_no_token)
    end

    it "excludes teachers with recent refresh" do
      teacher_recent_refresh = create(:teacher, trn: nil, refresh_token: "token", refresh_token_updated_at: 1.hour.ago)
      expect(subject).not_to include(teacher_recent_refresh)
    end

    it "excludes teachers with TRN already requested" do
      teacher_trn_requested = create(:teacher, trn: nil, refresh_token: "token", refresh_token_updated_at: 2.days.ago, trn_requested_at: 1.hour.ago)
      expect(subject).not_to include(teacher_trn_requested)
    end
  end

  describe ".needing_trn_activation_check" do
    subject { described_class.needing_trn_activation_check }

    let!(:teacher_needing_check) { create(:teacher, trn: nil, refresh_token: "token", trn_requested_at: 1.day.ago) }

    it "includes teachers without TRN, with refresh token, and with trn_requested_at set" do
      expect(subject).to include(teacher_needing_check)
    end

    it "excludes teachers with TRN" do
      teacher_with_trn = create(:teacher, trn: "1234567", refresh_token: "token", trn_requested_at: 1.day.ago)
      expect(subject).not_to include(teacher_with_trn)
    end

    it "excludes teachers without refresh token" do
      teacher_no_token = create(:teacher, trn: nil, refresh_token: nil, trn_requested_at: 1.day.ago)
      expect(subject).not_to include(teacher_no_token)
    end

    it "excludes teachers without trn_requested_at" do
      teacher_not_requested = create(:teacher, trn: nil, refresh_token: "token", trn_requested_at: nil)
      expect(subject).not_to include(teacher_not_requested)
    end
  end

  describe "#can_request_trn?" do
    it "returns true when teacher has no TRN and has refresh token" do
      teacher = build(:teacher, trn: nil, refresh_token: "token")
      expect(teacher.can_request_trn?).to be true
    end

    it "returns false when teacher has TRN" do
      teacher = build(:teacher, trn: "1234567", refresh_token: "token")
      expect(teacher.can_request_trn?).to be false
    end

    it "returns false when teacher has no refresh token" do
      teacher = build(:teacher, trn: nil, refresh_token: nil)
      expect(teacher.can_request_trn?).to be false
    end
  end

  describe "#clear_auth_tokens!" do
    let(:teacher) { create(:teacher, refresh_token: "token", refresh_token_updated_at: 1.day.ago) }

    it "clears refresh_token and refresh_token_updated_at" do
      teacher.clear_auth_tokens!
      expect(teacher.reload).to have_attributes(refresh_token: nil, refresh_token_updated_at: nil)
    end
  end
end
