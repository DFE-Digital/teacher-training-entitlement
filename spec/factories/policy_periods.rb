FactoryBot.define do
  factory :policy_period do
    start_date { Time.zone.today.next_month.beginning_of_month }
    end_date { Time.zone.today.advance(months: 3).beginning_of_month }
  end
end
