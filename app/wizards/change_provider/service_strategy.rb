module ChangeProvider
  class ServiceStrategy
    def self.for(application:, wizard:)
      if wizard.current_step_name == :"check-answers"
        Applications::ChangeLeadProvider.new(
          application:,
          new_provider: wizard.current_step.new_provider,
        )
      end
    end
  end
end
