FactoryBot.define do
  factory :contract do
    association :statement
    lead_provider { statement.lead_provider }
    association :course
    association :contract_template
  end
end
