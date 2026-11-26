module Registrations
  class AnswerOption
    attr_reader :step_definition, :name, :value, :hint, :next_step_slug, :state_store_key,
                :redirect_path, :redirect_state_store_key, :position

    def initialize(step_definition:, name:, value: nil, hint: nil, next_step_slug: nil,
                   next_step: nil, state_store_key: nil, redirect_path: nil,
                   redirect_state_store_key: nil, position: nil, **)
      @step_definition = step_definition
      @name = name
      @value = value
      @hint = hint
      @next_step_slug = next_step&.slug || next_step_slug
      @state_store_key = state_store_key
      @redirect_path = redirect_path
      @redirect_state_store_key = redirect_state_store_key
      @position = position
    end

    def next_step
      step_definition.journey_definition.find_step_by_slug(next_step_slug)
    end

    def next_step=(step)
      @next_step_slug = step&.slug
    end

    def answer_matches?(answer_value:)
      Array(answer_value).map(&:to_s).include?(value.to_s)
    end

    def has_state_store_answer_key?
      state_store_key.present?
    end

    def resolved_redirect_target(state_store:)
      state_store_value = if redirect_state_store_key.present?
                            state_store[redirect_state_store_key] || state_store[redirect_state_store_key.to_sym]
                          end
      target = redirect_path.presence || state_store_value
      target = target.gsub(/:\w+/, state_store_value.to_s) if redirect_path.present? && state_store_value.present?
      target if target.to_s.start_with?("/")
    end
  end
end
