module Forms
  class CustomViewStepForm < CustomRegistrationStepForm
    include DfE::Wizard::Step

    def view_component(form:, registration_step:)
      clazz = registration_step.custom_view_class_name.constantize
      clazz.new(step: self, form:)
    end

    def form_param_names
      []
    end
  end
end
