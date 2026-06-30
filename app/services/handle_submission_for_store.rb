class HandleSubmissionForStore
  attr_reader :store, :application

  def initialize(store:)
    @store = store
  end

  def call
    ActiveRecord::Base.transaction do
      @application = user.applications.create!(
        course_cohort:,
        application_lead_providers: [ApplicationLeadProvider.new(current: true, lead_provider_id: store["lead_provider_id"])],
        institution: (institution_from_store if inside_catchment?),
        ukprn:,
        eligible_for_funding: funding_eligibility_service.funded?,
        funding_eligiblity_status_code: funding_eligibility_service.funding_eligiblity_status_code,
        funding_choice:,
        teacher_catchment:,
        works_in_school: works_in_school?,
        primary_establishment:,
        number_of_pupils:,
        works_in_childcare: !works_in_school?,
        kind_of_nursery: store["kind_of_nursery"],
        work_setting: store["work_setting"],
        referred_by_return_to_teaching_adviser: store["referred_by_return_to_teaching_adviser"],
        raw_application_data: raw_application_data.except("current_user", "current_user_id"),
        on_submission_trn: store["trn"],
        teacher_catchment_country:,
        teacher_catchment_iso_country_code:,
        status: Application::PENDING,
        review_status: nil,
      )
      enqueue_send_application_submission_email_job(application)
    end
  end

private

  def works_in_school?
    return false if institution_from_store.nil?

    institution_from_store.institutionable.is_a?(School)
  end

  def raw_application_data
    # Cutting out confirmation keys since that is not application related data
    # Though I recognise that this means that even though this is meant to be raw
    # it still has a small layer of processing
    store.except("generated_confirmation_code")
  end

  def query_store
    @query_store ||= RegistrationQueryStore.new(store:)
  end

  delegate :course_cohort,
           :inside_catchment?,
           to: :query_store

  def primary_establishment
    institution_from_store&.school? && institution_from_store.school.primary_education_phase?
  end

  def number_of_pupils
    institution_from_store&.school? && institution_from_store.school.number_of_pupils
  end

  def institution_from_store
    return nil if store["institution_id"].blank?

    @institution_from_store ||= Institution.find(store["institution_id"])
  end

  def store_ukprn?
    return false unless inside_catchment?

    institution_from_store&.local_authority? || institution_from_store&.school?
  end

  def ukprn
    institution_from_store.ukprn if store_ukprn?
  end

  def funding_choice
    # It is possible that the applicant had chosen a non-funded path and selected a funding choice
    # before going back a few steps and choosing a funded route. We should clear the funding choice
    # to nil here to reduce confusion
    if funding_eligibility_service.funded?
      nil
    else
      store["funding"]
    end
  end

  def enqueue_send_application_submission_email_job(application)
    Emails::SendApplicationSubmissionEmailJob.perform_later(application:)
  end

  def funding_eligibility_service
    @funding_eligibility_service ||= FundingEligibility.new(
      course:,
      institution: institution_from_store,
      inside_catchment: inside_catchment?,
      query_store:,
    )
  end

  def course
    @course ||= query_store.course
  end

  def user
    @user ||= store["current_user"].presence || User.find(store["current_user_id"])
  end

  def uk_country
    @uk_country ||= ISO3166::Country.find_country_by_any_name("United Kingdom")
  end

  def teacher_catchment_country
    return uk_country.iso_short_name if in_uk_catchement_area?

    store["teacher_catchment_country"]
  end

  def teacher_catchment
    store["teacher_catchment"]
  end

  def in_uk_catchement_area?
    teacher_catchment.in?(Application::UK_CATCHMENT_AREA)
  end

  def teacher_catchment_iso_country_code
    return if teacher_catchment_country.blank?
    return uk_country.alpha3 if in_uk_catchement_area?

    if (country = ISO3166::Country.find_country_by_any_name(teacher_catchment_country))
      country.alpha3
    else
      Sentry.capture_message("Could not find the ISO3166 alpha3 code for #{teacher_catchment_country}.", level: :warning)
      nil
    end
  end
end
