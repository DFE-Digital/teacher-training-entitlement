module Admin
  module Applications
    module APITests
      class ResumeController < APITestsController
        def create
          cohort = Cohort.find_by_id(params[:cohort_id])

          @response = ::APITests::ResumeApplication.new(application: @application, cohort:).call
        end
      end
    end
  end
end
