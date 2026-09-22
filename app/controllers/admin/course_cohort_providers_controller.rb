module Admin
  class CourseCohortProvidersController < AdminController
    before_action :course
    before_action :course_cohort
    before_action :ensure_super_admin
    before_action :lead_providers

    def show; end

    def update
      service = CourseCohorts::Update.new(
        course_cohort: @course_cohort,
        selected_lead_providers: selected_lead_providers,
      )
      service.call
      if service.errors.blank?
        flash[:success] = "Course providers updated"
        redirect_to admin_cohort_course_path(@course_cohort.cohort, @course_cohort.course)
      else
        @course_cohort = service.course_cohort
        @selected_lead_providers = service.selected_lead_providers
        render :show, status: :unprocessable_content
      end
    end

  private

    def course
      @course ||= Course.find(params[:course_id])
    end

    def course_cohort
      @course_cohort ||= @course.course_cohorts.find(params[:id])
    end

    def course_cohort_params
      params.require(:course_cohort)
        .permit(lead_providers: {})
    end

    def lead_providers
      @lead_providers ||= LeadProvider.order(:name)
      @selected_lead_providers = @course_cohort.course_cohort_providers.includes(:lead_provider).map do |ccp|
        [ccp.lead_provider, ccp.attributes]
      end
    end

    def selected_lead_providers
      selected_providers = course_cohort_params[:lead_providers]
                             &.select { |_, attrs| attrs["id"].present? && attrs["id"] != "0" } || {}

      selected_providers.to_hash.map do |id, contract|
        [LeadProvider.find(id), contract]
      end
    end

    def ensure_super_admin
      return if current_admin.super_admin?

      flash[:error] = "You must be a super admin to change course cohort providers"
      redirect_to admin_cohort_course_path(@course_cohort.cohort, @course)
    end
  end
end
