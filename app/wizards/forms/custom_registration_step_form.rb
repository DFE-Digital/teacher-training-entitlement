module Forms
  class CustomRegistrationStepForm < RegistrationStepForm
    include DfE::Wizard::Step

    #
    # To render a custom view implement a new View component class here
    #
    def view_component(form:, registration_step:) # rubocop:disable Lint/UnusedMethodArgument
      raise "Please implement this by returning a ViewComponent class"
    end

    #
    # Define he names of the form params your custom view defines
    #
    def form_param_names
      raise "Please implement this by returning a list of param names"
    end
  end
end
