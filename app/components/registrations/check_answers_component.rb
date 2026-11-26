module Registrations
  class CheckAnswersComponent < BaseComponent
    HIDDEN_STATE_KEYS = %w[completed completed_at _display_values].freeze

    DISPLAY_VALUES_KEY = "_display_values".freeze

    attr_reader :wizard_step

    def initialize(wizard_step:)
      @wizard_step = wizard_step
    end

    def course
      @course ||= wizard_step.wizard.journey_definition.course
    end

    def captured_values
      @captured_values ||= wizard_step.captured_values.reject do |key, value|
        value.blank? || key.to_s.in?(HIDDEN_STATE_KEYS)
      end
    end

    def captured_display_values
      values = wizard_step.captured_values
      values[DISPLAY_VALUES_KEY] || {}
    end

    def answer_rows
      @answer_rows ||= begin
        wizard = wizard_step.wizard
        answer_steps = if wizard
                         wizard.steps_processor.step_definitions.filter_map do |step_id, step_class|
                           if step_class <= Registrations::JourneyStep
                             wizard.step(step_id)
                           else
                             wizard_step.journey_definition.find_step_by_slug(step_id.to_s.dasherize)
                           end
                         end
                       else
                         wizard_step.journey_definition.step_definitions
                       end

        captured_values.filter_map do |key, value|
          step = answer_steps.find do |answer_step|
            answer_step.answer_key.to_s == key.to_s
          end

          [key, value, step] if step&.display_on_check_answers?
        end
      end
    end

    def answer_label(key:, step_definition:)
      step_definition&.answer_display_name.presence || key.to_s.humanize
    end

    def display_value(step_definition:, value:)
      case value
      when Array
        helpers.safe_join(
          value.map { |item| helpers.tag.div(step_answer_value(step_definition:, value: item)) },
        )
      when Hash
        helpers.safe_join(
          value.map { |nested_key, nested_value| helpers.tag.div("#{nested_key.to_s.humanize}: #{nested_value}") },
        )
      else
        step_answer_value(step_definition:, value:).to_s
      end
    end

    def change_path(step_definition)
      helpers.step_registration_path(wizard_step.journey_slug, step_definition.slug)
    end

  private

    def step_answer_value(step_definition:, value:)
      return value unless step_definition

      saved_display_value(step_definition:, value:) || step_definition.display_answer_value(value:)
    end

    def saved_display_value(step_definition:, value:)
      values_for_answer = captured_display_values[step_definition.answer_key.to_s] || {}
      values_for_answer[value.to_s]
    end
  end
end
