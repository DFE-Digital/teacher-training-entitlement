FactoryBot.define do
  factory :milestone do
    declaration_type { :started }
    course_cohort
  end
end
