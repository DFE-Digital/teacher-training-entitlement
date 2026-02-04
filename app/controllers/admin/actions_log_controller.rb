class Admin::ActionsLogController < AdminController
  def search
    if params[:admin_id].blank?
      redirect_to admin_actions_log_index_path
    else
      redirect_to admin_actions_log_path(params[:admin_id])
    end
  end

  def show
    @admin = AdminUser.find(params[:id])
    versions = PaperTrail::Version
      .includes(:item)
      .where(item_type: "Application", whodunnit: "AdminUser #{@admin.id}")
      .order(created_at: :desc)
    @pagy, @versions = pagy(versions)
  end
end
