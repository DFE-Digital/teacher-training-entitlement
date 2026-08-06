require "securerandom"

FactoryBot.define do
  factory :application do
    with_school
    user
    status { :pending }
    ecf_id { SecureRandom.uuid }

    transient do
      lead_provider { nil }
      course { Course.find_by(identifier: Course::IDENTIFIERS.first) || create(Course::IDENTIFIERS.first.to_sym) }
      cohort do
        course.cohorts.last
      end
      schedule { course.course_cohorts.last&.schedule || create(:schedule, cohort: course.cohorts.last) }
    end

    course_cohort { course.course_cohorts.last }
    teacher_catchment { course_cohort.cohort.start_year > 2023 ? "england" : nil }
    teacher_catchment_country { "United Kingdom of Great Britain and Northern Ireland" }
    teacher_catchment_iso_country_code { "GBR" }
    funding_choice { Application.funding_choices.keys.first }
    ukprn { rand(10_000_000..99_999_999).to_s }
    funded_place { course_cohort.cohort.funding_cap ? !!eligible_for_funding : nil }

    after(:create) do |application, evaluator|
      lead_provider = evaluator.lead_provider || LeadProvider.first || create(:lead_provider)
      create(:application_lead_provider, :current, application:, lead_provider:)
    end

    trait :with_state_change do
      after(:create) do |application|
        next if application.pending_status?

        application.state_changes << create(:state_change, application.status.to_sym, application:, lead_provider: application.lead_provider)
      end
    end

    trait :with_accepted_event do
      after(:create) do |application|
        application.state_changes << create(:state_change, :accepted, application:, lead_provider: application.lead_provider)
      end
    end

    trait :for_cohort_starting_on do
      transient do
        registration_starts_at { 1.week.ago.to_date.beginning_of_month }
      end

      cohort { create(:cohort, registration_starts_at:) }
      schedule { create(:schedule, cohort:) }
      course_cohort { create(:course_cohort, course:, cohort:, schedule:) }
    end

    trait :with_school do
      transient do
        school { nil }
        school_record { school || create(:school) }
      end

      institution { school_record.institution }
      ukprn { school_record.ukprn }

      works_in_school { true }
      works_in_childcare { false }
      kind_of_nursery { nil }
    end

    trait :with_private_childcare_provider do
      transient do
        provider_record { create(:private_childcare_provider) }
      end

      institution { provider_record.institution }

      works_in_school { false }
      works_in_childcare { true }
      kind_of_nursery { Questionnaires::KindOfNursery::KIND_OF_NURSERY_PRIVATE_OPTIONS.first }
    end

    trait :with_public_childcare_provider do
      transient do
        school_record { create(:school) }
      end

      institution { school_record.institution }

      works_in_school { false }
      works_in_childcare { true }
      kind_of_nursery { Questionnaires::KindOfNursery::KIND_OF_NURSERY_PUBLIC_OPTIONS.first }
    end

    trait :eligible_for_funding do
      eligible_for_funding { true }
    end

    trait :eligible_for_funded_place do
      eligible_for_funding
      funded_place { course_cohort.cohort.funding_cap ? true : nil }
    end

    trait :with_funded_place do
      eligible_for_funding
      funded_place { true }
    end

    trait :without_funded_place do
      eligible_for_funding { false }
      funded_place { false }
    end

    trait :previously_funded do
      after(:create) do |application|
        course = application.course.rebranded_alternative_courses.first
        previous_registration_starts_at = application.cohort.registration_starts_at.prev_month
        previous_registration_starts_at = application.cohort.registration_starts_at.next_month if previous_registration_starts_at.year < 2021

        previous_cohort = Cohort.find_by(registration_starts_at: previous_registration_starts_at) ||
          create(
            :cohort,
            :with_funding_cap,
            registration_starts_at: previous_registration_starts_at,
          )

        if previous_cohort == application.cohort
          registration_starts_at = application.cohort.registration_starts_at.prev_year
          previous_cohort = create(:cohort, :with_funding_cap,
                                   start_year: registration_starts_at.year,
                                   registration_starts_at:)
        end

        create(:application, :accepted, :eligible_for_funding, :for_cohort_starting_on, user: application.user, course:, registration_starts_at: previous_cohort.registration_starts_at)
      end
    end

    trait :with_random_work_setting do
      work_setting { "a_school" }
    end

    trait :with_random_participant_outcome_state do
      participant_outcome_state { "passed" }
    end

    trait :with_random_user do
      user { build(:user, :with_random_name) }
    end

    trait :with_teacher_auth_user do
      user { create(:user, :with_one_login_id) }
    end

    trait :without_teacher_auth_user do
      user { create(:user, provider: nil) }
    end

    trait :with_participant_id_change do
      after(:create) do |application|
        user = application.user

        create(:participant_id_change, to_participant_id: user.ecf_id, user:)
      end
    end

    trait :with_declaration do
      after(:create) do |application|
        if application.schedule.training_starts_at.future?
          application.schedule.update!(
            training_starts_at: 1.month.ago.beginning_of_day,
            training_ends_at: 1.month.from_now.beginning_of_day,
          )
        end

        milestone = application.course_cohort.milestones.find_or_create_by!(declaration_type: Milestone::STARTED) do |record|
          record.acceptance_window_start_date = 1.month.ago.to_date
          record.acceptance_window_end_date = 1.month.from_now.to_date
        end

        application.declarations << create(
          :declaration,
          :started,
          :eligible,
          application:,
          course_cohort: application.course_cohort,
          milestone:,
          declaration_date: milestone.acceptance_window_start_date + 1.day,
        )
      end
    end

    trait :with_application_lead_provider do
      transient do
        old_lead_provider { nil }
      end
      after(:create) do |application, eval|
        lead_provider = eval.old_lead_provider || create(:lead_provider)
        application.application_lead_providers.create!(
          application:,
          lead_provider:,
          assigned_at: application.created_at,
        )
      end
    end

    trait :pending do
      status { Application::PENDING }
    end

    trait :rejected do
      status { Application::REJECTED }
    end

    trait :accepted do
      status { Application::ACCEPTED }
      funded_place { cohort.funding_cap ? !!eligible_for_funding : nil }
    end

    trait :started do
      with_declaration
      status { Application::STARTED }
    end

    trait :completed do
      started
      status { Application::COMPLETED }
      after(:create) do |application|
        application.declarations << create(:declaration, :completed, application:)
      end
    end

    trait :withdrawn do
      with_declaration
      status { Application::WITHDRAWN }

      after(:create) do |application|
        application.state_changes.create!(
          event: Application::WITHDRAWN,
          lead_provider: application.lead_provider,
          metadata: { reason: "other" },
        )
      end
    end

    trait :deferred do
      with_declaration
      status { Application::DEFERRED }

      after(:create) do |application|
        application.state_changes.create!(
          event: Application::DEFERRED,
          lead_provider: application.lead_provider,
          metadata: { reason: "other" },
        )
      end
    end

    trait :manual_review do
      review_status { "Needs review" }
    end
  end
end
