require_relative "constants"

LEAD_PROVIDERS.each do |name|
  LeadProvider.find_by(name:) || FactoryBot.create(:lead_provider, name:)
end

Course.find_each do |course|
  Cohort.find_each do |cohort|
    schedule = Schedule.find_by(cohort:, course_group: course.course_group)
    if schedule.nil?
      schedule = Schedule.create!(
        course_group: course.course_group,
        cohort:,
        name: "#{cohort.id} Schedule",
        identifier: "#{cohort.id} Identifier",
        training_starts_at: Date.new(cohort.start_year, 10, 1),
        training_ends_at: Date.new(cohort.start_year, 11, 1),
        allowed_declaration_types: %w[started retained-1 retained-2 completed],
        policy_descriptor: 1,
        acceptance_window_start: Date.new(cohort.start_year, 1, 1),
        acceptance_window_end: Date.new(cohort.start_year, 12, 31),
      )
    end
    course_cohort = CourseCohort.find_or_create_by!(course:, cohort:) do |cc|
      cc.schedule = schedule
    end

    LeadProvider.find_each do |lead_provider|
      CourseCohortProvider.find_or_create_by!(
        lead_provider:,
        course_cohort:,
      )
    end
  end
end
