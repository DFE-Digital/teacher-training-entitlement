# frozen_string_literal: true

require "rails_helper"

RSpec.describe Teachers::FindOrCreateFromTeacherAuth do
  subject(:make_request) { described_class.new(provider_data:, feature_flag_id:).call }

  let(:uid) { "urn:fdc:gov.uk:2022:#{SecureRandom.alphanumeric(43)}" }
  let(:feature_flag_id) { SecureRandom.uuid }
  let(:email) { "user@example.com" }
  let(:trn) { "1234567" }
  let(:verified_name) { %w[Test Teacher] }
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

  before { create(:teacher, trn:, archived_at: 1.day.ago) if trn.present? }

  context "when the TRN matches an existing teacher" do
    let(:teacher) { create(:teacher, trn:) }

    before { teacher }

    it "sets the one_login_id and provider on the teacher" do
      make_request
      expect(teacher.reload).to have_attributes(one_login_id: uid, provider: "teacher_auth")
    end

    it "returns the teacher" do
      expect(make_request).to eq(teacher)
    end

    context "when teacher's details have updated" do
      it "updates the teacher" do
        make_request
        expect(teacher.reload).to have_attributes(email:, full_name: verified_name.join(" "))
      end
    end
  end

  context "when the TRN matches more than one teacher" do
    let(:most_recently_updated_teacher) { create(:teacher, trn:) }
    let(:older_teacher) { create(:teacher, trn:, updated_at: 2.days.ago) }
    let(:application) { create(:application, teacher: older_teacher) }

    before do
      travel_to(1.day.ago) { most_recently_updated_teacher }
      travel_to(2.days.ago) { application }
    end

    it "sets the one_login_id and provider on the most recently updated teacher" do
      make_request
      expect(most_recently_updated_teacher.reload).to have_attributes(one_login_id: uid, provider: "teacher_auth")
    end

    it "moves applications to the most recently updated teacher" do
      make_request
      expect(application.reload.teacher).to eq(most_recently_updated_teacher)
    end

    it "archives the other teachers" do
      make_request
      expect(older_teacher.reload).to be_archived
    end

    it "creates participant ID records" do
      make_request
      expect(
        most_recently_updated_teacher.participant_id_changes.find_by(
          from_participant_id: older_teacher.ecf_id,
          to_participant_id: most_recently_updated_teacher.ecf_id,
        ),
      ).to be_present
    end

    it "returns the most recently updated teacher" do
      expect(make_request).to eq(most_recently_updated_teacher)
    end

    context "when teacher's details have updated" do
      it "updates the teacher" do
        make_request
        expect(most_recently_updated_teacher.reload).to have_attributes(
          email:,
          full_name: verified_name.join(" "),
        )
      end
    end
  end

  shared_examples "logging in using provider and One Login ID" do
    context "when a teacher exists with the same provider and One Login ID" do
      let(:existing_teacher) { create(:teacher, :with_one_login_id, email: "oldemail@example.com", one_login_id: uid) }

      before { existing_teacher }

      context "when teachers details have updated" do
        it "updates the teacher" do
          make_request
          expect(existing_teacher.reload).to have_attributes(
            email:,
            full_name: verified_name.join(" "),
          )
        end
      end

      context "when the TRN is different" do
        let(:existing_teacher) { create(:teacher, :with_one_login_id, email:, one_login_id: uid, trn: "2345678") }

        it "updates the TRN on the teacher" do
          make_request
          expect(existing_teacher.reload).to have_attributes(trn:)
        end
      end
    end

    context "when no teacher exists with the same provider and One Login ID" do
      it "creates a new teacher" do
        make_request
        expect(Teacher.find_by(provider: "teacher_auth", one_login_id: uid)).to have_attributes(
          email:,
          trn:,
          full_name: verified_name.join(" "),
          date_of_birth: Date.parse("1990-01-01"),
          feature_flag_id:,
        )
      end
    end
  end

  context "when the TRN doesn't match a teacher" do
    it_behaves_like "logging in using provider and One Login ID"
  end

  context "when no TRN is specified" do
    let(:trn) { nil }
    let(:refresh_token) { "test_refresh_token" }

    context "when a teacher exists with the same provider and One Login ID" do
      let(:existing_teacher) { create(:teacher, :with_one_login_id, one_login_id: uid) }

      before { existing_teacher }

      it "stores refresh_token and refresh_token_updated_at" do
        freeze_time do
          make_request
          expect(existing_teacher.reload).to have_attributes(
            refresh_token: "test_refresh_token",
            refresh_token_updated_at: Time.current,
          )
        end
      end
    end

    context "when no teacher exists with the same provider and One Login ID" do
      it "creates a new teacher with refresh_token and refresh_token_updated_at" do
        freeze_time do
          make_request
          expect(Teacher.find_by(provider: "teacher_auth", one_login_id: uid)).to have_attributes(
            trn: nil,
            refresh_token: "test_refresh_token",
            refresh_token_updated_at: Time.current,
          )
        end
      end
    end
  end

  describe "email clash handling" do
    context "when another teacher already has the incoming email" do
      context "when clashing teacher has no TRN" do
        let(:clashing_teacher) { create(:teacher, email:, trn: nil) }

        before { clashing_teacher }

        context "when TRN matches an existing teacher" do
          let(:teacher) { create(:teacher, trn:, email: "old@example.com") }

          before { teacher }

          it "archives the clashing teacher" do
            make_request
            expect(clashing_teacher.reload).to be_archived
          end

          it "updates the matched teacher with the new email" do
            make_request
            expect(teacher.reload.email).to eq(email)
          end

          context "when clashing teacher has applications" do
            let!(:clashing_application) { create(:application, teacher: clashing_teacher) }

            it "moves applications to the matched teacher" do
              make_request
              expect(clashing_application.reload.teacher).to eq(teacher)
            end
          end
        end

        context "when one_login_id matches an existing teacher" do
          let(:trn) { nil }
          let(:existing_teacher) { create(:teacher, :with_one_login_id, one_login_id: uid, email: "old@example.com") }

          before { existing_teacher }

          it "archives the clashing teacher" do
            make_request
            expect(clashing_teacher.reload).to be_archived
          end

          it "updates the matched teacher with the new email" do
            make_request
            expect(existing_teacher.reload.email).to eq(email)
          end

          context "when clashing teacher has applications" do
            let!(:clashing_application) { create(:application, teacher: clashing_teacher) }

            it "moves applications to the matched teacher" do
              make_request
              expect(clashing_application.reload.teacher).to eq(existing_teacher)
            end
          end
        end

        context "when creating a new teacher" do
          let(:trn) { nil }

          it "archives the clashing teacher" do
            make_request
            expect(clashing_teacher.reload).to be_archived
          end

          it "creates the new teacher with the email" do
            make_request
            expect(Teacher.find_by(one_login_id: uid).email).to eq(email)
          end
        end
      end

      context "when clashing teacher has a TRN (different verified person)" do
        let(:clashing_teacher) { create(:teacher, email:, trn: "9999999") }

        before { clashing_teacher }

        context "when TRN matches an existing teacher" do
          let(:teacher) { create(:teacher, trn:, email: "old@example.com") }

          before { teacher }

          it "archives the clashing teacher" do
            make_request
            expect(clashing_teacher.reload).to be_archived
          end

          it "updates the matched teacher with the new email" do
            make_request
            expect(teacher.reload.email).to eq(email)
          end

          context "when clashing teacher has applications" do
            let!(:clashing_application) { create(:application, teacher: clashing_teacher) }

            it "does not move applications (different verified person)" do
              make_request
              expect(clashing_application.reload.teacher).to eq(clashing_teacher)
            end
          end
        end

        context "when one_login_id matches an existing teacher" do
          let(:trn) { nil }
          let(:existing_teacher) { create(:teacher, :with_one_login_id, one_login_id: uid, email: "old@example.com") }

          before { existing_teacher }

          it "archives the clashing teacher" do
            make_request
            expect(clashing_teacher.reload).to be_archived
          end

          it "updates the matched teacher with the new email" do
            make_request
            expect(existing_teacher.reload.email).to eq(email)
          end

          context "when clashing teacher has applications" do
            let!(:clashing_application) { create(:application, teacher: clashing_teacher) }

            it "does not move applications (different verified person)" do
              make_request
              expect(clashing_application.reload.teacher).to eq(clashing_teacher)
            end
          end
        end
      end
    end
  end
end
