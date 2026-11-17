FactoryBot.define do
  factory :trs_webhook_message do
    message_id { SecureRandom.uuid }
    message_type { "ping" }
    message_source { "https://preprod.teacher-qualifications-api.education.gov.uk/" }
    sent_at { Time.current }
    message { { "pingId" => SecureRandom.uuid } }

    trait :trn_request_completed do
      transient do
        one_login_id { SecureRandom.uuid }
        trn { "1234567" }
      end

      message_type { "trn_request.completed" }
      message do
        {
          "trnRequest" => {
            "requestId" => SecureRandom.uuid,
            "oneLoginUserSubject" => one_login_id,
            "trn" => trn,
            "status" => "Completed",
            "potentialDuplicate" => false,
            "accessYourTeachingQualificationsLink" => nil,
          },
        }
      end
    end
  end
end
