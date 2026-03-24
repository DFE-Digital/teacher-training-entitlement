current_year = Date.current.year

((current_year - 3)..(current_year + 3)).each do |start_year|
  %w[a b].each do |suffix|
    Cohort.find_by(start_year:, suffix:) || FactoryBot.create(:cohort, :with_funding_cap, start_year:, suffix:)
  end
end
