module GuidanceHelper
  def guidance_sidebar_structure
    @guidance_sidebar_structure ||= [
      NavigationStructure::Node.new(
        name: "Get started",
        href: api_guidance_page_path(page: "get-started"),
      ),
      NavigationStructure::Node.new(
        name: "How the API works",
        href: api_guidance_page_path(page: "api-introduction"),
      ),
      NavigationStructure::Node.new(
        name: "Test environments",
        href: api_guidance_page_path(page: "test-environments"),
      ),
      NavigationStructure::Node.new(
        name: "How-to guides",
        href: api_guidance_page_path(page: "how-to-guides/how-courses-work"),
        prefix: "/api/guidance/how-to-guides",
        nodes: [
          NavigationStructure::Node.new(
            name: "How courses work",
            href: api_guidance_page_path(page: "how-to-guides/how-courses-work"),
          ),
          NavigationStructure::Node.new(
            name: "View, accept or reject applications",
            href: api_guidance_page_path(page: "how-to-guides/view-accept-or-reject-applications"),
          ),
          NavigationStructure::Node.new(
            name: "View participant data",
            href: api_guidance_page_path(page: "how-to-guides/view-participant-data"),
            prefix: "/api/guidance/how-to-guides/view-and-update-participant-data",
          ),
          NavigationStructure::Node.new(
            name: "View payments information",
            href: api_guidance_page_path(page: "how-to-guides/view-payments-information"),
          ),
          NavigationStructure::Node.new(
            name: "Submit, view and void declarations",
            href: api_guidance_page_path(page: "how-to-guides/submit-view-and-void-declarations"),
          ),
        ],
      ),
      NavigationStructure::Node.new(
        name: "Process diagrams",
        href: api_guidance_page_path(page: "process-diagrams/participant-training-journey-diagrams"),
        prefix: "/api/guidance/process-diagrams",
      ),
      NavigationStructure::Node.new(
        name: "Release notes",
        href: api_guidance_page_path(page: "release-notes"),
      ),
      NavigationStructure::Node.new(
        name: "Roadmap",
        href: api_guidance_page_path(page: "roadmap"),
      ),
    ]
  end
end
