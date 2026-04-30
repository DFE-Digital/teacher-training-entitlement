class AdminController < ApplicationController
  layout "admin"
  before_action :require_admin
  skip_before_action :authenticate_user!

  include Pagy::Backend

private

  def require_admin
    flash_notice_and_redirect unless current_admin
  end

  def require_super_admin
    flash_notice_and_redirect unless current_admin.super_admin?
  end

  def flash_notice_and_redirect
    flash[:alert] = { title: "Unauthorized", message: "Sign in with your administrator account" }
    redirect_to sign_in_path
  end
end
