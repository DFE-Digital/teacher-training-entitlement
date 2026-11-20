module Admin::Settings
  class CoursesController < AdminController
    before_action :require_super_admin

    def index
      @courses = Course.all
    end

    def show
      @course = Course.includes(contract_years: :lead_provider).find(params[:id])
    end
  end
end
