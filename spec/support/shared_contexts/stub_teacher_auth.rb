RSpec.shared_context("Stub Teacher Auth Responses") do
  include Helpers::TeacherLogin

  let(:teacher_first_name) { "John" }
  let(:teacher_last_name) { "Doe" }
  let(:teacher_preferred_name) { "#{teacher_first_name} #{teacher_last_name}" }
  let(:teacher_full_name) { teacher_preferred_name || "#{teacher_first_name} #{teacher_last_name}" }
  let(:teacher_email) { "user@example.com" }
  let(:teacher_uid) { SecureRandom.uuid }
  let(:teacher_date_of_birth) { "1980-12-13" }
  let(:teacher_date_of_birth_parsed) { Date.new(1980, 12, 13) }
  let(:teacher_trn) { "1234567" }
  let(:teacher_trn_lookup_status) { "Found" }
  let(:teacher_verified_name) { [teacher_first_name, teacher_last_name] }
  let(:teacher) do
    create(
      :teacher,
      full_name: "#{teacher_first_name} #{teacher_last_name}",
      email: teacher_email,
      trn: teacher_trn,
      date_of_birth: teacher_date_of_birth_parsed,
    )
  end

  let(:provider) { "teacher_auth" }

  let(:stubbed_callback_response) do
    {
      "provider" => "teacher_auth",
      "uid" => teacher_uid,
      "info" => {
        "date_of_birth" => teacher_date_of_birth_parsed,
        "email" => teacher_email,
        "email_verified" => true,
        "trn" => teacher_trn,
        "name" => teacher_full_name,
        "preferred_name" => teacher_preferred_name,
        "trn_lookup_status" => teacher_trn_lookup_status,
      },
      "credentials" => {
        "token" => SecureRandom.uuid,
        "id_token" => SecureRandom.uuid,
        "expires_at" => 24.days.from_now.to_i,
        "expires" => true,
      },
      "extra" => {
        "raw_info" => {
          "sub" => teacher_uid,
          "email" => teacher_email,
          "email_verified" => "True",
          "name" => teacher_full_name,
          "preferred_name" => teacher_preferred_name,
          "birthdate" => teacher_date_of_birth,
          "verified_name" => teacher_verified_name,
          "verified_date_of_birth" => teacher_date_of_birth,
          "trn" => teacher_trn,
          "given_name" => teacher_first_name,
          "family_name" => teacher_last_name,
          "trn_lookup_status" => teacher_trn_lookup_status,
        },
      },
    }
  end

  let(:stubbed_callback_response_as_json) do
    stubbed_callback_response.as_json
  end

  let(:teacher_attributes_from_stubbed_callback_response) do
    {
      "date_of_birth" => teacher_date_of_birth,
      "email" => teacher_email,
      "full_name" => teacher_full_name,
      "preferred_name" => teacher_preferred_name,
      "provider" => "teacher_auth",
      "raw_tra_provider_data" => stubbed_callback_response_as_json,
      "trn" => teacher_trn,
      "trn_lookup_status" => teacher_trn_lookup_status,
      "one_login_id" => teacher_uid,
    }
  end

  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.add_mock(:teacher_auth, stubbed_callback_response)

    teacher_sign_in(teacher:)
  end
end
