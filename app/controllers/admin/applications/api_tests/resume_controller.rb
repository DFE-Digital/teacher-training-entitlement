require Rails.root.join("lib/tasks/api_test/helpers/resume_application")

module Admin
  module Applications
    module APITests
      class ResumeController < APITestsController
        def create
          course_cohort = CourseCohort.includes([:schedule]).find_by_id(params[:course_cohort_id])

          @response = ResumeApplication.new(application: @application, course_cohort:).call
        end
      end
    end
  end
end
