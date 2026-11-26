module Registrations
  module StepConfiguration
    def configure_step(step_id, **configuration)
      @step_configurations ||= {}
      @step_configurations[step_id.to_sym] = (@step_configurations[step_id.to_sym] || {}).merge(configuration)
    end

    def configure_steps(configurations)
      configurations.each { |step_id, configuration| configure_step(step_id, **configuration) }
    end

    def step_configurations
      inherited_configurations = superclass.step_configurations if superclass.respond_to?(:step_configurations)
      inherited_configurations.to_h.merge(@step_configurations || {})
    end
  end
end
