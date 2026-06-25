module Admin
  class ProviderCourseProfilesController < AdminController
    before_action :lead_provider
    before_action :course, only: %i[edit update]
    before_action :provider_course_profile, only: %i[edit update]

    def edit; end

    def update
      if @provider_course_profile.update(provider_course_profile_params)
        redirect_to admin_lead_provider_path(@lead_provider), flash: { success: "Provider course profile updated" }
      else
        render :edit, status: :unprocessable_content
      end
    end

  private

    def lead_provider
      @lead_provider ||= LeadProvider.find(params[:lead_provider_id])
    end

    def course
      @course ||= Course.find(params[:course_id])
    end

    def provider_course_profile
      @provider_course_profile ||= ProviderCourseProfile.find_or_initialize_by(
        lead_provider:,
        course:,
      )
    end

    def provider_course_profile_params
      params.require(:provider_course_profile).permit(:url)
    end
  end
end
