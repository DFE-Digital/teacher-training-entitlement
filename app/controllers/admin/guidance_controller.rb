class Admin::GuidanceController < AdminController
  def index
    @page = Guidance::IndexPage.new
  end

  def show
    @page = Guidance::GuidancePage.new(params[:page], template_dir: "admin/guidance")

    render template: @page.template
  rescue ActionView::MissingTemplate
    raise ActionController::RoutingError, "Not Found"
  end
end
