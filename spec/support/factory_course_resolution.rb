# Resolves the hash keys accepted by the delivery partner / lead provider
# factories (Course, CourseCohort or Cohort) to the course a course-level
# delivery partnership belongs to.
module FactoryCourseResolution
module_function

  def course_for(key)
    case key
    when Course
      key
    when CourseCohort
      key.course
    when Cohort
      (CourseCohort.find_by(cohort: key) || FactoryBot.create(:course_cohort, cohort: key)).course
    else
      raise ArgumentError, "Cannot resolve course from #{key.inspect}"
    end
  end
end
