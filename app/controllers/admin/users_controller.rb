class Admin::UsersController < AdminController
  def show
    @user = User.find_by!(ecf_id: params[:id])
    @applications = @user.applications.includes(:course, :lead_provider, :institution).order(:created_at, :id)
  end
end
