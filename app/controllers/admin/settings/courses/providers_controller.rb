class Admin::Settings::Courses::ProvidersController < AdminController
  before_action :require_super_admin

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  def show
    @course = Course.find(params[:course_id])
    @lead_provider = @course.lead_providers.find(params[:id])
    contract_details = @course.contract_years
                         .where(lead_provider: @lead_provider)
                         .order(academic_year: :asc)
    @contract_generic = contract_details.detect { _1.academic_year.blank? }
    @contract_years = contract_details.select { _1.academic_year.present? }
    @pagy_delivery_partnerships, @delivery_partnerships = pagy(@course.delivery_partnerships.includes(:delivery_partner).where(lead_provider: @lead_provider))
  end

private

  def not_found
    render "errors/not_found", status: :not_found
  end
end
