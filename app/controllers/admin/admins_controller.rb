class Admin::AdminsController < AdminController
  before_action :require_super_admin

  def index
    @pagy, @admins = pagy(AdminUser.all)
  end

  def new
    @admin = AdminUser.new
  end

  def create
    @admin = AdminUser.find_or_initialize_by(email: admin_params[:email])
    @admin.assign_attributes(admin_params)

    if @admin.save
      flash[:success] = "Admin permissions granted to #{@admin.email}"
      redirect_to admin_admins_path
    else
      render :new
    end
  end

  def destroy
    @admin = AdminUser.find(params[:id])

    if @admin == current_admin || @admin.super_admin?
      flash[:error] = "You cannot remove admin permissions from yourself or another super admin."
      redirect_back fallback_location: admin_admins_path
    elsif @admin.destroy!
      redirect_to admin_admins_path, flash: { success: "#{@admin.full_name} deleted" }
    else
      flash[:error] = "Failed to remove admin permissions from #{@admin.email}, please contact technical support if this problem persists."
      redirect_back fallback_location: admin_admins_path
    end
  end

private

  def admin_params
    params.require(:admin_user).permit(:full_name, :email)
  end
end
