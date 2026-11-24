class Admin::TeachersController < AdminController
  def show
    @teacher = Teacher.find_by!(ecf_id: params[:id])
    @applications = @teacher.applications.includes(:course, :lead_provider, :institution).order(:created_at, :id)
  end
end
