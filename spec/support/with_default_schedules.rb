# frozen_string_literal: true

RSpec.shared_context "with default schedules", shared_context: :metadata do
  before do
    # create cohorts since 2021 with default schedule
    end_year = Date.current.month < 9 ? Date.current.year : Date.current.year.succ
    (2021..end_year).each do |start_year|
      cohort = FactoryBot.create(:cohort, start_year:)
      Schedule::IDENTIFIERS.each do |schedule_identifier|
        FactoryBot.create(:schedule, schedule_identifier.tr("-", "_"), cohort:, change_training_dates: false)
      end
    end
  end
end

RSpec.configure do |config|
  config.include_context "with default schedules", :with_default_schedules
end
