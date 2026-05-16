module ReceptionRegistrations
  class ServiceStrategy
    def self.for(wizard:, user:)
      if wizard.current_step_name == :"check-answers"
        Applications::Create.new(state_store: wizard.state_store, user:)
      end
    end
  end
end
