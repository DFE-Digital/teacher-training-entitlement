FactoryBot.define do
  factory :milestone do
    declaration_type { :started }
    acceptance_window_start_date { 1.week.ago.to_date }
    acceptance_window_end_date { 1.month.from_now.to_date }
    course_cohort

    trait :started do
      declaration_type { Milestone::STARTED }
    end

    trait :completed do
      declaration_type { Milestone::COMPLETED }
    end
  end
end
