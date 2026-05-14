# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Omniauth callbacks", type: :request do
  describe "callback for teacher_auth" do
    before do
      OmniAuth.config.test_mode = true
    end

    describe "POST /users/auth/teacher_auth/callback" do
      subject { post "/users/auth/teacher_auth/callback" }

      let(:uid) { "urn:fdc:gov.uk:2022:#{SecureRandom.alphanumeric(43)}" }
      let(:mock_auth) do
        OmniAuth::AuthHash.new(
          "uid" => uid,
          "info" => {
            "email" => "user@example.com",
          },
          "credentials" => {
            "id_token" => "test-id-token",
          },
          "extra" => {
            "raw_info" => {
              "trn" => "1234567",
              "verified_name" => %w[John Doe],
              "verified_date_of_birth" => "1990-01-01",
            },
          },
        )
      end

      before do
        OmniAuth.config.mock_auth[:teacher_auth] = mock_auth
        Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:teacher_auth]
      end

      context "when omniauth callback is successful" do
        let(:user) { create(:user, :with_teacher_auth_uid) }
        let(:service) { instance_double(Users::FindOrCreateFromTeacherAuth, call: user) }

        before do
          allow(Users::FindOrCreateFromTeacherAuth).to receive(:new).and_return(service)
        end

        it "calls Users::FindOrCreateFromTeacherAuth to find or create a user" do
          expect(Users::FindOrCreateFromTeacherAuth).to receive(:new).with(
            provider_data: mock_auth,
            feature_flag_id: nil,
          )
          subject
        end

        it "signs in the user and redirects" do
          subject
          expect(response).to redirect_to(registration_wizard_show_path("course-start-date"))
        end

        context "when user has applications" do
          before do
            create(:application, user: user)
          end

          it "redirects to user registrations path" do
            subject
            expect(response).to redirect_to(applications_path)
          end
        end
      end

      context "when user creation fails" do
        let(:invalid_user) { build(:user) }
        let(:service) { instance_double(Users::FindOrCreateFromTeacherAuth, call: invalid_user) }

        before do
          allow(Users::FindOrCreateFromTeacherAuth).to receive(:new).and_return(service)
          allow(invalid_user).to receive(:persisted?).and_return(false)
        end

        it "redirects to the failed sign in path" do
          subject
          expect(response).to redirect_to(registration_wizard_show_path(:start))
        end

        it "sets an error flash message" do
          subject
          expect(flash[:error]).to include("There was an error")
        end
      end
    end
  end
end
