module Admin
  module Applications
    module APITests
      class ResumeController < APITestsController
        def create
          course_cohort = CourseCohort.find_by_id(params[:course_cohort_id])

          @response = ::APITests::ResumeApplication.new(application: @application, course_cohort:).call
        end
      end
    end
  end
end
