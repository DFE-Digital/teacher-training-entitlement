module NavigationStructures
  class GuidanceNavigationStructure < NavigationStructure
    include Rails.application.routes.url_helpers

    def sidebar_structure
      [
        Node.new(
          name: "Get started",
          href: api_guidance_page_path(page: "get-started"),
          prefix: "/api/guidance/get-started",
        ),
        Node.new(
          name: "How the API works",
          href: api_guidance_page_path(page: "api-introduction"),
          prefix: "/api/guidance/api-introduction",
        ),
        Node.new(
          name: "Test environments",
          href: api_guidance_page_path(page: "test-environments"),
          prefix: "/api/guidance/test-environments",
        ),
        Node.new(
          name: "What's new",
          href: api_guidance_page_path(page: "release-notes"),
          prefix: "/api/guidance/release-notes",
        ),
        Node.new(
          name: "How-to guides",
          href: api_guidance_page_path(page: "how-to-guides/how-courses-work"),
          prefix: "/api/guidance/how-to-guides",
          nodes: [
            Node.new(
              name: "How courses work",
              href: api_guidance_page_path(page: "how-to-guides/how-courses-work"),
              prefix: "/api/guidance/how-to-guides/how-courses-work",
            ),
            Node.new(
              name: "View, accept or reject applications",
              href: api_guidance_page_path(page: "how-to-guides/view-accept-or-reject-applications"),
              prefix: "/api/guidance/how-to-guides/view-accept-or-reject-applications",
            ),
            Node.new(
              name: "View and update participant data",
              href: api_guidance_page_path(page: "how-to-guides/view-and-update-participant-data"),
              prefix: "/api/guidance/how-to-guides/view-and-update-participant-data",
            ),
            Node.new(
              name: "View payments information",
              href: api_guidance_page_path(page: "how-to-guides/view-payments-information"),
              prefix: "/api/guidance/how-to-guides/view-payments-information",
            ),
            Node.new(
              name: "Submit, view and void declarations",
              href: api_guidance_page_path(page: "how-to-guides/submit-view-and-void-declarations"),
              prefix: "/api/guidance/how-to-guides/submit-view-and-void-declarations",
            ),
          ],
        ),
        Node.new(
          name: "Process diagrams",
          href: api_guidance_page_path(page: "process-diagrams/participant-training-journey-diagrams"),
          prefix: "/api/guidance/process-diagrams",
        ),
        Node.new(
          name: "Roadmap",
          href: api_guidance_page_path(page: "roadmap"),
          prefix: "/api/guidance/roadmap",
        ),
      ]
    end

  private

    def structure
      {
        Node.new(
          name: "Get started",
          href: api_guidance_page_path(page: "get-started"),
          prefix: "/api/guidance/get-started",
        ) => [],
        Node.new(
          name: "How the API works",
          href: api_guidance_page_path(page: "api-introduction"),
          prefix: "/api/guidance/api-introduction",
        ) => [],
        Node.new(
          name: "Test environments",
          href: api_guidance_page_path(page: "test-environments"),
          prefix: "/api/guidance/test-environments",
        ) => [],
        Node.new(
          name: "What's new",
          href: api_guidance_page_path(page: "release-notes"),
          prefix: "/api/guidance/release-notes",
        ) => [],
        Node.new(
          name: "How-to guides",
          href: api_guidance_page_path(page: "/", anchor: "how-to-guides"),
          prefix: "/api/guidance/how-to-guides",
        ) => [],
        Node.new(
          name: "Process diagrams",
          href: api_guidance_page_path(page: "/", anchor: "process-diagrams"),
          prefix: "/api/guidance/process-diagrams",
        ) => [],
        Node.new(
          name: "Roadmap",
          href: api_guidance_page_path(page: "roadmap"),
          prefix: "/api/guidance/roadmap",
        ) => [],
      }
    end
  end
end
