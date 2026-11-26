module Registrations
  class CheckAnswersComponent < BaseComponent
    HIDDEN_STATE_KEYS = %w[completed completed_at _display_values].freeze
    DISPLAY_VALUES_KEY = "_display_values".freeze

    attr_reader :wizard_step

    def initialize(wizard_step:)
      @wizard_step = wizard_step
    end

    def course
      wizard_step.wizard.course
    end

    def captured_values
      @captured_values ||= begin
        data = wizard_step.wizard.data
        data.fetch(:steps, {}).values.reduce({}, :merge).merge(data.except(:steps)).with_indifferent_access.reject do |key, value|
          value.blank? || key.to_s.in?(HIDDEN_STATE_KEYS)
        end
      end
    end

    def captured_display_values
      wizard_step.wizard.data.with_indifferent_access[DISPLAY_VALUES_KEY] || {}
    end

    def answer_rows
      @answer_rows ||= captured_values.filter_map do |key, value|
        step_id, _step_class = wizard_step.wizard.steps_processor.step_definitions.find do |_id, klass|
          klass.attribute_names.map(&:to_s).include?(key.to_s)
        end
        next unless step_id

        step = wizard_step.wizard.step(step_id)
        next if step.class.const_defined?(:DISPLAY_ON_CHECK_ANSWERS, false) && !step.class::DISPLAY_ON_CHECK_ANSWERS

        [key, value, step]
      end
    end

    def answer_label(key:, step_definition:)
      step_class = step_definition.class
      if step_class.const_defined?(:ANSWER_DISPLAY_NAME, false)
        step_class::ANSWER_DISPLAY_NAME
      else
        key.to_s.humanize
      end
    end

    def display_value(step_definition:, value:)
      case value
      when Array
        helpers.safe_join(value.map { |item| helpers.tag.div(step_answer_value(step_definition:, value: item)) })
      when Hash
        helpers.safe_join(value.map { |nested_key, nested_value| helpers.tag.div("#{nested_key.to_s.humanize}: #{nested_value}") })
      else
        step_answer_value(step_definition:, value:).to_s
      end
    end

    def change_path(step_definition)
      helpers.step_registration_path(wizard_step.wizard.journey_slug, step_definition.step_id.to_s.dasherize)
    end

  private

    def step_answer_value(step_definition:, value:)
      return value unless step_definition

      saved_display_value(step_definition:, value:) ||
        (step_definition.display_answer_value(value:) if step_definition.respond_to?(:display_answer_value)) ||
        option_display_value(step_definition:, value:) || value
    end

    def saved_display_value(step_definition:, value:)
      answer_key = step_definition.class::ATTRIBUTE.to_s
      values_for_answer = captured_display_values[answer_key] || {}
      values_for_answer[value.to_s]
    end

    def option_display_value(step_definition:, value:)
      return unless step_definition.class.respond_to?(:answer_options)

      option = step_definition.class.answer_options.find { |answer| answer[:value].to_s == value.to_s }
      option&.fetch(:name)
    end
  end
end
