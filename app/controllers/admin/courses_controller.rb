class Admin::CoursesController < AdminController
  def index
    @pagy, @courses = pagy(Course.order(name: :asc))
  end

  def show
    @course = Course.find(params[:id])
  end
end
