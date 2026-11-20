class Admin::Settings::Courses::Providers::DeliveryPartnersController < Admin::Settings::Courses::Providers::BaseController
  def new
    @names = [""]
  end

  def create
    @names = Array(params[:names]).map(&:to_s)

    if params[:commit] == "add_more"
      @names << ""
      return render :new
    end

    result = DeliveryPartnerships::CreatePartners.new(course: @course, lead_provider: @lead_provider, names: @names).call

    if result.success?
      redirect_to provider_path, flash: { success: "#{helpers.pluralize(@names.count(&:present?), 'delivery partner')} added" }
    else
      @errors = result.errors
      render :new, status: :unprocessable_content
    end
  end
end
