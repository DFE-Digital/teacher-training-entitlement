module Registrations
  class StepDefinition
    attr_accessor :journey_definition
    attr_reader :name, :slug, :step_class, :answer_options, :config, :state_store_key, :answer_display_name,
                :redirect_path, :redirect_state_store_key, :required_answer_message, :requires_answer,
                :display_on_check_answers

    def initialize(journey_definition: nil, step_class: nil, name: nil, slug: nil, config: {}, state_store_key: nil,
                   answer_display_name: nil, redirect_path: nil, redirect_state_store_key: nil,
                   requires_answer: nil, required_answer_message: nil, display_on_check_answers: true)
      @journey_definition = journey_definition
      @name = name
      @slug = slug.presence || name.to_s.parameterize
      @step_class = step_class || Registrations::StepDefinitions::Plain
      @config = config.with_indifferent_access
      @state_store_key = state_store_key
      @answer_display_name = answer_display_name.presence || answer_key.to_s.humanize
      @redirect_path = redirect_path
      @redirect_state_store_key = redirect_state_store_key
      @requires_answer = requires_answer.nil? ? required_type? : requires_answer
      @required_answer_message = required_answer_message
      @display_on_check_answers = display_on_check_answers
      @answer_options = []
    end

    def answer_key
      state_store_key.presence || name.to_s.underscore.parameterize.underscore
    end

    def type_as_param
      return "choose_institution" if step_class <= Registrations::StepDefinitions::InstitutionChoice

      step_class.name.demodulize.underscore
    end

    def text_data
      config.dig(type_as_param, "text") || []
    end

    def partial_name
      config.dig("html_partial", "partial_name")
    end

    def multiple_answers?
      config.dig("checkboxes", "multiple_answers") != false
    end

    def requires_answer?
      !!requires_answer
    end

    def display_on_check_answers?
      !!display_on_check_answers
    end

    def add_text!(text: nil, text_class: nil)
      config[type_as_param] ||= {}
      type_config = config[type_as_param]
      texts = type_config["text"] ||= []
      texts << { "text" => Array(text), "text_class" => text_class }.compact
    end

    def set_answer_options!(answers:)
      @answer_options = answers.each_with_index.filter_map do |answer, position|
        attributes = answer.to_h.deep_symbolize_keys
        next if attributes[:name].blank?

        AnswerOption.new(step_definition: self, **attributes, position:)
      end
    end

    def add_service!(class_name:, execute_point:)
      services = config["services"] ||= []
      services << { "class_name" => class_name, "execute_point" => execute_point.to_s }
    end

    def set_html_partial!(partial_name:)
      config["html_partial"] = { "partial_name" => partial_name } if partial_name.present?
    end

    def resolved_redirect_target(state_store:, answer: nil)
      answer_redirect = answer_options.find { |configured_answer|
        configured_answer.redirect_path.present? && configured_answer.answer_matches?(answer_value: answer)
      }&.resolved_redirect_target(state_store:)

      return answer_redirect if answer_redirect

      state_store_value = if redirect_state_store_key.present?
                            state_store_value_for(state_store, redirect_state_store_key)
                          end
      target = redirect_path.presence || state_store_value
      target = target.gsub(/:\w+/, state_store_value.to_s) if redirect_path.present? && state_store_value.present?
      target if target.to_s.start_with?("/")
    end

    def display_answer_value(value:)
      if step_class <= Registrations::StepDefinitions::InstitutionChoice && value.to_s.match?(/\A\d+\z/)
        return Institution.find_by(id: value)&.name || value
      end

      answer_options.find { |answer| answer.answer_matches?(answer_value: value) }&.name || value
    end

  private

    def state_store_value_for(state_store, key)
      state_store[key] || state_store[key.to_sym]
    end

    def required_type?
      step_class <= Registrations::StepDefinitions::RadioButtons || step_class <= Registrations::StepDefinitions::InstitutionChoice
    end
  end
end
