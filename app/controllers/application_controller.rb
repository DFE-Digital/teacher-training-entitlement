class ApplicationController < ActionController::Base
  include SessionTimeout

  default_form_builder GOVUKDesignSystemFormBuilder::FormBuilder

  before_action :http_basic_authenticate, if: -> { Rails.env.staging? }

  around_action :set_time_zone
  before_action :clear_null_teacher_sessions
  before_action :set_cache_headers
  before_action :authenticate_teacher!
  before_action :set_sentry_user
  before_action :initialize_store

  include DfE::Analytics::Requests

private

  def http_basic_authenticate
    credentials = ENV.fetch("HTTP_BASIC_AUTH_USER_PASS", nil)
    return if credentials.blank?

    authenticate_or_request_with_http_basic do |username, password|
      expected_username, expected_password = credentials.split(":", 2)
      ActiveSupport::SecurityUtils.secure_compare(username, expected_username) &
        ActiveSupport::SecurityUtils.secure_compare(password, expected_password)
    end
  end

  def authenticate_teacher!
    raise "ApplicationController should not be used directly. Use a subclass instead."
  end

  # If the teacher is logged in then we should retrieve from the logged in teacher record,
  # otherwise we should generate a new one for assigning to the NullTeacher record that will
  # later be persisted against a new Teacher record once one is created.
  def feature_flag_id
    return logged_in_teacher.retrieve_or_persist_feature_flag_id if logged_in_teacher.present?

    session[:feature_flag_id] ||= SecureRandom.uuid
  end
  helper_method :feature_flag_id

  def current_teacher
    logged_in_teacher
  end
  helper_method :current_teacher

  # DfE::Analytics::Requests attributes web_request events to current_user.
  alias_method :current_user, :current_teacher

  def set_sentry_user
    Sentry.set_user(id: current_teacher.id) if current_teacher
  end

  # Use current_teacher instead!
  def logged_in_teacher
    Teacher.find_by(id: session[:teacher_id]).tap do |public_teacher|
      PaperTrail.request.whodunnit = "Public User #{public_teacher.id}" if public_teacher
    end
  end

  def current_admin
    return unless session[:admin_id]

    if session[:admin_sign_in_at].nil? || session[:admin_sign_in_at] < Time.zone.now.utc.beginning_of_day
      reset_session
      nil
    else
      AdminUser.find_by(id: session[:admin_id]).tap do |admin_user|
        PaperTrail.request.whodunnit = "AdminUser #{admin_user.id}" if admin_user
      end
    end
  end
  helper_method :current_admin

  def initialize_store
    session["registration_store"] ||= {}
  end

  def set_cache_headers
    no_store
  end

  def clear_null_teacher_sessions
    if session.key?(:registration_store) &&
        session[:registration_store][:current_teacher].is_a?(NullTeacher)
      reset_session
      redirect_to root_path
    end
  end

  def set_time_zone(&block)
    # Display times in UK local time in web UI, ie UTC+1 in summer and UTC+0 in winter
    # Not using config.time_zone because this also impacts times on the API
    # and we have a lot of specs which set up date assuming datetimes are in UTC
    Time.use_zone("London", &block)
  end
end
