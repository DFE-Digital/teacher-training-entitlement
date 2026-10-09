class HandleSubmissionForStore
  attr_reader :store, :application

  def initialize(store:)
    @store = store
  end

  def call
    ActiveRecord::Base.transaction do
      @application = user.applications.create!(
        course_cohort:,
        application_lead_providers: [ApplicationLeadProvider.new(current: true, lead_provider_id: store["lead_provider_id"], assigned_at: Time.zone.now)],
        institution: (institution_from_store if inside_catchment?),
        eligible_for_funding: funding_eligibility_service.funded?,
        funding_eligiblity_status_code: funding_eligibility_service.funding_eligiblity_status_code,
        funding_choice:,
        teacher_catchment:,
        work_setting: store["work_setting"],
        registration_data: store.except("generated_confirmation_code", "current_user", "current_user_id"),
        status: Application::PENDING,
      )
      enqueue_send_application_submission_email_job(application)
    end
  end

private

  def query_store
    @query_store ||= RegistrationQueryStore.new(store:)
  end

  delegate :course_cohort,
           :inside_catchment?,
           to: :query_store

  def institution_from_store
    return nil if store["institution_id"].blank?

    @institution_from_store ||= Institution.find(store["institution_id"])
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

  def teacher_catchment
    store["teacher_catchment"]
  end
end
