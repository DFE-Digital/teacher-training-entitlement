module API
  class GuidanceController < PublicPagesController
    layout "api_guidance"

    def index
      @page = Guidance::IndexPage.new
    end

    def show
      @page = Guidance::GuidancePage.new(params[:page])

      render template: @page.template
    rescue ActionView::MissingTemplate
      raise ActionController::RoutingError, "Not Found"
    end
  end
end
