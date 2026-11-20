module Registrations
  class StepServiceExecutor
    def initialize(router_step:, execute_point:)
      @router_step = router_step
      @execute_point = execute_point
    end

    def call
      service_classes.each do |service_class|
        service_class.new(router_step:).call
      end
    end

  private

    attr_reader :router_step, :execute_point

    def service_classes
      service_config.filter_map { |service|
        next unless service.fetch("execute_point", service[:execute_point]).to_s == execute_point.to_s

        service.fetch("class_name", service[:class_name])
      }.map(&:constantize)
    end

    def service_config
      router_step.registration_step.config["services"] || []
    end
  end
end
