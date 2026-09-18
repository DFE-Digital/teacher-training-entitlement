module NavigationStructures
  class AdminNavigationStructure < NavigationStructure
    include Rails.application.routes.url_helpers
    include AdminHelper

    def initialize(current_admin)
      @current_admin = current_admin
    end

    def service_navigation_items
      primary_structure
        .reject { |node| node.name == "Service settings" }
        .map(&:to_service_navigation_item)
    end

    def sub_navigation_heading(_path)
      { text: "Service settings", visible: true }
    end

  private

    # Returns a hash where the keys are primary nodes and the values are
    # sub nodes nested with the 'nodes: key'
    def structure
      admin_nodes
    end

    def super_admin_service_settings_nodes
      return [] unless @current_admin.super_admin?

      nodes = [
        Node.new(
          name: "Create course",
          href: "/admin/course-builder",
        ),
        Node.new(
          name: "Feature flags",
          href: admin_features_path,
        ),

        Node.new(
          name: "Admins",
          href: admin_admins_path,
        ),
      ]

      # Only show API Test Scenarios in development, review, and sandbox environments
      if Rails.env.in?(%w[development review sandbox])
        nodes << Node.new(
          name: "API Test Scenarios",
          href: admin_api_test_scenarios_path,
        )
      end

      nodes
    end

    def service_settings_nodes
      [
        *super_admin_service_settings_nodes,
        Node.new(
          name: "Registration closed",
          href: admin_registration_closed_index_path,
        ),
        Node.new(
          name: "Bulk changes",
          href: admin_bulk_operations_path,
        ),
        Node.new(
          name: "Action logs",
          href: admin_actions_log_index_path,
        ),
        Node.new(
          name: "Workplaces",
          href: admin_schools_path,
        ),
        Node.new(
          name: "Glossary",
          href: admin_glossary_index_path,
        ),
      ]
    end

    def service_settings_prefixes
      service_settings_nodes.map(&:prefix)
    end

    def admin_nodes
      {
        Node.new(
          name: "Service settings",
          href: service_settings_nodes.first.href,
          prefix: service_settings_prefixes,
        ) => service_settings_nodes,
        Node.new(
          name: "Registration periods",
          href: admin_cohorts_path,
        ) => [],
        Node.new(
          name: "Courses",
          href: admin_courses_path,
        ) => [],
        Node.new(
          name: "Applications",
          href: admin_applications_path,
        ) => [],
        Node.new(
          name: "Providers",
          href: admin_lead_providers_path,
        ) => [],
        Node.new(
          name: "Finance",
          href: admin_finance_statements_path,
          prefix: "/admin/finance",
        ) => [],
        Node.new(
          name: "Delivery partners",
          href: admin_delivery_partners_path,
        ) => [],
        Node.new(
          name: "Users",
          href: admin_users_path,
        ) => [],
      }
    end
  end
end
