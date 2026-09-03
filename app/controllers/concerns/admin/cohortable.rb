module Admin
  module Cohortable
    extend ActiveSupport::Concern

    included do
      before_action :set_cohorts
      before_action :redirect_to_current_academic_year, only: [:index]
    end

  protected

    def set_cohorts
      @course_cohorts = CourseCohort.includes(:cohort)
                                     .joins(:cohort)
                                     .select("DISTINCT ON (course_cohorts.cohort_id) course_cohorts.*")
                                     .order("course_cohorts.cohort_id, cohorts.registration_starts_at DESC")
      @current_cohort = params[:cohort_id] ? Cohort.find(params[:cohort_id]) : nil
      @current_academic_year = params[:academic_year].presence&.to_i
    end

    def redirect_to_current_academic_year
      if params[:cohort_id].blank? && params[:academic_year].blank?
        redirect_to request.path + "/academic-years/#{Date.current.year}"
      end
    end
  end
end
