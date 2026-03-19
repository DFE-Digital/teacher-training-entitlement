class Admin::SchoolsController < AdminController
  def index
    @pagy, @institutions = pagy(scope)
  end

private

  def scope
    AdminService::WorkplaceSearch.new(q: params[:q])
  end
end
