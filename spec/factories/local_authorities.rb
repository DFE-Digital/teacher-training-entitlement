FactoryBot.define do
  factory :local_authority do
    transient do
      institution_name { "local authority" }
    end

    sequence(:ukprn) { |n| (10_000_000 + n).to_s }

    after(:build) do |la, evaluator|
      la.institution ||= build(:institution, :for_local_authority, institutionable: la, name: evaluator.institution_name)
    end

    after(:create) do |la, evaluator|
      la.institution ||= create(:institution, :for_local_authority, institutionable: la, name: evaluator.institution_name)
    end
  end
end
