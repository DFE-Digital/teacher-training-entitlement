module Admin
  module Cohortable
    extend ActiveSupport::Concern
    include DateHelper

    included do
      before_action :set_cohorts
    end

  protected

    def set_cohorts
      @course_cohorts = CourseCohort.includes(:cohort)
                                     .joins(:cohort)
                                     .select("DISTINCT ON (course_cohorts.cohort_id) course_cohorts.*")
                                     .order("course_cohorts.cohort_id, cohorts.registration_starts_at DESC")
      @current_cohort = params[:cohort_id].presence ? Cohort.find(params[:cohort_id]) : nil
      @current_academic_year = current_academic_year_param
    end

    # Controllers/actions that should default to the current academic year
    # when the request doesn't specify a cohort or academic year to filter
    # by. Override in including controllers to opt in/out per action -
    # defaults to opting in on :index only, matching prior behaviour.
    def default_academic_year_actions
      %i[index]
    end

  private

    # Defaults to the current academic year, without redirecting - keeping
    # this purely a query-parameter concern avoids forcing a URL shape (and
    # therefore a route) onto every controller/action that includes this
    # concern, which previously broke actions/subclasses that don't define
    # a matching cohortable route (e.g. show actions, or controllers that
    # inherit Cohortable but don't render cohort-scoped views).
    def current_academic_year_param
      return if params[:cohort_id].present?
      return params[:academic_year].to_i if params[:academic_year].present?
      return unless default_academic_year_actions.include?(action_name.to_sym)

      get_academic_year(Date.current)
    end
  end
end
