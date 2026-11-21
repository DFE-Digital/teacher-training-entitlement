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
        institution:,
        **rule_set.submission_attributes(query_store),
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

  delegate :course_cohort, :institution, to: :query_store

  def enqueue_send_application_submission_email_job(application)
    Emails::SendApplicationSubmissionEmailJob.perform_later(application:)
  end

  def rule_set
    @rule_set ||= FundingEligibilities.for_course(query_store.course)
  end

  def user
    @user ||= store["current_user"].presence || User.find(store["current_user_id"])
  end
end
