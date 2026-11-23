# frozen_string_literal: true

FactoryBot.define do
  factory :participant_id_change do
    teacher
    from_participant_id { SecureRandom.uuid }
    to_participant_id { teacher.ecf_id }
  end
end
