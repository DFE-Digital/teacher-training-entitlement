module AdminHelper
  def admin_navigation_structure
    @admin_navigation_structure ||= NavigationStructures::AdminNavigationStructure.new(current_admin)
  end

  def admin_service_navigation_items
    return [] unless current_admin

    admin_navigation_structure.service_navigation_items
  end
end
