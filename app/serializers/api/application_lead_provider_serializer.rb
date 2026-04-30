module API
  class ApplicationLeadProviderSerializer
    class << self
      def render(obj, view:, root:)
        if obj.is_a?(ApplicationLeadProvider)
          render_one(obj, view:, root:)
        else
          render_array(obj, view:, root:)
        end
      end

      def render_one(application_lead_provider, view:, root:)
        view = application_lead_provider.current? ? view : "#{view}_reassigned".to_sym
        ApplicationSerializer.render(application_lead_provider.application, view:, root:)
      end

      def render_array(application_lead_providers, view:, root:)
        result =
          application_lead_providers.map do |alp|
            JSON.parse(render_one(alp, view:, root:))["data"]
          end
        { data: result }.to_json
      end
    end
  end
end
