current_year = Date.current.year

Cohort.where(start_year: ..(current_year - 1)).find_each do |cohort|
  %i[tte_reception_autumn tte_reception_spring].each do |schedule_identifier|
    FactoryBot.build(:schedule, schedule_identifier, cohort:).save(validate: false)
  end
end

Cohort.where(start_year: current_year..).find_each do |cohort|
  {
    tte_reception_autumn: 9,
    tte_reception_spring: 8,
  }.each do |schedule_identifier, policy_descriptor|
    FactoryBot.create(
      :schedule,
      schedule_identifier,
      cohort:,
      change_training_dates: false,
      policy_descriptor: policy_descriptor + (cohort.start_year - current_year),
      acceptance_window_start: Date.new(cohort.start_year, 1, 1),
      acceptance_window_end: Date.new(cohort.start_year, 12, 1),
    )
  end
end
