module Applications
  class ApplicationsWithLateCompletedDeclarations
    def initialize(cohort: nil, course: nil, lead_provider: nil, status: nil)
      @cohort = cohort
      @course = course
      @lead_provider = lead_provider
      @status = status
    end

    def call
      query = applications_on_current_schedules
                .includes(:user, :current_application_lead_provider, :schedule,
                          :lead_provider, :course_cohort, :course, :cohort)
                .merge(Declaration.started)
                .where.not(id: applications_on_current_schedules.merge(Declaration.completed))

      if lead_provider
        query = query.merge(
          Application.joins(:current_application_lead_provider)
                     .merge(ApplicationLeadProvider.current.where(lead_provider:)),
        )
      end

      query = query.merge(Application.where(status:)) if status

      query = query.where.not(status: excluded_statuses)

      query.order(Schedule.arel_table[:training_ends_at].asc,
                  Application.arel_table[:created_at].asc)
    end

  private

    def applications_on_current_schedules
      Application
        .where.not(status: excluded_statuses)
        .joins(:declarations, :course_cohort)
        .merge(course_cohorts)
    end

    def excluded_statuses
      [Application::WITHDRAWN, Application::REJECTED]
    end

    def course_cohorts
      @course_cohorts ||= begin
        query = CourseCohort.joins(:cohort, :schedule)
                            .merge(Schedule.training_ended_before(Time.zone.today))
                            .merge(Schedule.training_started_before(Time.zone.today))
        query = query.where(cohort:) if cohort
        query = query.where(course:) if course
        query
      end
    end

    attr_reader :cohort, :course, :lead_provider, :status
  end
end
