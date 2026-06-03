# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::FindOrCreateFromTeacherAuth do
  subject(:make_request) { described_class.new(provider_data:, feature_flag_id:).call }

  let(:uid) { "urn:fdc:gov.uk:2022:#{SecureRandom.alphanumeric(43)}" }
  let(:feature_flag_id) { SecureRandom.uuid }
  let(:email) { "user@example.com" }
  let(:trn) { "1234567" }
  let(:verified_name) { %w[Test User] }
  let(:refresh_token) { nil }

  let(:provider_data) do
    OpenStruct.new({
      uid:,
      info: OpenStruct.new({
        email:,
      }),
      extra: OpenStruct.new({
        raw_info: OpenStruct.new({
          trn:,
          verified_name:,
          verified_date_of_birth: "1990-01-01",
        }),
      }),
      credentials: OpenStruct.new({
        refresh_token:,
      }),
    })
  end

  before { create(:user, trn:, archived_at: 1.day.ago) if trn.present? }

  context "when the TRN matches an existing user" do
    let(:user) { create(:user, trn:) }

    before { user }

    it "sets the one_login_id and provider on the user" do
      make_request
      expect(user.reload).to have_attributes(one_login_id: uid, provider: "teacher_auth")
    end

    it "returns the user" do
      expect(make_request).to eq(user)
    end

    context "when user's details have updated" do
      it "updates the user" do
        make_request
        expect(user.reload).to have_attributes(email:, full_name: verified_name.join(" "))
      end
    end
  end

  context "when the TRN matches more than one user" do
    let(:most_recently_updated_user) { create(:user, trn:) }
    let(:older_user) { create(:user, trn:, updated_at: 2.days.ago) }
    let(:application) { create(:application, user: older_user) }

    before do
      travel_to(1.day.ago) { most_recently_updated_user }
      travel_to(2.days.ago) { application }
    end

    it "sets the one_login_id and provider on the most recently updated user" do
      make_request
      expect(most_recently_updated_user.reload).to have_attributes(one_login_id: uid, provider: "teacher_auth")
    end

    it "moves applications to the most recently updated user" do
      make_request
      expect(application.reload.user).to eq(most_recently_updated_user)
    end

    it "archives the other users" do
      make_request
      expect(older_user.reload).to be_archived
    end

    it "creates participant ID records" do
      make_request
      expect(
        most_recently_updated_user.participant_id_changes.find_by(
          from_participant_id: older_user.ecf_id,
          to_participant_id: most_recently_updated_user.ecf_id,
        ),
      ).to be_present
    end

    it "returns the most recently updated user" do
      expect(make_request).to eq(most_recently_updated_user)
    end

    context "when user's details have updated" do
      it "updates the user" do
        make_request
        expect(most_recently_updated_user.reload).to have_attributes(
          email:,
          full_name: verified_name.join(" "),
        )
      end
    end
  end

  shared_examples "logging in using provider and One Login ID" do
    context "when a user exists with the same provider and One Login ID" do
      let(:existing_user) { create(:user, :with_one_login_id, email: "oldemail@example.com", one_login_id: uid) }

      before { existing_user }

      context "when users details have updated" do
        it "updates the user" do
          make_request
          expect(existing_user.reload).to have_attributes(
            email:,
            full_name: verified_name.join(" "),
          )
        end
      end

      context "when the TRN is different" do
        let(:existing_user) { create(:user, :with_one_login_id, email:, one_login_id: uid, trn: "2345678") }

        it "updates the TRN on the user" do
          make_request
          expect(existing_user.reload).to have_attributes(trn:)
        end
      end
    end

    context "when no user exists with the same provider and One Login ID" do
      it "creates a new user" do
        make_request
        expect(User.find_by(provider: "teacher_auth", one_login_id: uid)).to have_attributes(
          email:,
          trn:,
          full_name: verified_name.join(" "),
          date_of_birth: Date.parse("1990-01-01"),
          feature_flag_id:,
        )
      end
    end
  end

  context "when the TRN doesn't match a user" do
    it_behaves_like "logging in using provider and One Login ID"
  end

  context "when no TRN is specified" do
    let(:trn) { nil }
    let(:refresh_token) { "test_refresh_token" }

    context "when a user exists with the same provider and One Login ID" do
      let(:existing_user) { create(:user, :with_one_login_id, one_login_id: uid) }

      before { existing_user }

      it "stores refresh_token and refresh_token_updated_at" do
        freeze_time do
          make_request
          expect(existing_user.reload).to have_attributes(
            refresh_token: "test_refresh_token",
            refresh_token_updated_at: Time.current,
          )
        end
      end
    end

    context "when no user exists with the same provider and One Login ID" do
      it "creates a new user with refresh_token and refresh_token_updated_at" do
        freeze_time do
          make_request
          expect(User.find_by(provider: "teacher_auth", one_login_id: uid)).to have_attributes(
            trn: nil,
            refresh_token: "test_refresh_token",
            refresh_token_updated_at: Time.current,
          )
        end
      end
    end
  end
end
