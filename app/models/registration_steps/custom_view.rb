module RegistrationSteps
  class CustomView < RegistrationStep
    TYPE = "Custom view".freeze

    def self.handles?(registration_step)
      registration_step.type == TYPE
    end

    def custom_views
      find_classes(path: "app/components", clazz: Registrations::BaseCustomViewComponent)
    end

    def set_custom_view!(custom_view_class_name:)
      config_for_type = config["custom_view"] ||= {}
      config_for_type["custom_view_class_name"] = custom_view_class_name if custom_view_class_name.in?(custom_views)

      update!(config:)
    end

    def custom_view_class_name
      config.dig("custom_view", "custom_view_class_name")
    end

    def step_class
      Forms::CustomViewStepForm
    end

  private

    def custom_view_class
      custom_view_class_name.safe_constantize if custom_view_class_name.in?(custom_views)
    end

    def find_classes(path:, clazz:)
      matches = Dir[Rails.root.join("#{path}/**/*.rb")].filter_map do |file_path|
        class_name = Pathname(file_path)
          .relative_path_from(Rails.root.join(path))
          .to_s
          .delete_suffix(".rb")
          .camelize
        match = class_name.safe_constantize

        match.name if match&.<(clazz)
      end

      matches.sort
    end
  end
end
