class Admin::DeliveryPartnershipsController < AdminController
  def edit
    @delivery_partner = DeliveryPartner.find(params[:delivery_partner_id])
    @lead_providers = LeadProvider.all.order(:name)
    @course_cohorts = CourseCohort.includes(:course, :cohort).order(:academic_year)
  end
end
