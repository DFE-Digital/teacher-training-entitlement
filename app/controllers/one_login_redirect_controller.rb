class OneLoginRedirectController < ApplicationController
  skip_before_action :authenticate_user!

  def create
    Analytics::DfeCustomEvents.new(type: :one_login_started, request:).send_event

    redirect_to user_teacher_auth_omniauth_authorize_path, status: :temporary_redirect
  end
end
