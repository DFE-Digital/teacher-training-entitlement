# frozen_string_literal: true

module ValidTestDataGenerators
  # Service to seed test data for Lead Provider API Test Scenarios
  # Based on: @tte-board/documentation/lead_provider_api_test_scenarios.md
  #
  # NOTE: the change-provider scenario is flagged via `change_provider` in
  # db/seeds/api_test_scenarios.yml
  class APITestScenariosSeeder
    Outcome = Data.define(:success, :error, :applications_count, :academic_year) do
      def initialize(success:, error: nil, applications_count: nil, academic_year: nil)
        super(success:, error:, applications_count:, academic_year:)
      end
    end

    RECRUITMENT_TARGETS = [50, 100, 150, 200].freeze
    TEACHER_FUNDING_AMOUNTS = [600, 700, 800].freeze

    STARTED_LIFECYCLE = [Application::ACCEPTED, :started_declaration, Application::STARTED].freeze
    COMPLETED_LIFECYCLE = (STARTED_LIFECYCLE + [:completed_declaration, Application::COMPLETED]).freeze
    DEFERRED_LIFECYCLE = (STARTED_LIFECYCLE + [Application::DEFERRED]).freeze
    WITHDRAWAL_LIFECYCLES = [
      DEFERRED_LIFECYCLE,             # auto withdrawn
      STARTED_LIFECYCLE,              # withdraw after started acceptance
      [Application::ACCEPTED].freeze, # withdraw after acceptance
    ].freeze

    attr_reader :lead_provider, :academic_year, :logger

    class << self
      def applications_data
        seed_config["applications"].map(&:deep_symbolize_keys)
      end

      def custom_email_templates
        seed_config["custom_email_templates"] || {}
      end

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

    private

      def seed_config
        @seed_config ||= YAML.load_file(Rails.root.join("db/seeds/api_test_scenarios.yml"))
      end
    end

    def initialize(lead_provider:,
                   course_identifier: "tte-early-years",
                   academic_year: Date.current.year,
                   logger: Rails.logger)
      @lead_provider = lead_provider
      @course_identifier = course_identifier
      @academic_year = academic_year.to_i
      @logger = logger
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
        academic_year:,
        ]
    rescue StandardError => e
      logger.error "APITestScenariosSeeder failed: #{e.message}"
      logger.error e.backtrace.join("\n")

      Sentry.capture_exception(e)
      Outcome[success: false, error: e.message]
    end

    def custom_data(nb_cohort:, nb_app_per_state:)
      registration_periods
        .take(nb_cohort)
        .each do |registration_starts_at, cohort_year|
        create_data!(registration_starts_at:, academic_year: cohort_year, apps_per_state: nb_app_per_state)
      end
    end

    def test_user_ecf_ids
      applications_data.map { |app| user_ecf_id(app[:participant_id]) }
    end

  private

    def applications_data
      self.class.applications_data
    end

    def registration_periods
      Enumerator.new do |yielder|
        year = academic_year
        loop do
          yielder << [Date.new(year, 7, 1), year] # for autumn term
          yielder << [Date.new(year, 12, 1), year] # for spring term
          year += 1
        end
      end
    end

    def test_emails
      applications_data.map { |app| user_email(app[:email]) }
    end

    def user_email(email, user_id = nil)
      if custom_email_template.present? && user_id.present?
        custom_email(user_id)
      else
        email.gsub("example", self.class.to_dns_name(lead_provider.name))
      end
    end

    def custom_email_template
      self.class.custom_email_templates[lead_provider.name]
    end

    def custom_email(user_id)
      prefix, domain = custom_email_template.split("@")
      "#{prefix}+#{user_id}@#{domain}"
    end

    def apply_custom_email_template(user)
      return user if custom_email_template.blank?

      email = custom_email(user.id)
      user.update!(email:) unless user.email == email
      user
    end

    def test_scenarios_drop_data!
      test_users = User.where(ecf_id: test_user_ecf_ids)
      application_ids = lead_provider.applications.where(user: test_users).pluck(:id)

      if application_ids.any?
        declarations = Declaration.where(application_id: application_ids)
        declaration_ids = declarations.pluck(:id)
        statement_ids = declarations.distinct.pluck(:statement_id)

        ParticipantOutcome.where(declaration_id: declaration_ids).delete_all
        declarations.delete_all
        ApplicationEvent.where(application_id: application_ids).delete_all
        Application.where(id: application_ids).delete_all

        delete_orphaned_statements(statement_ids)
      end

      delete_test_users_without_applications(test_users)
    end

    def delete_orphaned_statements(statement_ids)
      Statement.where(id: statement_ids).where.missing(:declarations).find_each do |statement|
        statement.adjustments.delete_all
        statement.delete
      end
    end

    def delete_test_users_without_applications(test_users)
      user_ids_with_applications = Application.where(user_id: test_users.select(:id)).distinct.pluck(:user_id)
      test_users.where.not(id: user_ids_with_applications).delete_all
    end

    def test_scenarios_create_data!
      course_cohorts = registration_periods
                         .take(4)
                         .map do |registration_starts_at, cohort_year|
        # for the current academic year make training start now to simplify testing
        training_starts_now = registration_starts_at.year == academic_year
        course_cohort_setup(registration_starts_at:, academic_year: cohort_year, training_starts_now:)
      end

      applications_data.each do |app_data|
        create_app(
          course_cohort: course_cohorts[app_data[:cohort_offset]],
          status: Application::PENDING,
          eligible_for_funding: app_data[:funding_eligible],
          user: create_user(app_data),
        ).tap do |application|
          if app_data[:change_provider]
            change_provider(application:)
            create_app_event(application:, event: :changed_provider)
          end
        end
      end
    end

    def create_data!(registration_starts_at:, academic_year:, apps_per_state:)
      course_cohort = course_cohort_setup(registration_starts_at:, academic_year:)
      applications_setup(course_cohort:, apps_per_state:)
    end

    def course
      @course ||= Course.find_by!(identifier: @course_identifier)
    end

    def create_random_user(with_trn: true)
      name = Faker::Name.unique.name
      email = "#{name.tr(" '.", "").downcase}@#{self.class.to_dns_name(lead_provider.name)}.com"

      user = User.find_or_create_by!(email:) do |u|
        u.ecf_id = SecureRandom.uuid
        u.full_name = name
        u.trn = generate_trn if with_trn
        u.date_of_birth = Faker::Date.birthday(min_age: 20)
        u.trn_lookup_status = "Found" if with_trn
      end

      apply_custom_email_template(user)
    end

    def create_user(app_data)
      ecf_id = user_ecf_id(app_data[:participant_id])
      fallback_email = user_email(app_data[:email])
      user = User.find_by(ecf_id:) || User.find_by(email: fallback_email)

      if user
        user.update!(full_name: app_data[:full_name], trn_lookup_status: "Found", ecf_id:)
      else
        user = User.create!(
          full_name: app_data[:full_name],
          trn: generate_trn,
          date_of_birth: Faker::Date.birthday(min_age: 20),
          trn_lookup_status: "Found",
          ecf_id:,
          email: fallback_email,
        )
      end

      apply_custom_email_template(user)
    end

    def user_ecf_id(index)
      [
        "4e87fadb",
        "f678",
        "4934",
        sprintf("%04x", lead_provider.id % 0x10000),
        sprintf("%012d", index),
      ].join("-")
    end

    def generate_trn
      sprintf("%07d", SecureRandom.random_number(10_000_000))
    end

    def delivery_partners
      @delivery_partners ||= (1..5).map do |i|
        DeliveryPartner.find_by(name: "Delivery partner #{i}") || DeliveryPartner.create!(name: "Delivery partner #{i}", ecf_id: SecureRandom.uuid)
      end
    end

    def course_cohort_setup(registration_starts_at:, academic_year:, training_starts_now: false)
      cohort = find_or_create_cohort(registration_starts_at:, academic_year:)
      course_cohort = upsert_course_cohort(cohort:, registration_starts_at:, academic_year:, training_starts_now:)
      create_or_update_milestones!(course_cohort:, training_starts_now:)
      create_or_update_lead_provider_contract(course_cohort:)
      create_delivery_partnerships
      course_cohort
    end

    def find_or_create_cohort(registration_starts_at:, academic_year:)
      identifier = Cohort.new(registration_starts_at:, start_year: academic_year).tap(&:valid?).identifier
      Cohort.find_by(identifier:) || Cohort.create!(registration_starts_at:, funding_cap: true, start_year: academic_year)
    end

    def upsert_course_cohort(cohort:, registration_starts_at:, academic_year:, training_starts_now:)
      course_cohort = CourseCohort.find_or_initialize_by(course:, cohort:)
      course_cohort.update!(
        academic_year:,
        term_identifier: CourseCohort.school_term(nominal_training_start_date(registration_starts_at)),
        training_starts_at: training_starts_at_for(registration_starts_at:, training_starts_now:),
      )
      course_cohort
    end

    # Nominal training start (~3 months after registration opens) used to derive the school term
    def nominal_training_start_date(registration_starts_at)
      (registration_starts_at + 3.months).to_date
    end

    def training_starts_at_for(registration_starts_at:, training_starts_now:)
      (training_starts_now ? 2.days.ago : nominal_training_start_date(registration_starts_at)).to_date
    end

    def create_or_update_milestones!(course_cohort:, training_starts_now:)
      started_window_start_date = course_cohort.training_starts_at
      nominal_completed_window_start_date = started_window_start_date + 6.months

      create_or_update_milestone!(
        course_cohort:,
        declaration_type: Milestone::STARTED,
        acceptance_window_start_date: started_window_start_date,
        acceptance_window_end_date: started_window_start_date + 2.months,
        payment_percentage: 0.6,
      )

      completed_window_start_date = if training_starts_now
                                      started_window_start_date + 1.day # to keep the milestone ordering
                                    else
                                      nominal_completed_window_start_date
                                    end
      create_or_update_milestone!(
        course_cohort:,
        declaration_type: Milestone::COMPLETED,
        acceptance_window_start_date: completed_window_start_date,
        acceptance_window_end_date: nominal_completed_window_start_date + 2.months,
        payment_percentage: 0.4,
      )
    end

    def create_delivery_partnerships
      delivery_partners.each do |delivery_partner|
        delivery_partner.delivery_partnerships.find_or_create_by!(lead_provider:, course:)
      end
    end

    def create_or_update_lead_provider_contract(course_cohort:)
      recruitment_target = RECRUITMENT_TARGETS[course_cohort.academic_year % RECRUITMENT_TARGETS.size]
      teacher_funding = TEACHER_FUNDING_AMOUNTS[course_cohort.academic_year % TEACHER_FUNDING_AMOUNTS.size]

      course_cohort_provider = course_cohort.course_cohort_providers.find_or_create_by!(lead_provider:)
      course_cohort_provider.update!(recruitment_target:, teacher_funding:)

      ContractYear
        .find_or_initialize_by(lead_provider:, academic_year: course_cohort.academic_year, course:)
        .update!(teacher_funding:, recruitment_target: contract_recruitment_target(course_cohort:))
    end

    # Sum of the year's course cohort targets, so the contract year does not exceed the academic year limit
    def contract_recruitment_target(course_cohort:)
      lead_provider.course_cohort_providers
        .joins(:course_cohort)
        .where(course_cohorts: { course:, academic_year: course_cohort.academic_year })
        .sum(:recruitment_target)
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
      application = lead_provider.updateable_applications.find_or_initialize_by(user:, course_cohort:)
      application.ecf_id ||= SecureRandom.uuid
      if application.application_lead_providers.current.none?
        application.application_lead_providers.build(lead_provider:, current: true, assigned_at: Time.zone.now)
      end
      application.update!(
        **funding_attributes(status:, eligible_for_funding:),
        status:,
        teacher_catchment: "england",
      )
      application
    end

    def funding_attributes(status:, eligible_for_funding:)
      {
        funded_place: (eligible_for_funding unless status == Application::PENDING),
        eligible_for_funding:,
        funding_eligiblity_status_code: (:ineligible_setting unless eligible_for_funding),
        institution: eligible_for_funding ? institutions_eligible : institutions_ineligible,
        funding_choice: eligible_for_funding ? "school" : (Application.funding_choices.values - %w[school]).sample,
      }
    end

    def create_state_change(application:, event:)
      application.state_changes.create!(event:, lead_provider: application.lead_provider)
    end

    def create_app_event(application:, event:)
      application.application_events.create!(event:, lead_provider: application.lead_provider)
    end

    def declaration_value(milestone, course_cohort:)
      contract = course_cohort.contract(lead_provider:)
      contract.teacher_funding * milestone.payment_percentage
    end

    def create_started_declaration(application:, statement:, declaration_date: nil)
      create_declaration(application:, statement:, declaration_type: :started, declaration_date:)
    end

    def create_completed_declaration(application:, statement:, declaration_date: nil, has_passed: true)
      create_declaration(application:, statement:, declaration_type: :completed, declaration_date:).tap do |declaration|
        ParticipantOutcome
          .new(declaration:, state: has_passed ? "passed" : "failed", completion_date: declaration.declaration_date)
          .save!(validate: false)
      end
    end

    def create_declaration(application:, statement:, declaration_type:, declaration_date: nil)
      milestone = milestone_for(application:, declaration_type:)
      date = declaration_date || declaration_date_for(application:, milestone:)
      value = (declaration_value(milestone, course_cohort: application.course_cohort) if application.funded_place)
      declaration = application.declarations.build(
        declaration_type:,
        declaration_date: date,
        state: :eligible,
        delivery_partner: delivery_partner_for(application),
        milestone:,
        lead_provider: application.lead_provider,
        statement:,
        value:,
      )
      declaration.save!(validate: false)
      declaration
    end

    def delivery_partner_for(application)
      return unless application.institution&.in_england?

      application.lead_provider.delivery_partners_for_course_cohort(course_cohort: application.course_cohort).sample
    end

    def declaration_date_for(application:, milestone:)
      acceptance_window_start_date = milestone.acceptance_window_start_date_for(training_starts_at: application.training_starts_at)
      declaration_date = acceptance_window_start_date + 1.day

      return Time.zone.today if acceptance_window_start_date <= Time.zone.today && declaration_date.future?

      declaration_date
    end

    def applications_setup(course_cohort:, apps_per_state: 5)
      # pending
      (apps_per_state * 3).times do |index|
        create_random_app(course_cohort:, status: Application::PENDING, index:)
      end

      # accepted / rejected
      [Application::ACCEPTED, Application::REJECTED].each do |status|
        apps_per_state.times do |index|
          create_random_app(course_cohort:, status:, index:).tap do |application|
            create_state_change(application:, event: status)
          end
        end
      end

      applications_with_declarations_setup(course_cohort:, apps_per_state:)

      # reassigned
      apps_per_state.times do |index|
        create_random_app(course_cohort:, status: Application::PENDING, index:).tap do |application|
          change_provider(application:)
          create_app_event(application:, event: :changed_provider)
        end
      end
    end

    def create_random_app(course_cohort:, status:, index:, with_trn: [true, false].sample)
      create_app(
        course_cohort:,
        status:,
        eligible_for_funding: index.even?,
        user: create_random_user(with_trn:),
      )
    end

    # declarations cannot be dated in the future, so these applications are
    # only created for cohorts whose acceptance windows have started
    def applications_with_declarations_setup(course_cohort:, apps_per_state:)
      return unless declarations_can_be_created_for?(course_cohort:)

      started_statement = create_open_statement(
        group: course_cohort.course.course_group,
        start_date: acceptance_window_start_date_for(course_cohort:, declaration_type: Milestone::STARTED),
      )
      completed_statement = create_open_statement(
        group: course_cohort.course.course_group,
        start_date: acceptance_window_start_date_for(course_cohort:, declaration_type: Milestone::COMPLETED),
      )

      # started / completed
      {
        Application::STARTED => STARTED_LIFECYCLE,
        Application::COMPLETED => COMPLETED_LIFECYCLE,
      }.each do |status, lifecycle|
        apps_per_state.times do |index|
          create_random_app(course_cohort:, status:, index:, with_trn: true).tap do |application|
            play_lifecycle(application:, lifecycle:, index:, started_statement:, completed_statement:)
          end
        end
      end

      # deferred
      apps_per_state.times do |index|
        create_random_app(course_cohort:, status: Application::DEFERRED, index:).tap do |application|
          play_lifecycle(application:, lifecycle: DEFERRED_LIFECYCLE, index:, started_statement:, completed_statement:)
        end
      end

      # withdrawn
      apps_per_state.times do |index|
        create_random_app(course_cohort:, status: Application::WITHDRAWN, index:).tap do |application|
          lifecycle = WITHDRAWAL_LIFECYCLES[index % WITHDRAWAL_LIFECYCLES.size]
          play_lifecycle(application:, lifecycle:, index:, started_statement:, completed_statement:)
          create_state_change(application:, event: Application::WITHDRAWN)
        end
      end

      # finalize paid statement
      started_statement.prepare_to_freeze!
      started_statement.mark_as_frozen!
    end

    def play_lifecycle(application:, lifecycle:, index:, started_statement:, completed_statement:)
      lifecycle.each do |step|
        case step
        when :started_declaration
          create_started_declaration(application:, statement: started_statement)
        when :completed_declaration
          create_completed_declaration(application:, statement: completed_statement, has_passed: index.even?)
        else
          create_state_change(application:, event: step)
        end
      end
    end

    def declarations_can_be_created_for?(course_cohort:)
      [Milestone::STARTED, Milestone::COMPLETED].all? do |declaration_type|
        acceptance_window_start_date_for(course_cohort:, declaration_type:) <= Time.zone.today
      end
    end

    def milestone_for(application:, declaration_type:)
      application.course_cohort.milestones.find_by!(declaration_type:)
    end

    def acceptance_window_start_date_for(course_cohort:, declaration_type:)
      course_cohort.milestones
        .find_by!(declaration_type:)
        .acceptance_window_start_date_for(training_starts_at: course_cohort.training_starts_at)
    end

    def create_or_update_milestone!(course_cohort:, declaration_type:, acceptance_window_start_date:, acceptance_window_end_date:, payment_percentage:)
      milestone = course_cohort.milestones.find_or_initialize_by(declaration_type:)
      milestone.update!(
        acceptance_window_start_offset: months_between(course_cohort.training_starts_at, acceptance_window_start_date),
        acceptance_window_end_offset: months_between(course_cohort.training_starts_at, acceptance_window_end_date),
        payment_percentage:,
      )
      milestone
    end

    def months_between(start_date, end_date)
      (end_date.year * 12 + end_date.month) - (start_date.year * 12 + start_date.month)
    end

    def change_provider(application:)
      new_provider = LeadProvider.where.not(id: lead_provider.id).order("RANDOM()").first
      raise "Changing provider requires at least one other lead provider" if new_provider.nil?

      application.change_provider!(to: new_provider)
    end

    def create_open_statement(group:, start_date:)
      statement = Statement.find_or_create_by!(
        lead_provider:,
        start_date:,
        course_group: group,
        frequency: :monthly,
      ) do |new_statement|
        new_statement.state = "open"
        new_statement.ecf_id = SecureRandom.uuid
      end

      statement.update_columns(state: "open", marked_as_paid_at: nil) unless statement.open?
      statement
    end
  end
end
