FactoryBot.define do
  factory :milestone do
    declaration_type { :started }
    acceptance_window_start_date { Time.zone.today }
    acceptance_window_end_date { 1.month.from_now.to_date }
    statement_date { Time.zone.today.beginning_of_month }
    course_cohort

    trait :started do
      declaration_type { Milestone::STARTED }
    end

    trait :completed do
      declaration_type { Milestone::COMPLETED }
    end
  end
end
