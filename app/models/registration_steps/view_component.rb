module RegistrationSteps
  class ViewComponent < RegistrationStep
    def set_view_component!(component_class_name:)
      return unless view_component_class_for(component_class_name)

      config[:view_component] = { component_class_name: }

      update!(config:)
    end

    def view_component_class_for(class_name)
      klass = class_name.safe_constantize if class_name.present?

      klass if klass.is_a?(Class) && klass < Registrations::BaseCustomViewComponent
    end

    def view_component_class
      view_component_class_for(view_component_class_name)
    end

    def view_component_class_name
      config.dig("view_component", "component_class_name")
    end
  end
end
