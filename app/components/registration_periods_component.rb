class RegistrationPeriodsComponent < BaseComponent
  include Rails.application.routes.url_helpers

  attr_accessor :current_path, :current_section, :heading

  def initialize(current_path, base_path:, resource: nil, current_academic_year: nil)
    @current_path = current_path
    @base_path = base_path
    @resource = resource
    @current_academic_year = current_academic_year
    @heading = { text: "Registration periods", visible: true }
  end

  def render?
    true
  end

  def academic_years_nodes
    academic_years.map do |academic_year, reg_periods|
      leaf_nodes = registration_period_leaf_nodes(reg_periods)
      href = academic_year_resource_path(academic_year, fallback: leaf_nodes.first.href)
      academic_year_link_name = [academic_year, academic_year + 1].join(" / ")

      NavigationStructure::Node.new(
        name: academic_year_link_name,
        href:,
        prefix: href,
        nodes: leaf_nodes,
        current: default_current_year?(academic_year),
      )
    end
  end

  def structure
    academic_years_nodes
  end

  def navigation_link(section, parent: false)
    aria = if !parent && current?(section.prefix)
             { current: true }
           else
             {}
           end

    link_to(
      section.name,
      section.href,
      class: "x-govuk-sub-navigation__link",
      aria:,
    )
  end

  def navigation_item_classes(section)
    class_names(
      "x-govuk-sub-navigation__section-item",
      "x-govuk-sub-navigation__section-item--current" => current_section?(section),
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

  def academic_years
    Cohort.all
      .group_by(&:start_year)
      .sort_by { |academic_year, _| academic_year }
      .reverse
  end

  def registration_period_leaf_nodes(registration_periods)
    registration_periods
      .sort_by(&:registration_starts_at)
      .reverse
      .map do |registration_period|
      NavigationStructure::Node.new(
        name: registration_period.description,
        href: registration_period_path(registration_period),
        prefix: registration_period_path(registration_period),
      )
    end
  end

  def current_section?(section)
    section.current || current?(section.prefix) || section.nodes&.any? { |node| current?(node.prefix) }
  end

  # When a controller silently defaults @current_academic_year (e.g. no
  # cohort_id/academic_year param given, see Admin::Cohortable), the
  # rendered current_path never actually contains that academic year's
  # segment, so the usual current_path == prefix match in `current?` can't
  # highlight it. Explicitly mark that year as current when we're on the
  # resource's bare/unfiltered path and it matches the applied default.
  def default_current_year?(academic_year)
    return false unless @current_academic_year
    return false unless current_path == resource_path

    academic_year == @current_academic_year
  end

  def registration_period_path(registration_period)
    if @resource
      public_send(:"cohort_#{@base_path}", @resource, registration_period)
    else
      public_send(:"cohort_#{@base_path}", registration_period)
    end
  end

  # Filters the resource (courses, applications, lead providers, statements)
  # by academic year, spanning every cohort within that year. Falls back to
  # the most recent child cohort's own link when the resource has no
  # academic-year-scoped route (e.g. a single course's cohort-scoped page).
  def academic_year_resource_path(academic_year, fallback:)
    helper_name = :"academic_year_#{@base_path}"
    return fallback unless respond_to?(helper_name)

    @resource ? public_send(helper_name, @resource, academic_year) : public_send(helper_name, academic_year)
  end

  def resource_path
    if @resource
      public_send(@base_path, @resource)
    else
      public_send(@base_path)
    end
  end

  def current?(prefix)
    # return nil instead of false so Rails' link helper drops the
    # attribute rather than setting "current='false'"
    return nil unless prefix

    current_path == prefix
  end
end
