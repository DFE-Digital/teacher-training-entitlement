module AdminHelper
  def admin_navigation_structure
    @admin_navigation_structure ||= NavigationStructures::AdminNavigationStructure.new(current_admin)
  end

  def admin_service_navigation_items
    return [] unless current_admin

    [
      *admin_navigation_structure.service_navigation_items,
      {
        href: admin_sign_out_path,
        text: "Sign out",
        classes: "ml-auto",
      },
    ]
  end

  def review_status_tag(review_status)
    case review_status
    when "Needs review"
      govuk_tag(text: "Needs review", colour: "blue")
    when "Awaiting information"
      govuk_tag(text: "Awaiting information", colour: "yellow")
    when "Re-register", "Decision made"
      govuk_tag(text: review_status, colour: "grey")
    else
      review_status.presence
    end
  end
end
