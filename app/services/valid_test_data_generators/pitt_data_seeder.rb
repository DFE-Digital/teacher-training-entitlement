module ValidTestDataGenerators
  class PittDataSeeder
    def run
      StatementItem.delete_all
      ParticipantOutcome.delete_all
      Declaration.delete_all
      ApplicationLeadProvider.delete_all
      ApplicationEvent.delete_all
      StateChange.delete_all
      Application.delete_all
      DeliveryPartnership.delete_all
      CourseCohortProvider.delete_all
      Milestone.delete_all
      CourseCohort.delete_all
      Contract.delete_all
      Statement.delete_all
      Schedule.delete_all
      Cohort.delete_all
      # PolicyPeriod.delete_all
      #

      lead_providers = LeadProvider.take(2)

      policy_period = PolicyPeriod.find_by_name("AY 2026/2027") || PolicyPeriod.create!(name: "AY 2026/2027", start_date: Date.new(2026, 9, 1), end_date: Date.new(2027, 7, 27))

      cohort = Cohort.create!(
        description: "Autumn 2026 Cohort",
        registration_starts_at: Date.new(2026, 7, 1),
        registration_ends_at: Date.new(2026, 8, 31),
        funding_cap: true,
      )

      course = Course.find_by(identifier: "npd-excellence-in-reception-teaching") || Course.reception || Course.new
      course.update!(
        name: "Excellence in Reception Teaching",
        ecf_id: "7fbefdd4-dd2d-4a4f-8995-d59e525124b7",
        identifier: "npd-excellence-in-reception-teaching",
        short_code: "NPD-EIRT",
        description: "The course is aimed at teachers who have completed their induction and are currently teaching reception age children, or plan to in the future.",
      )

      course_cohorts = [CourseCohort.create!(course:, cohort:, policy_period:,
                                             registration_starts_at: cohort.registration_starts_at,
                                             registration_ends_at: cohort.registration_ends_at,
                                             training_starts_at: cohort.registration_ends_at + 1.day,
                                             training_ends_at: cohort.registration_ends_at + 1.day + 3.months),
                        CourseCohort.create!(course:, cohort:, policy_period:,
                                             registration_starts_at: cohort.registration_starts_at,
                                             registration_ends_at: cohort.registration_ends_at,
                                             training_starts_at: cohort.registration_ends_at + 1.day + 3.months,
                                             training_ends_at: cohort.registration_ends_at + 1.day + 6.months),

                        CourseCohort.create!(course:, cohort:, policy_period:,
                                             registration_starts_at: cohort.registration_starts_at,
                                             registration_ends_at: cohort.registration_ends_at,
                                             training_starts_at: cohort.registration_ends_at + 1.day + 6.months,
                                             training_ends_at: cohort.registration_ends_at + 1.day + 9.months)]

      course_cohorts.each do |cc|
        Milestone.create!(declaration_type: Milestone::STARTED,
                          acceptance_window_start_date: cc.training_starts_at,
                          acceptance_window_end_date: cc.training_ends_at,
                          course_cohort: cc)

        Milestone.create!(declaration_type: Milestone::COMPLETED,
                          acceptance_window_start_date: cc.training_ends_at,
                          acceptance_window_end_date: cc.training_ends_at + 1.month,
                          course_cohort: cc)

        lead_providers.each do |lead_provider|
          contract = Contract.where(lead_provider:, course:).last || Contract.create!(lead_provider:, course:)

          CourseCohortProvider.create!(course_cohort: cc, lead_provider:, contract:)
        end

        create_applications_on(course_cohort: cc)
      end
    end

    def create_applications_on(course_cohort:)
      lead_provider = course_cohort.lead_providers.first
      delivery_partner = delivery_partner_for(course_cohort:, lead_provider:)
      started_milestone = course_cohort.milestones.find_by!(declaration_type: Milestone::STARTED)
      completed_milestone = course_cohort.milestones.find_by!(declaration_type: Milestone::COMPLETED)

      3.times do
        FactoryBot.create(:application, course_cohort:, lead_provider:, status: Application::PENDING)
      end

      3.times do
        application = FactoryBot.create(:application, course_cohort:, lead_provider:, status: Application::STARTED)

        create_declaration(application:, milestone: started_milestone, delivery_partner:)
      end

      3.times do
        application = FactoryBot.create(:application, course_cohort:, lead_provider:, status: Application::COMPLETED)

        create_declaration(application:, milestone: started_milestone, delivery_partner:)
        create_declaration(application:, milestone: completed_milestone, delivery_partner:)
      end
    end

  private

    def delivery_partner_for(course_cohort:, lead_provider:)
      delivery_partner = DeliveryPartner.find_or_create_by!(
        name: "Pitt Delivery Partner #{course_cohort.course.short_code} #{course_cohort.training_starts_at.to_fs(:db)}",
      ) do |partner|
        partner.ecf_id = SecureRandom.uuid
      end

      DeliveryPartnership.find_or_create_by!(
        delivery_partner:,
        lead_provider:,
        cohort: course_cohort.cohort,
      )

      delivery_partner
    end

    def create_declaration(application:, milestone:, delivery_partner:)
      FactoryBot.create(
        :declaration,
        application:,
        course_cohort: application.course_cohort,
        lead_provider: application.lead_provider,
        milestone:,
        delivery_partner:,
        declaration_type: milestone.declaration_type,
        declaration_date: [milestone.acceptance_window_start_date, Time.zone.today - 1.day].min,
      )
    end
  end
end
