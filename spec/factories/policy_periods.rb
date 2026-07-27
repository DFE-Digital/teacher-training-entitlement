FactoryBot.define do
  factory :policy_period do
    name { "Academic year #{start_date.year}/#{end_date.year}" }
    start_date { Time.zone.today.next_month.beginning_of_month }
    end_date { Time.zone.today.advance(months: 3).beginning_of_month }
  end
end
