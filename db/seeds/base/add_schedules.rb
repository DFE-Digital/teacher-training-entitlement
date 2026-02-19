schedules = %i[tte_reception_autumn tte_send_spring]
# cohorts up to 2025 reflect production
{
  2023 => schedules,
  2024 => schedules,
}.each do |start_year, schedules|
  cohort = Cohort.find_by(start_year:, suffix: "a")
  schedules.each do |schedule_identifier|
    FactoryBot.build(:schedule, schedule_identifier, cohort:, change_applies_dates: false).save(validate: false)
  end
end

Cohort.where(start_year: 2025..).find_each do |cohort|
  {
    tte_reception_autumn: 9,
    tte_reception_spring: 8,
  }.each do |schedule_identifier, policy_descriptor|
    FactoryBot.create(
      :schedule,
      schedule_identifier,
      cohort:,
      change_applies_dates: false,
      policy_descriptor: policy_descriptor + (cohort.start_year - 2025),
      acceptance_window_start: Date.new(cohort.start_year, 1, 1),
      acceptance_window_end: Date.new(cohort.start_year, 12, 1),
    )
  end
end
