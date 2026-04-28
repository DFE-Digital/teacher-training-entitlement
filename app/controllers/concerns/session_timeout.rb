module SessionTimeout
  extend ActiveSupport::Concern

  INACTIVITY_TIMEOUT = 30.minutes

  included do
    before_action :check_session_timeout, if: :user_signed_in?
    before_action :update_last_activity, if: :user_signed_in?
  end

private

  def check_session_timeout
    return if session[:last_activity_at].blank?

    if session[:last_activity_at] < INACTIVITY_TIMEOUT.ago
      handle_session_timeout
    end
  end

  def update_last_activity
    session[:last_activity_at] = Time.current
  end

  def handle_session_timeout
    reset_session
    redirect_to root_path, notice: "Your session has expired due to inactivity."
  end

  def user_signed_in?
    session[:user_id].present?
  end
end
