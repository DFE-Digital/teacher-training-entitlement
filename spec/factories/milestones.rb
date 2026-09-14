FactoryBot.define do
  factory :milestone do
    declaration_type { :started }
    acceptance_window_start_offset { 0 }
    acceptance_window_end_offset { 1 }
    course

    trait :started do
      declaration_type { Milestone::STARTED }
    end

    trait :completed do
      declaration_type { Milestone::COMPLETED }
    end
  end
end
