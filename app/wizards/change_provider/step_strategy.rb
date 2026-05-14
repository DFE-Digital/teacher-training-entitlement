module ChangeProvider
  class StepStrategy
    attr_reader :wizard

    delegate :current_step_name, :current_step, to: :wizard

    def initialize(wizard:, action_type:, application:)
      @wizard = wizard
      @action_type = action_type
      @application = application
    end

    def resolve
      if @action_type == :update
        resolve_on_update
      else
        resolve_on_show
      end
    end

  private

    def resolve_on_update
      # If they cannot change provider
      return :exit unless @application.can_change_provider?

      # If they've said "no I don't want to change provider"
      if current_step_name == :start && current_step.confirmation == false
        :exit
      # If they've completed the flow
      elsif current_step_name == :"check-answers"
        :exit
      end
    end

    def resolve_on_show
      # If they cannot change provider
      return :exit unless @application.can_change_provider?

      if current_step_name == :"contact-us"
        nil #  current step is OK
      # If the check answers form is invalid go back to the start
      elsif current_step_name == :"check-answers" && current_step.invalid?
        :start
      end
    end
  end
end
