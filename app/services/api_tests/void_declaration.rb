module APITests
  class VoidDeclaration
    include CallAPI
    include Rails.application.routes.url_helpers

    def initialize(declaration: nil)
      @declaration = declaration
    end

    def call
      if declaration.nil?
        raise "[VoidDeclaration] Could not find a declaration"
      end

      url = void_api_v1_declaration_path(declaration.ecf_id)

      api_put(lead_provider:, url:, body: nil)
    end

  private

    def lead_provider
      declaration.lead_provider
    end

    def declaration
      @declaration ||= Declaration.last
    end
  end
end
