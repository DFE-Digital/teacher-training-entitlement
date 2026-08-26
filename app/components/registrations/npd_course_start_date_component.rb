module Registrations
  class NpdCourseStartDateComponent < BaseCustomViewComponent
    def application_course_start_date
      course_cohort&.name || "Registration closed"
    end

  private

    def course_cohort
      @course_cohort ||= existing_course_cohort || CourseCohort.next_open_for(course: Course.reception)
    end

    def existing_course_cohort
      CourseCohort.find_by(id: @wizard.state_store["course_cohort_id"])
    end
  end
end
