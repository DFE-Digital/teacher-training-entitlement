FactoryBot.define do
  factory :delivery_partnership do
    association(:delivery_partner)
    association(:lead_provider)
    course_cohort
  end
end
