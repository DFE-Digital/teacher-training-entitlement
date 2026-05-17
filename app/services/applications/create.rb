module Applications
  class Create
    attr_reader :state_store

    delegate :course,
             :eligible_for_funding,
             :funding_choice,
             :funding_eligibility_status_code,
             :inside_catchment?,
             :kind_of_nursery,
             :lead_provider,
             :number_of_pupils,
             :primary_establishment,
             :selected_institution,
             :teacher_catchment,
             :teacher_catchment_country,
             :teacher_catchment_iso_country_code,
             :trn,
             :ukprn,
             :work_setting,
             :works_in_childcare,
             :works_in_school,
             to: :state_store

    def initialize(state_store:, user:)
      @state_store = state_store
      @user = user
    end

    def call
      application = @user.applications.create!(
        course_cohort: CourseCohort.find_by!(course:, cohort: Cohort.current),
        application_lead_providers: [ApplicationLeadProvider.new(current: true, lead_provider:)],
        institution: (selected_institution if inside_catchment?),
        ukprn:,
        eligible_for_funding:,
        funding_eligiblity_status_code: funding_eligibility_status_code,
        funding_choice:,
        teacher_catchment:,
        works_in_school:,
        primary_establishment:,
        number_of_pupils:,
        works_in_childcare:,
        kind_of_nursery:,
        work_setting:,
        raw_application_data: state_store.read,
        on_submission_trn: trn || @user.trn,
        teacher_catchment_country:,
        teacher_catchment_iso_country_code:,
        status: Application::PENDING,
        review_status: nil,
      )

      Emails::SendApplicationSubmissionEmailJob.perform_later(application:)

      application
    end
  end
end
