module ValidTestDataGenerators
  class CleanReceptionLaunchSeeder
    def run
      DeliveryPartnership.delete_all
      CourseCohortProvider.delete_all
      CourseCohort.delete_all
      StatementItem.delete_all
      Statement.delete_all
      ParticipantOutcome.delete_all
      Declaration.delete_all
      Schedule.delete_all
      Cohort.delete_all

      cohort = Cohort.create!(
        start_year: 2026,
        description: "2026a",
        registration_starts_at: Date.new(2026, 7, 1),
        registration_ends_at: Date.new(2026, 8, 31),
        funding_cap: true,
      )

      schedule = Schedule.create!(
        cohort:,
        name: "NPD Reception October 2026",
        identifier: "npd-reception-october-2026",
        course_group: "reception",
        training_starts_at: Date.new(2026, 10, 1),
        training_ends_at: Date.new(2026, 3, 31),
        allowed_declaration_types: %w[started completed],
        policy_descriptor: 1,
        acceptance_window_start: Date.new(2026, 7, 1),
        acceptance_window_end: Date.new(2026, 8, 31),
      )

      course = Course.find_by(identifier: "npd-excellence-in-reception-teaching") || Course.reception || Course.new
      course.update!(
        name: "Excellence in Reception Teaching",
        ecf_id: "7fbefdd4-dd2d-4a4f-8995-d59e525124b7",
        identifier: "npd-excellence-in-reception-teaching",
        short_code: "NPD-EIRT",
        description: "The course is aimed at teachers who have completed their induction and are currently teaching reception age children, or plan to in the future.",
      )

      course_cohort = CourseCohort.create!(course:, cohort:, schedule:)
      LeadProvider.find_each do |lead_provider|
        CourseCohortProvider.create(course_cohort:, lead_provider:)
      end
    end
  end
end
