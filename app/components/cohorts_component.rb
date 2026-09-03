class CohortsComponent < BaseComponent
  include Rails.application.routes.url_helpers

  attr_accessor :current_path, :current_section, :heading

  def initialize(current_path, course_cohorts:, base_path:, resource: nil, cohort_path: nil, academic_year_path: nil)
    @current_path = current_path
    @course_cohorts = course_cohorts
    @base_path = base_path
    @resource = resource
    @cohort_path = cohort_path
    @academic_year_path = academic_year_path
    @heading = { text: "Registration periods", visible: true }
  end

  def render?
    @course_cohorts.present?
  end

  def year_nodes
    cohorts_by_academic_year.sort_by { |academic_year, _cohorts| academic_year }.reverse.map do |academic_year, cohorts|
      leaf_nodes = cohort_leaf_nodes(cohorts)
      most_recent_cohort_leaf_node = leaf_nodes.first
      href = academic_year_resource_path(academic_year, fallback: most_recent_cohort_leaf_node.href)

      NavigationStructure::Node.new(
        name: [academic_year, academic_year + 1].join(" / "),
        href:,
        prefix: href,
        nodes: leaf_nodes,
      )
    end
  end

  def all_node
    NavigationStructure::Node.new(
      name: "All",
      href: resource_path,
      prefix: resource_path,
    )
  end

  def structure
    # [all_node, *year_nodes]
    year_nodes
  end

  def navigation_link(section, parent: false)
    link_to(
      section.name,
      section.href,
      class: "x-govuk-sub-navigation__link",
      aria: (parent ? {} : { current: current?(section.prefix) }),
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

  def cohorts_by_academic_year
    @course_cohorts
      .uniq(&:cohort_id)
      .group_by(&:academic_year)
  end

  def cohort_leaf_nodes(course_cohorts)
    course_cohorts
      .sort_by { |course_cohort| course_cohort.cohort.registration_starts_at }
      .reverse
      .map do |course_cohort|
        cohort = course_cohort.cohort

        NavigationStructure::Node.new(
          name: cohort.description,
          href: cohort_resource_path(cohort),
          prefix: cohort_resource_path(cohort),
        )
      end
  end

  def current_section?(section)
    current?(section.prefix) || section.nodes&.any? { |node| current?(node.prefix) }
  end

  def cohort_resource_path(cohort)
    if @cohort_path
      @cohort_path.call(cohort)
    elsif @resource
      public_send(:"cohort_#{@base_path}", @resource, cohort)
    else
      public_send(:"cohort_#{@base_path}", cohort)
    end
  end

  # Filters the resource (courses, applications, lead providers, statements)
  # by academic year, spanning every cohort within that year. Falls back to
  # the most recent child cohort's own link when the resource has no
  # academic-year-scoped route (e.g. a single course's cohort-scoped page).
  def academic_year_resource_path(academic_year, fallback:)
    return @academic_year_path.call(academic_year) if @academic_year_path

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
