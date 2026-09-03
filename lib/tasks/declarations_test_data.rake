# frozen_string_literal: true

namespace :declarations do
  desc "Create declaration test data for reception/SEND courses and Ambition Institute"
  task setup_test_data: :environment do
    raise "This task must not be run in production" if Rails.env.production?

    started_on = 1.month.ago.beginning_of_month.to_date
    ends_on = 2.months.from_now.to_date
    run_id = Time.zone.now.strftime("%Y%m%d%H%M%S")

    cohort = Cohort.find_or_create_by!(registration_starts_at: started_on) do |record|
      record.description = "Declaration test #{started_on.to_fs(:db)}"
      record.registration_ends_at = ends_on
      record.funding_cap = false
      record.ecf_id = SecureRandom.uuid
    end

    lead_provider = LeadProvider.find_or_create_by!(name: "Ambition Institute") do |record|
      record.ecf_id = SecureRandom.uuid
      record.email = "ambition@example.com"
    end

    delivery_partner = DeliveryPartner.find_or_create_by!(name: "Declaration Test Delivery Partner") do |record|
      record.ecf_id = SecureRandom.uuid
    end

    APIToken.create_with_known_token!("ambition-token", lead_provider:)

    courses = [
      Course.find_or_create_by!(identifier: "tte-early-years") do |record|
        record.name = "NPD excellence in reception teaching"
        record.short_code = "NPDEIRT"
        record.course_group = "reception"
        record.ecf_id = SecureRandom.uuid
      end,
      Course.find_or_create_by!(identifier: "npd-send") do |record|
        record.name = "SEND teaching"
        record.short_code = "NPDSEND"
        record.course_group = "send"
        record.ecf_id = SecureRandom.uuid
      end,
    ]

    course_setups = courses.map do |course|
      schedule = Schedule.find_or_create_by!(cohort:, identifier: "declaration-test-#{course.identifier}-#{started_on.to_fs(:number)}") do |record|
        record.name = "Declaration test #{course.short_code} schedule"
        record.course_group = course.course_group
        record.training_starts_at = started_on
        record.training_ends_at = ends_on
        record.acceptance_window_start = started_on
        record.acceptance_window_end = ends_on
        record.policy_descriptor = started_on.year
        record.ecf_id = SecureRandom.uuid
      end

      course_cohort = CourseCohort.find_or_create_by!(course:, cohort:) do |record|
        record.schedule = schedule
        record.academic_year = started_on.year
        record.ecf_id = SecureRandom.uuid
      end

      course_cohort.update!(schedule:) unless course_cohort.schedule == schedule

      started_milestone = Milestone.find_or_create_by!(course_cohort:, declaration_type: Milestone::STARTED) do |record|
        record.acceptance_window_start_date = started_on
        record.acceptance_window_end_date = ends_on
        record.payment_amount = 50
      end

      completed_milestone = Milestone.find_or_create_by!(course_cohort:, declaration_type: Milestone::COMPLETED) do |record|
        record.acceptance_window_start_date = started_on + 1.month
        record.acceptance_window_end_date = ends_on
        record.payment_amount = 50
      end

      CourseCohortProvider.find_or_create_by!(course_cohort:, lead_provider:)
      DeliveryPartnership.find_or_create_by!(course_cohort:, lead_provider:, delivery_partner:)

      applications = 3.times.map do |index|
        unique_id = "#{run_id}-#{course.identifier.parameterize}-#{index + 1}"
        school = School.create!(
          establishment_status_code: "1",
          establishment_status_name: "Open",
          establishment_type_code: "1",
          establishment_type_name: "Community school",
          la_code: "201",
          la_name: "City of London",
          phase_name: School::PRIMARY_PHASE,
          ukprn: unique_id.hash.abs.to_s.first(8),
        )

        institution = Institution.create!(
          institutionable: school,
          institution_reference_number: unique_id.hash.abs.to_s.first(6),
          name: "Declaration Test School #{unique_id}",
          postcode: "SW1A 1AA",
          postcode_without_spaces: "SW1A1AA",
          town: "London",
        )

        user = User.create!(
          full_name: "Declaration Test User #{unique_id}",
          email: "declaration-test-#{unique_id}@example.com",
        )

        application = Application.create!(
          user:,
          course_cohort:,
          institution:,
          status: Application::PENDING,
          teacher_catchment: "england",
          teacher_catchment_country: "United Kingdom of Great Britain and Northern Ireland",
          teacher_catchment_iso_country_code: "GBR",
          works_in_school: true,
          works_in_childcare: false,
          funding_choice: Application.funding_choices.keys.first,
          ukprn: institution.ukprn,
          eligible_for_funding: true,
        )

        ApplicationLeadProvider.create!(
          application:,
          lead_provider:,
          current: true,
          assigned_at: Time.zone.now,
        )

        service = Applications::Accept.new(application:, funded_place: false)
        raise "Could not accept application #{application.id}: #{service.errors.full_messages.to_sentence}" unless service.call

        application.reload
      end

      {
        course:,
        course_cohort:,
        started_milestone:,
        completed_milestone:,
        applications:,
      }
    end

    puts "Created declaration test data"
    puts "Lead provider: #{lead_provider.name} (token: ambition-token)"
    puts "Delivery partner: #{delivery_partner.name} / #{delivery_partner.ecf_id}"
    course_setups.each do |setup|
      puts "Course cohort: #{setup[:course_cohort].id} (#{setup[:course].name}, #{cohort.name})"
      puts "Started milestone: #{setup[:started_milestone].id}"
      puts "Completed milestone: #{setup[:completed_milestone].id}"
      puts "Accepted applications:"
      setup[:applications].each { |application| puts "- #{application.id} / #{application.ecf_id} / #{application.user.email}" }
    end
  end
end
