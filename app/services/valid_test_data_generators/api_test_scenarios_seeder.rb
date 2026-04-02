# frozen_string_literal: true

module ValidTestDataGenerators
  # Service to seed test data for Lead Provider API Test Scenarios
  # Based on: @tte-board/documentation/lead_provider_api_test_scenarios.md
  #
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

    private

      def load_applications_data
        config_path = Rails.root.join("config/api_test_scenarios.yml")
        config = YAML.load_file(config_path)
        config["applications"].map(&:deep_symbolize_keys)
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
      @cohort_year = cohort_year
      @logger = logger
    end

    def user_email(email)
      email.gsub("example", to_dns_name(@lead_provider.name))
    end

    def call
      unless Rails.env.in?(%w[development review sandbox])
        return Outcome[success: false, error: "Only available in development, review, and sandbox environments"]
      end

      logger.info "APITestScenariosSeeder: Started for #{lead_provider.name} (cohort #{cohort_year})"

      ActiveRecord::Base.transaction do
        cleanup_existing_data!
        setup_course_cohorts!
        create_applications!
        create_statements!
      end

      logger.info "APITestScenariosSeeder: Finished for #{lead_provider.name}"
      logger.info "Created #{applications_data.size} applications"

      Outcome[
        success: true,
        applications_count: applications_data.size,
        cohort_year: cohort_year,
        ]
    rescue StandardError => e
      logger.error "APITestScenariosSeeder failed: #{e.message}"
      logger.error e.backtrace.join("\n")

      Outcome[success: false, error: e.message]
    end

    def test_emails
      applications_data.map { |app| user_email(app[:email]) }
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

    def cleanup_existing_data!
      logger.info "Cleaning up existing test data..."

      test_users = User.where(email: test_emails)

      # Delete applications for these test users with this lead provider
      applications_to_delete = Application.where(user: test_users, lead_provider: lead_provider)

      if applications_to_delete.any?
        app_count = applications_to_delete.count
        declaration_ids = Declaration.where(application: applications_to_delete).pluck(:id)

        if declaration_ids.any?
          # Find statements through statement_items
          statement_ids = StatementItem.where(declaration_id: declaration_ids).pluck(:statement_id).uniq

          # Delete participant outcomes associated with declarations
          ParticipantOutcome.where(declaration_id: declaration_ids).delete_all

          # Delete statement items
          StatementItem.where(declaration_id: declaration_ids).delete_all

          # Delete statements and their associated records
          if statement_ids.any?
            Adjustment.where(statement_id: statement_ids).delete_all
            MilestoneStatement.where(statement_id: statement_ids).delete_all
            Contract.where(statement_id: statement_ids).delete_all
            Statement.where(id: statement_ids).delete_all
            logger.info "✓ Deleted #{statement_ids.count} statements connected to test declarations"
          end
        end

        # Delete declarations and application states
        Declaration.where(application: applications_to_delete).delete_all
        ApplicationState.where(application: applications_to_delete).delete_all

        applications_to_delete.delete_all
        logger.info "✓ Deleted #{app_count} existing test applications"
      end

      # Delete test users if they have no other applications
      test_users.each do |user|
        if user.applications.reload.empty?
          user.delete
          logger.info "✓ Deleted test user: #{user.email}"
        end
      end

      logger.info "Cleanup complete"
    end

    def setup_course_cohorts!
      setup_cohorts!
      setup_course_and_schedules!
      @course_cohort_primary = CourseCohort.find_or_create_by!(
        course: @course,
        cohort: @cohort_primary,
        schedule: @schedule_primary,
      )
      @course_cohort_primary.course_cohort_providers.find_or_create_by!(lead_provider:)

      @course_cohort_secondary = CourseCohort.find_or_create_by!(
        course: @course,
        cohort: @cohort_secondary,
        schedule: @schedule_secondary,
      )
      @course_cohort_secondary.course_cohort_providers.find_or_create_by!(lead_provider:)
    end

    def setup_cohorts!
      @cohort_primary = Cohort.find_or_create_by!(start_year: cohort_year, suffix: "a") do |cohort|
        cohort.description = "#{cohort_year} to #{cohort_year + 1}"
        cohort.registration_starts_at = Date.new(cohort_year, 4, 3)
        cohort.funding_cap = true
      end

      @cohort_secondary = Cohort.find_or_create_by!(start_year: cohort_year + 1, suffix: "a") do |cohort|
        cohort.description = "#{cohort_year + 1} to #{cohort_year + 2}"
        cohort.registration_starts_at = Date.new(cohort_year + 1, 4, 3)
        cohort.funding_cap = true
      end

      logger.info "✓ Cohorts setup: #{cohort_year}, #{cohort_year + 1}"
    end

    def setup_course_and_schedules!
      @course = Course.find_by!(identifier: @course_identifier)

      # Create schedule for primary cohort
      @schedule_primary = Schedule.find_or_create_by!(
        identifier: @schedule_identifier,
      ) do |schedule|
        schedule.name = "TTE Reception autumn"
        schedule.course_group = @course.course_group
        schedule.training_starts_at = Date.new(cohort_year, 9, 1)
        schedule.training_ends_at = Date.new(cohort_year + 1, 8, 31)
        schedule.allowed_declaration_types = %w[started completed]
        schedule.policy_descriptor = 1
        schedule.acceptance_window_start = Date.new(cohort_year, 1, 1)
        schedule.acceptance_window_end = Date.new(cohort_year, 12, 31)
      end

      # Create schedule for secondary cohort
      @schedule_secondary = Schedule.find_or_create_by!(
        identifier: @schedule_identifier,
      ) do |schedule|
        schedule.name = "TTE Reception autumn"
        schedule.course_group = @course.course_group
        schedule.training_starts_at = Date.new(cohort_year + 1, 9, 1)
        schedule.training_ends_at = Date.new(cohort_year + 2, 8, 31)
        schedule.allowed_declaration_types = %w[started completed]
        schedule.policy_descriptor = 1
        schedule.acceptance_window_start = Date.new(cohort_year + 1, 1, 1)
        schedule.acceptance_window_end = Date.new(cohort_year + 1, 12, 31)
      end

      logger.info "✓ Course and schedules setup"
    end

    def create_applications!
      @applications = {}

      applications_data.each do |app_data|
        course_cohort = app_data[:cohort_offset].zero? ? @course_cohort_primary : @course_cohort_secondary
        school = School.open.order("RANDOM()").first || School.open.first

        user = create_user(app_data)

        application = Application.create!(
          user: user,
          lead_provider: lead_provider,
          course_cohort: course_cohort,
          institution: school.institution,
          status: Application::PENDING,
          ecf_id: SecureRandom.uuid,
          eligible_for_funding: app_data[:funding_eligible],
          funded_place: nil,
          teacher_catchment: "england",
          teacher_catchment_country: "United Kingdom of Great Britain and Northern Ireland",
          teacher_catchment_iso_country_code: "GBR",
          funding_choice: :school,
          works_in_school: true,
          works_in_childcare: false,
          ukprn: school.ukprn,
          # This is for change provider feature
          # unassigned: app_data[:label] == APP-006 ? Time.zone.now : nil
        )

        @applications[app_data[:label]] = application
        logger.info "✓ Created #{app_data[:label]}: #{user.email} (#{app_data[:purpose]})"
      end
    end

    def create_user(app_data)
      email = user_email(app_data[:email])

      User.find_or_create_by!(email:) do |user|
        user.full_name = app_data[:full_name]
        user.trn = generate_trn
        user.date_of_birth = Date.new(1990, 1, 1)
        user.ecf_id = SecureRandom.uuid
        user.trn_verified = true
        user.trn_lookup_status = "Found"
      end
    end

    def create_statements!
      # STMT-001: Paid statement for primary cohort
      @statement_paid = Statement.find_or_create_by!(
        cohort: @cohort_primary,
        lead_provider: lead_provider,
        year: cohort_year,
        month: 10,
      ) do |statement|
        statement.deadline_date = Date.new(cohort_year, 10, 15)
        statement.payment_date = Date.new(cohort_year, 10, 20)
        statement.output_fee = true
        statement.state = "paid"
        statement.marked_as_paid_at = Date.new(cohort_year, 10, 20)
        statement.ecf_id = SecureRandom.uuid
      end

      # STMT-002: Payable statement for primary cohort
      @statement_payable = Statement.find_or_create_by!(
        cohort: @cohort_primary,
        lead_provider: lead_provider,
        year: cohort_year,
        month: 11,
      ) do |statement|
        statement.deadline_date = Date.new(cohort_year, 11, 15)
        statement.payment_date = Date.new(cohort_year, 11, 20)
        statement.output_fee = true
        statement.state = "payable"
        statement.ecf_id = SecureRandom.uuid
      end

      logger.info "✓ Created statements: STMT-001 (paid), STMT-002 (payable)"
    end

    def generate_trn
      sprintf("%07d", SecureRandom.random_number(10_000_000))
    end
  end
end
