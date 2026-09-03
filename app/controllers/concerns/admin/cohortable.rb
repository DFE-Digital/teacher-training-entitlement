module Admin
  module Cohortable
    extend ActiveSupport::Concern

    included do
      before_action :set_cohorts
    end

  protected

    def set_cohorts
      @course_cohorts = CourseCohort.includes(:cohort)
                                     .joins(:cohort)
                                     .select("DISTINCT ON (course_cohorts.cohort_id) course_cohorts.*")
                                     .order("course_cohorts.cohort_id, cohorts.registration_starts_at DESC")
      @current_cohort = params[:cohort_id] ? Cohort.find(params[:cohort_id]) : nil
    end
  end
end
