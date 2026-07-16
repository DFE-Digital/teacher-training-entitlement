FactoryBot.define do
  factory :milestone do
    declaration_type { :started }
    acceptance_window_start_date { Time.zone.today }
    acceptance_window_end_date { 1.month.from_now.to_date }
    course_cohort
  end
end
