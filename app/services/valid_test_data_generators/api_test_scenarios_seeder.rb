# frozen_string_literal: true

module ValidTestDataGenerators
  # Service to seed test data for Lead Provider API Test Scenarios
  # Based on: @tte-board/documentation/lead_provider_api_test_scenarios.md
  #
  # NOTE: for change provider feature, the application label APP-006 should
  # marked as unassigned and be read-only
  class APITestScenariosSeeder
    attr_reader :lead_provider, :cohort_year, :logger

    Outcome = Data.define(:success, :error, :applications_count, :cohort_year) do
      def initialize(success:, error: nil, applications_count: nil, cohort_year: nil)
        super(success:, error:, applications_count:, cohort_year:)
      end
    end

    class << self
      def applications_data
        @applications_data ||= load_applications_data
      end

      def custom_email_templates
        @custom_email_templates ||= load_custom_email_templates
      end

    private

      def load_applications_data
        config_path = Rails.root.join("config/api_test_scenarios.yml")
        config = YAML.load_file(config_path)
        config["applications"].map(&:deep_symbolize_keys)
      end

      def load_custom_email_templates
        config_path = Rails.root.join("config/api_test_scenarios.yml")
        config = YAML.load_file(config_path)
        config["custom_email_templates"] || {}
      end
    end

    def initialize(lead_provider:,
                   course_identifier: "tte-early-years",
                   schedule_identifier: "tte-reception-autumn",
                   cohort_year: Date.current.year,
                   logger: Rails.logger)
      @lead_provider = lead_provider
      @course_identifier = course_identifier
      @schedule_identifier = schedule_identifier
      @cohort_year = cohort_year.to_i
      @logger = logger
    end

    def user_email(email, user_id = nil)
      # Check if custom email template exists for this lead provider
      custom_template = self.class.custom_email_templates[@lead_provider.name]

      if custom_template.present? && user_id.present?
        # Generate email in format: prefix+<user.id>@domain
        prefix, domain = custom_template.split("@")
        "#{prefix}+#{user_id}@#{domain}"
      else
        # Fall back to original logic
        email.gsub("example", to_dns_name(@lead_provider.name))
      end
    end

    def call
      unless Rails.env.in?(%w[development review sandbox])
        return Outcome[success: false, error: "Only available in development, review, and sandbox environments"]
      end

      ActiveRecord::Base.transaction do
        test_scenarios_drop_data!
        test_scenarios_create_data!
      end

      Outcome[
        success: true,
        applications_count: applications_data.size,
        cohort_year: cohort_year,
        ]
    rescue StandardError => e
      logger.error "APITestScenariosSeeder failed: #{e.message}"
      logger.error e.backtrace.join("\n")

      Sentry.capture_exception(e)
      Outcome[success: false, error: e.message]
    end

    def custom_data(nb_cohort:, nb_app_per_state:)
      cohort_start_dates
        .take(nb_cohort)
        .each do |registration_starts_at|
        create_data!(registration_starts_at:, number: nb_app_per_state)
      end
    end

    def cohort_start_dates
      Enumerator.new do |yielder|
        year = cohort_year
        loop do
          yielder << Date.new(year, 7, 1) # autumn schedule
          yielder << Date.new(year, 9, 1) # spring schedule
          year += 1
        end
      end
    end

    def test_emails
      applications_data.map { |app| user_email(app[:email]) }
    end

    def test_user_ecf_ids
      applications_data.map { |app| user_ecf_id(app[:participant_id]) }
    end

    def test_scenarios_drop_data!
      # Find test users by ecf_id for reliable identification
      test_users = User.includes(:applications).where(ecf_id: test_user_ecf_ids)

      # Delete applications for these test users with this lead provider
      applications_to_delete = lead_provider.applications.where(user: test_users)

      if applications_to_delete.any?
        declaration_ids = Declaration.where(application: applications_to_delete).pluck(:id)

        if declaration_ids.any?
          # Find statements through statement_items
          statement_ids = StatementItem.where(declaration_id: declaration_ids).pluck(:statement_id).uniq

          # Delete statements and their associated records
          if statement_ids.any?
            # Delete statement items
            StatementItem.where(declaration_id: declaration_ids).delete_all
            Adjustment.where(statement_id: statement_ids).delete_all
            MilestoneStatement.where(statement_id: statement_ids).delete_all
            Contract.where(statement_id: statement_ids).delete_all
            Statement.where(id: statement_ids).delete_all
          end

          statement_ids = Declaration.where(application: applications_to_delete).pluck(:statement_id)
          if statement_ids.any?
            # case when declaration are attach directly to statement
            Adjustment.where(statement_id: statement_ids).delete_all
            Statement.where(id: statement_ids).delete_all
          end

          # Delete participant outcomes associated with declarations
          ParticipantOutcome.where(declaration_id: declaration_ids).delete_all
        end

        # Delete declarations and application events
        Declaration.where(application: applications_to_delete).delete_all
        ApplicationEvent.where(application: applications_to_delete).delete_all

        Application.where(id: applications_to_delete.pluck(:id)).delete_all
      end

      # Delete test users if they have no other applications
      test_users.each do |user|
        if user.applications.reload.empty?
          user.delete
        end
      end
    end

    def test_scenarios_create_data!
      course_cohorts = cohort_start_dates
                         .take(4)
                         .map do |registration_starts_at|
        course_cohort_setup(
          registration_starts_at:,
          training_starts_now: registration_starts_at.year == cohort_year, # for the cohort_year make training start now to simplify testing
        )
      end

      applications_data.each do |app_data|
        create_app(
          course_cohort: course_cohorts[app_data[:cohort_offset]],
          status: Application::PENDING,
          eligible_for_funding: app_data[:funding_eligible],
          user: create_user(app_data),
        ).tap do |application|
          if app_data[:label] == "APP-013"
            change_provider(application:)
            create_app_event(application:, event: :changed_provider)
          end
        end
      end
    end

    def create_data!(registration_starts_at:, number:)
      course_cohort = course_cohort_setup(registration_starts_at:)
      applications_setup(course_cohort:, number:)
    end

  private

    def to_dns_name(name, max_length: 63)
      name.to_s
        .parameterize # Convert to lowercase, replace spaces/special chars with hyphens
        .gsub(/[^a-z0-9-]/, "")         # Remove any remaining invalid characters
        .gsub(/-+/, "-")                # Collapse multiple hyphens
        .sub(/^-/, "")                  # Remove leading hyphen
        .sub(/-$/, "")                  # Remove trailing hyphen
        .slice(0, max_length)           # Truncate to max length
        .sub(/-$/, "")                  # Remove trailing hyphen again if truncation created one
    end

    def applications_data
      self.class.applications_data
    end

    def course
      @course ||= Course.find_by!(identifier: @course_identifier)
    end

    def create_random_user(with_trn: true)
      name = Faker::Name.unique.name
      email_part = name.tr(" '.", "").downcase

      email = "#{email_part}@#{to_dns_name(@lead_provider.name)}.com"

      user = User.find_or_create_by!(email:) do |u|
        u.ecf_id = SecureRandom.uuid
        u.full_name = name
        u.trn = generate_trn if with_trn
        u.date_of_birth = Faker::Date.birthday(min_age: 20)
        u.trn_lookup_status = "Found" if with_trn
      end

      # Update email if custom template exists for this lead provider
      custom_template = self.class.custom_email_templates[@lead_provider.name]
      if custom_template.present?
        custom_email = "#{custom_template.split('@')[0]}+#{user.id}@#{custom_template.split('@')[1]}"
        user.update!(email: custom_email)
      end

      user
    end

    def create_user(app_data)
      ecf_id = user_ecf_id(app_data[:participant_id])

      attrs = {
        full_name: app_data[:full_name],
        trn: generate_trn,
        date_of_birth: Faker::Date.birthday(min_age: 20),
        trn_lookup_status: "Found",
        ecf_id:,
      }

      temp_email = user_email(app_data[:email])
      user = User.find_by(ecf_id: ecf_id) || User.find_by(email: temp_email)

      if user
        # Update existing user
        user.update!(attrs)
      else
        # Create new user with temporary email
        user = User.create!(attrs.merge(email: temp_email))
      end

      # Update email if custom template exists for this lead provider
      custom_template = self.class.custom_email_templates[@lead_provider.name]
      if custom_template.present?
        custom_email = user_email(app_data[:email], user.id)
        user.update!(email: custom_email)
      end

      user
    end

    def user_ecf_id(index)
      [
        "4e87fadb",
        "f678",
        "4934",
        sprintf("%04x", @lead_provider.id % 0x10000),
        sprintf("%012d", index),
      ].join("-")
    end

    def generate_trn
      sprintf("%07d", SecureRandom.random_number(10_000_000))
    end

    def delivery_partners(number: 5)
      @delivery_partners ||= (1..number).map do |i|
        DeliveryPartner.find_by(name: "Delivery partner #{i}") || DeliveryPartner.create!(name: "Delivery partner #{i}", ecf_id: SecureRandom.uuid)
      end
    end

    def course_cohort_setup(registration_starts_at:, training_starts_now: false)
      cohort_year = registration_starts_at.year
      term = registration_starts_at.month < 8 ? "autumn" : "spring"
      current_cohort = Cohort.find_by(registration_starts_at:)

      attrs = {
        description: "#{registration_starts_at.strftime('%B')} #{cohort_year}",
        registration_starts_at:,
        funding_cap: true,
      }
      if current_cohort
        current_cohort.update!(attrs)
      else
        current_cohort = Cohort.create!(**attrs)
      end

      training_starts_at = training_starts_now ? 1.day.ago : registration_starts_at + 2.months
      training_ends_at = training_starts_at + 6.months
      schedule = create_or_update_schedule!(
        cohort: current_cohort,
        term:,
        training_starts_at:,
        training_ends_at:,
      )

      cc = CourseCohort.find_by(course:, cohort: current_cohort)
      if cc
        cc.update!(schedule:)
      else
        cc = CourseCohort.create!(
          course:,
          cohort: current_cohort,
          schedule:,
        )
      end

      create_or_update_milestone!(
        course_cohort: cc,
        declaration_type: Milestone::STARTED,
        acceptance_window_start_date: training_starts_at,
        acceptance_window_end_date: training_starts_at + 2.months,
      )

      create_or_update_milestone!(
        course_cohort: cc,
        declaration_type: Milestone::COMPLETED,
        acceptance_window_start_date: training_ends_at,
        acceptance_window_end_date: training_ends_at + 2.months,
      )

      cc.course_cohort_providers.find_or_create_by!(lead_provider:)

      delivery_partners.each do |dp|
        dp.delivery_partnerships.find_or_create_by!(lead_provider:, cohort: current_cohort)
      end

      cc
    end

    def create_or_update_schedule!(cohort:, term:, training_starts_at:, training_ends_at:)
      identifier = "tte-reception-#{term}"
      attrs = {
        cohort:,
        name: "TTE Reception #{term}",
        course_group: course.course_group,
        training_starts_at:,
        training_ends_at:,
        allowed_declaration_types: %w[started completed],
        policy_descriptor: 1,
        acceptance_window_start: training_starts_at,
        acceptance_window_end: training_starts_at + 2.months,
      }

      schedule = Schedule.find_or_initialize_by(identifier:, cohort:)
      schedule.update!(attrs)
      schedule
    end

    def institutions_eligible
      Institution
        .open_school_or_non_school
        .order("RANDOM()")
        .first
    end

    def institutions_ineligible
      Institution
        .schools
        .where(institutionable_id: School.not_in_england)
        .order("RANDOM()")
        .first
    end

    def create_app(course_cohort:, status:, eligible_for_funding:, user:)
      funded_place = status == Application::PENDING ? nil : eligible_for_funding
      institution = eligible_for_funding ? institutions_eligible : institutions_ineligible
      funding_eligiblity_status_code = eligible_for_funding ? nil : :ineligible_setting
      funding_choice = (eligible_for_funding ? %w[school] : Application.funding_choices.values - %w[school]).sample

      application = lead_provider.updateable_applications.find_or_create_by!(user:, course_cohort:)
      application.update!(
        user:,
        lead_provider:,
        institution:,
        course_cohort:,
        status:,
        funded_place:,
        eligible_for_funding:,
        funding_eligiblity_status_code:,
        ecf_id: SecureRandom.uuid,
        teacher_catchment: "england",
        teacher_catchment_country: "United Kingdom of Great Britain and Northern Ireland",
        teacher_catchment_iso_country_code: "GBR",
        funding_choice:,
        works_in_school: institution.school?,
        works_in_childcare: institution.private_childcare_provider?,
      )
      application
    end

    def create_state_change(application:, event:)
      application.state_changes.create!(event:, lead_provider: application.lead_provider)
    end

    def create_app_event(application:, event:)
      application.application_events.create!(event:, lead_provider: application.lead_provider)
    end

    def create_started_declaration(application:, statement:, declaration_date: nil)
      milestone = milestone_for(application:, declaration_type: :started)
      date = declaration_date || milestone.acceptance_window_start_date + 1.day
      application.declarations.create!(
        declaration_type: :started,
        declaration_date: date,
        state: :eligible,
        delivery_partner: application.lead_provider.delivery_partners.sample,
        milestone:,
        lead_provider: application.lead_provider,
        statement:,
      )
    end

    def create_completed_declaration(application:, statement:, declaration_date: nil, has_passed: true)
      milestone = milestone_for(application:, declaration_type: :completed)
      date = declaration_date || milestone.acceptance_window_start_date + 1.day
      declaration = application.declarations.create!(
        declaration_type: :completed,
        declaration_date: date,
        state: :eligible,
        delivery_partner: application.lead_provider.delivery_partners.sample,
        milestone:,
        lead_provider: application.lead_provider,
        statement:,
      )

      if has_passed
        state = has_passed ? "passed" : "failed"
        ParticipantOutcome.create!(declaration:, state:, completion_date: date)
      end
      declaration
    end

    def applications_setup(course_cohort:, number: 5)
      # pending
      (number * 3).times do |index|
        create_app(
          course_cohort:,
          status: Application::PENDING,
          eligible_for_funding: index.even?,
          user: create_random_user(with_trn: [true, false].sample),
        )
      end

      # accepted
      number.times do |index|
        create_app(
          course_cohort:,
          status: Application::ACCEPTED,
          eligible_for_funding: index.even?,
          user: create_random_user(with_trn: [true, false].sample),
        ).tap do |application|
          create_state_change(application:, event: Application::ACCEPTED)
        end
      end

      # rejected
      number.times do |index|
        create_app(
          course_cohort:,
          status: Application::REJECTED,
          eligible_for_funding: index.even?,
          user: create_random_user(with_trn: [true, false].sample),
        ).tap do |application|
          create_state_change(application:, event: Application::REJECTED)
        end
      end

      # we cannot create declaration in the future
      # so only creates these applications for past cohorts
      if course_cohort.cohort.start_year < Time.zone.now.year
        # create the open statement for started applicatons
        paid_statement = create_open_statement(
          start_date: course_cohort
                        .milestones
                        .find_by!(declaration_type: Milestone::STARTED)
                        .acceptance_window_start_date,
        )
        open_statement = create_open_statement(
          start_date: course_cohort
                        .milestones
                        .find_by!(declaration_type: Milestone::COMPLETED)
                        .acceptance_window_start_date,
        )

        # started
        number.times do |index|
          create_app(
            course_cohort:,
            status: Application::STARTED,
            eligible_for_funding: index.even?,
            user: create_random_user,
          ).tap do |application|
            create_state_change(application:, event: Application::ACCEPTED)
            create_started_declaration(application:, statement: paid_statement)
            create_state_change(application:, event: Application::STARTED)
          end
        end

        # completed
        number.times do |index|
          create_app(
            course_cohort:,
            status: Application::COMPLETED,
            eligible_for_funding: index.even?,
            user: create_random_user,
          ).tap do |application|
            create_state_change(application:, event: Application::ACCEPTED)
            create_started_declaration(application:, statement: paid_statement)
            create_state_change(application:, event: Application::STARTED)
            # TODO: add voided and clawback declarations
            create_completed_declaration(application:, statement: open_statement, has_passed: index.even?)
            create_state_change(application:, event: Application::COMPLETED)
          end
        end

        # deferred
        number.times do |index|
          create_app(
            course_cohort:,
            status: Application::DEFERRED,
            eligible_for_funding: index.even?,
            user: create_random_user(with_trn: [true, false].sample),
          ).tap do |application|
            create_state_change(application:, event: Application::ACCEPTED)
            create_started_declaration(application:, statement: paid_statement)
            create_state_change(application:, event: Application::STARTED)

            create_state_change(application:, event: Application::DEFERRED)
          end
        end

        # withdrawn
        number.times do |index|
          create_app(
            course_cohort:,
            status: Application::WITHDRAWN,
            eligible_for_funding: index.even?,
            user: create_random_user(with_trn: [true, false].sample),
          ).tap do |application|
            case index
            when index % 5
              # auto withdrawn
              create_state_change(application:, event: Application::ACCEPTED)
              create_started_declaration(application:, statement: paid_statement)
              create_state_change(application:, event: Application::STARTED)
              create_state_change(application:, event: Application::DEFERRED)

            when index % 3
              # withdraw after started acceptance
              create_state_change(application:, event: Application::ACCEPTED)
              create_started_declaration(application:, statement: paid_statement)
              create_state_change(application:, event: Application::STARTED)

            when index % 2
              # withdraw after acceptance
              create_state_change(application:, event: Application::ACCEPTED)
            end

            create_state_change(application:, event: Application::WITHDRAWN)
          end
        end

        # finalize paid statement
        paid_statement.prepare_to_freeze!
        paid_statement.mark_as_frozen!
      end

      # reassigned
      number.times do |index|
        create_app(
          course_cohort:,
          status: Application::PENDING,
          eligible_for_funding: index.even?,
          user: create_random_user(with_trn: [true, false].sample),
        ).tap do |application|
          change_provider(application:)
          create_app_event(application:, event: :changed_provider)
        end
      end
    end

    def milestone_for(application:, declaration_type:)
      application.course_cohort.milestones.find_or_create_by!(declaration_type:) do |milestone|
        milestone.assign_attributes(acceptance_window_start_date: application.cohort.registration_starts_at,
                                    acceptance_window_end_date: application.cohort.registration_ends_at)
      end
    end

    def create_or_update_milestone!(course_cohort:, declaration_type:, acceptance_window_start_date:, acceptance_window_end_date:)
      milestone = course_cohort.milestones.find_or_initialize_by(declaration_type:)
      milestone.update!(
        acceptance_window_start_date:,
        acceptance_window_end_date:,
      )
      milestone
    end

    def change_provider(application:)
      new_provider = LeadProvider.where.not(id: @lead_provider.id).order("RANDOM()").first
      application.change_provider!(to: new_provider)
    end

    def create_open_statement(start_date:)
      Statement.find_or_create_by!(
        lead_provider: lead_provider,
        start_date:,
        frequency: :monthly,
      ) do |statement|
        statement.state = "open"
        statement.ecf_id = SecureRandom.uuid
      end
    end
  end
end
