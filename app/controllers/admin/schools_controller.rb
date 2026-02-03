class Admin::SchoolsController < AdminController
  def index
    @pagy, @schools = pagy(scope)
  end

private

  def scope
    AdminService::WorkplaceSearch.new(q: params[:q])
  end
end
