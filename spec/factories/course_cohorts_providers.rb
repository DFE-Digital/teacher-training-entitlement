FactoryBot.define do
  factory :course_cohort_provider do
    course_cohort
    lead_provider
    teacher_funding { 100 }
    recruitment_target { 20 }
  end
end
