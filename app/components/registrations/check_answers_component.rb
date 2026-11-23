module Registrations
  class CheckAnswersComponent < BaseComponent
    HIDDEN_STATE_KEYS = %w[completed completed_at _display_values].freeze

    attr_reader :router_step

    def initialize(router_step:)
      @router_step = router_step
    end

    def course
      @course ||= router_step.registration_journey.course
    end

    def captured_values
      @captured_values ||= router_step.captured_values.reject do |key, value|
        value.blank? || key.to_s.in?(HIDDEN_STATE_KEYS)
      end
    end

    def captured_display_values
      values = router_step.captured_values
      values[Registrations::RouterStep::DISPLAY_VALUES_KEY] || {}
    end

    def answer_rows
      @answer_rows ||= begin
        registration_steps = router_step.registration_journey.registration_steps.to_a
        captured_values.filter_map do |key, value|
          step = registration_steps.find do |registration_step|
            registration_step.answer_key.to_sym == key.to_sym
          end

          [key, value, step] if step&.display_on_check_answers?
        end
      end
    end

    def answer_label(key:, registration_step:)
      registration_step&.answer_display_name.presence || key.to_s.humanize
    end

    def display_value(registration_step:, value:)
      case value
      when Array
        helpers.safe_join(
          value.map { |item| helpers.tag.div(step_answer_value(registration_step:, value: item)) },
        )
      when Hash
        helpers.safe_join(
          value.map { |nested_key, nested_value| helpers.tag.div("#{nested_key.to_s.humanize}: #{nested_value}") },
        )
      else
        step_answer_value(registration_step:, value:).to_s
      end
    end

    def change_path(registration_step)
      helpers.step_registration_path(router_step.registration_journey_slug, registration_step.slug)
    end

  private

    def step_answer_value(registration_step:, value:)
      return value unless registration_step

      saved_display_value(registration_step:, value:) || registration_step.display_answer_value(value:)
    end

    def saved_display_value(registration_step:, value:)
      values_for_answer = captured_display_values[registration_step.answer_key.to_s] || {}
      values_for_answer[value.to_s]
    end
  end
end
