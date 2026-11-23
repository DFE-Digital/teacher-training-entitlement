class Admin::Settings::Courses::Providers::DeliveryPartnershipsController < Admin::Settings::Courses::Providers::BaseController
  def edit
    @selected_ids = active_partner_ids
    load_partners
  end

  def update
    case params[:commit]
    when "add_new" then add_new
    when "discard" then redirect_to new_admin_settings_course_provider_delivery_partner_path(@course, @lead_provider)
    when "go_back" then render_edit
    when "save_and_continue" then save_changes_and_continue
    when "save" then save_changes
    else head :bad_request
    end
  end

private

  def selected_ids
    Array(params[:delivery_partner_ids]).compact_blank.map(&:to_i)
  end

  def active_partner_ids
    DeliveryPartnership.active.where(course: @course, lead_provider: @lead_provider).pluck(:delivery_partner_id)
  end

  def load_partners
    partners = DeliveryPartner.order(Arel.sql("lower(name)"), :id)
    active = active_partner_ids
    @active_partners, @other_partners = partners.partition { active.include?(_1.id) }
  end

  def render_edit(error: nil)
    @selected_ids = selected_ids
    @error = error
    load_partners
    render :edit, status: error ? :unprocessable_content : :ok
  end

  def add_new
    @changes = pending_changes
    if @changes.any?
      @selected_ids = @changes.selected_ids
      render :unsaved_changes
    else
      redirect_to new_admin_settings_course_provider_delivery_partner_path(@course, @lead_provider)
    end
  end

  def save_changes
    result = update_partnerships!

    return render_edit(error: result.error) unless result.success?

    redirect_to provider_path, flash: { success: summary(result) }
  end

  def save_changes_and_continue
    result = update_partnerships!

    return render_edit(error: result.error) unless result.success?

    redirect_to new_admin_settings_course_provider_delivery_partner_path(@course, @lead_provider), flash: { success: summary(result) }
  end

  def update_partnerships!
    DeliveryPartnerships::Update.new(course: @course, lead_provider: @lead_provider, selected_ids:).call
  end

  def pending_changes
    DeliveryPartnerships::PendingChanges.new(course: @course, lead_provider: @lead_provider, selected_ids:).call
  end

  def summary(result)
    "#{helpers.pluralize(result.added.size, 'delivery partner')} added, #{result.removed.size} removed"
  end
end
