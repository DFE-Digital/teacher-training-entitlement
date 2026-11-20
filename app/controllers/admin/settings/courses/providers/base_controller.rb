class Admin::Settings::Courses::Providers::BaseController < AdminController
  before_action :require_super_admin
  before_action :set_course_and_lead_provider

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

private

  def set_course_and_lead_provider
    @course = Course.find(params[:course_id])
    @lead_provider = @course.lead_providers.find(params[:provider_id])
  end

  def provider_path
    admin_settings_course_provider_path(@course, @lead_provider)
  end

  def not_found
    render "errors/not_found", status: :not_found
  end
end
