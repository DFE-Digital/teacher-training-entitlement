class CohortsComponent < BaseComponent
  include Rails.application.routes.url_helpers

  attr_accessor :current_path, :current_section, :heading

  def initialize(current_path, cohorts:, base_path:)
    @current_path = current_path
    @cohorts = cohorts
    @base_path = base_path
    @heading = { text: "Cohorts", visible: true }
  end

  def render?
    structure.present?
  end

  def cohort_nodes
    @cohorts.map do |cohort|
      NavigationStructure::Node.new(
        name: cohort.description,
        href: public_send(:"cohort_#{@base_path}", cohort),
        prefix: public_send(:"cohort_#{@base_path}", cohort),
      )
    end
  end

  def all_node
    NavigationStructure::Node.new(
      name: "All",
      href: public_send(@base_path),
      prefix: public_send(@base_path),
    )
  end

  def structure
    [all_node, *cohort_nodes]
  end

  def navigation_link(section)
    link_to(
      section.name,
      section.href,
      class: "x-govuk-sub-navigation__link",
      aria: { current: current?(section.prefix) },
    )
  end

  def navigation_item_classes(section)
    class_names(
      "x-govuk-sub-navigation__section-item",
      "x-govuk-sub-navigation__section-item--current" => current?(section.prefix),
    )
  end

  def render_heading
    heading_text = heading[:text].presence || "Navigation"
    heading_class = class_names(
      "x-govuk-sub-navigation__heading",
      "govuk-heading-s",
      "govuk-visually-hidden" => !heading[:visible],
    )

    tag.h2(heading_text, class: heading_class, id: aria_key)
  end

  def aria_key
    @aria_key ||= "sub-navigation-heading-#{SecureRandom.base58(4)}"
  end

private

  def current?(prefix)
    # return nil instead of false so Rails' link helper drops the
    # attribute rather than setting "current='false'"
    return nil unless prefix

    current_path == prefix
  end
end
