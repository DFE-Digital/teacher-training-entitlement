class SuperAdminController < AdminController
  before_action :require_super_admin

private

  def require_super_admin
    unless current_admin.super_admin?
      flash[:alert] = { title: "Unauthorized", message: "Sign in with your administrator account" }
      redirect_to sign_in_path
    end
  end
end
