module RegistrationSteps
  class CustomStep < RegistrationStep
    TYPE = "Custom step".freeze

    def self.handles?(registration_step)
      registration_step.type == TYPE
    end

    def custom_steps
      find_classes(path: "app/wizards", clazz: Forms::CustomRegistrationStepForm)
    end

    def set_custom_step!(custom_step_class_name:)
      config_for_type = config["custom_step"] ||= {}
      config_for_type["custom_step_class_name"] = custom_step_class_name if custom_step_class_name.in?(custom_steps)

      update!(config:)
    end

    def custom_step_class_name
      config.dig("custom_step", "custom_step_class_name")
    end

    def step_class
      custom_step_class || Forms::RegistrationStepForm
    end

    def stored_answer_keys
      custom_form = step_class.new
      return custom_form.form_param_names.map(&:to_sym) if custom_form.respond_to?(:form_param_names)

      super
    end

  private

    def custom_step_class
      custom_step_class_name.safe_constantize if custom_step_class_name.in?(custom_steps)
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
