module RegistrationSteps
  class HtmlComponent < RegistrationStep
    TYPES = ["Plain",
             "Radio buttons",
             "Checkboxes"].freeze

    def self.handles?(registration_step)
      registration_step.type.in?(TYPES)
    end

    def answers
      answer_data
    end

    def answer_data
      config.dig(type_as_param, "answers") || []
    end

    def text_data
      config.dig(type_as_param, "text") || []
    end

    def add_answer!(answer_name:, answer_value: nil, next_step_id: nil, redirect_path: nil, redirect_state_store_key: nil)
      config_for_type = config[type_as_param] ||= {}
      answers = config_for_type["answers"] ||= []
      answers << {
        "name" => answer_name,
        "value" => normalized_answer_value(name: answer_name, value: answer_value),
        "next_step_id" => next_step_id,
        "redirect" => redirect_config(
          path: redirect_path,
          state_store_key: redirect_state_store_key,
        ),
      }.compact

      update!(config:)
    end

    def set_answers!(answers:)
      config_for_type = config[type_as_param] ||= {}
      config_for_type["answers"] = answers.filter_map do |answer|
        next if answer["name"].blank?

        {
          "name" => answer["name"],
          "value" => normalized_answer_value(name: answer["name"], value: answer["value"]),
          "next_step_id" => answer["next_step_id"],
          "redirect" => redirect_config(
            path: answer.dig("redirect", "path") || answer["redirect_path"],
            state_store_key: answer.dig("redirect", "state_store_key") || answer["redirect_state_store_key"],
          ),
        }.compact
      end

      update!(config:)
    end

    def remove_answer!(index:)
      answers = config.dig(type_as_param, "answers")
      return if answers.blank?

      answers.delete_at(index.to_i)

      update!(config:)
    end

    def add_text!(text:, text_size:)
      config_for_type = config[type_as_param] ||= {}
      texts = config_for_type["text"] ||= []
      texts << { text:, text_size: }

      update!(config:)
    end

    def remove_text!(index:)
      texts = config.dig(type_as_param, "text")
      return if texts.blank?

      texts.delete_at(index.to_i)

      update!(config:)
    end

    def step_class
      return Forms::RadioButtonsStepForm if type == "Radio buttons"

      super
    end

  private

    def redirect_config(path:, state_store_key:)
      {
        "path" => path.presence,
        "state_store_key" => state_store_key.presence,
      }.compact.presence
    end

    def normalized_answer_value(name:, value:)
      value.presence || name.to_s.underscore.parameterize.underscore
    end
  end
end
