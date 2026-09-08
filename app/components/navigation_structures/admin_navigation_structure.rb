module NavigationStructures
  class AdminNavigationStructure < NavigationStructure
    include Rails.application.routes.url_helpers
    include AdminHelper

    def initialize(current_admin)
      @current_admin = current_admin
    end

  private

    # Returns a hash where the keys are primary nodes and the values are
    # sub nodes nested with the 'nodes: key'
    def structure
      admin_nodes
    end

    def super_admin_nodes
      return {} unless @current_admin.super_admin?

      nodes = {
        Node.new(
          name: "Feature flags",
          href: admin_features_path,
          prefix: "/admin/features",
        ) => [],

        Node.new(
          name: "Admins",
          href: admin_admins_path,
          prefix: "/admin/admins",
        ) => [],
      }

      # Only show API Test Scenarios in development, review, and sandbox environments
      if Rails.env.in?(%w[development review sandbox])
        nodes[Node.new(
          name: "API Test Scenarios",
          href: admin_api_test_scenarios_path,
          prefix: "/admin/api-test-scenarios",
        )] = []
      end

      nodes
    end

    def admin_nodes
      nodes = {
        Node.new(
          name: "Registration periods",
          href: admin_cohorts_path,
          prefix: "/admin/cohorts",
        ) => [],
        Node.new(
          name: "Courses",
          href: admin_courses_path,
          prefix: "/admin/courses",
        ) => [],
        Node.new(
          name: "Applications",
          href: admin_applications_path,
          prefix: "/admin/applications",
        ) => [],
        Node.new(
          name: "Providers",
          href: admin_lead_providers_path,
          prefix: "/admin/providers",
        ) => [],
        Node.new(
          name: "Delivery partners",
          href: admin_delivery_partners_path,
          prefix: "/admin/delivery-partners",
        ) => [],
        Node.new(
          name: "Users",
          href: admin_users_path,
          prefix: "/admin/users",
        ) => [],
        Node.new(
          name: "Finance",
          href: admin_finance_statements_path,
          prefix: "/admin/finance",
        ) => [],
        Node.new(
          name: "Workplaces",
          href: admin_schools_path,
          prefix: "/admin/schools",
        ) => [],
        Node.new(
          name: "Bulk changes",
          href: admin_bulk_operations_path,
          prefix: "/admin/bulk-changes",
        ) => [],
        Node.new(
          name: "Registration closed",
          href: admin_registration_closed_index_path,
          prefix: "/admin/registration-closed",
        ) => [],
        Node.new(
          name: "Actions log",
          href: admin_actions_log_index_path,
          prefix: "/admin/actions-log",
        ) => [],
      }

      nodes.merge!(super_admin_nodes)

      nodes[Node.new(
        name: "Glossary",
        href: admin_glossary_index_path,
        prefix: "/admin/glossary",
      )] = []

      nodes
    end
  end
end
