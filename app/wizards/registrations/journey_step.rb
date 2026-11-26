module Registrations
  # Shared runtime behavior for DfE Wizard steps backed by wizard step data.
  class JourneyStep
    include DfE::Wizard::Step

    Choice = Struct.new(:name, :value, :hint, :display_value, keyword_init: true)

    attr_accessor :answer

    delegate :state_store, :current_user, to: :wizard

    def self.answer_options
      []
    end

    def step_config
      @step_config ||= wizard.step_config(step_id).with_indifferent_access
    end

    def serializable_data
      answer_key = step_config[:answer_key]
      return super if answer_key.blank? || !respond_to?(:answer)

      super.except("answer").merge(answer_key.to_s => answer)
    end

    def name
      step_config[:name] || self.class::NAME
    end

    def slug
      step_id.to_s.dasherize
    end

    def journey_slug
      wizard.journey_definition.slug
    end

    def type_as_param
      self.class::TYPE_AS_PARAM
    end

    def text_data
      step_config[:texts] || (self.class.const_defined?(:TEXT_DATA, false) ? self.class::TEXT_DATA : [])
    end

    def partial_name
      step_config[:partial_name] || (self.class.const_defined?(:PARTIAL_NAME, false) ? self.class::PARTIAL_NAME : nil)
    end

    def html_partial?
      type_as_param == "html_partial"
    end

    def answer_field_name
      return :answer if step_config[:answer_key].present?

      self.class.attribute_names.first&.to_sym
    end

    def answer_options
      step_config[:answers] || self.class.answer_options
    end

    def answer_key
      step_config[:answer_key] || self.class.attribute_names.first&.to_sym
    end

    def answer_display_name
      step_config[:answer_display_name] || answer_key.to_s.humanize
    end

    def display_on_check_answers?
      step_config.fetch(:display_on_check_answers, true)
    end

    def display_answer_value(value:)
      answer_options.find { |option| option.value.to_s == value.to_s }&.name || value
    end

    def capture_display_values!
      options = answer_options
      selected_values = Array(answer)
      labels = options.each_with_object({}) do |option, captured|
        value = option.respond_to?(:value) ? option.value : option[:value]
        display_value = option.respond_to?(:display_value) ? option.display_value : option[:display_value]
        next unless selected_values.any? { |selected_value| selected_value.to_s == value.to_s }
        next if display_value.blank? || display_value.to_s == value.to_s

        captured[value.to_s] = display_value
      end

      state = state_store.read
      display_values = state["_display_values"] || {}
      display_values.delete(answer_key.to_s)
      display_values[answer_key.to_s] = labels if labels.present?
      state["_display_values"] = display_values if display_values.present?
      state.delete("_display_values") if display_values.empty?
      state_store.clear
      state_store.write(state)
    end

    def multiple_answers?
      step_config.fetch(:multiple_answers, false)
    end

    def service_config
      step_config[:services] || []
    end

    def redirect_target
      path = step_config[:redirect_path]
      return unless path.to_s.start_with?("/")

      path.gsub(/:(\w+)/) { state_store[Regexp.last_match(1)].to_s }
    end

    def captured_values
      data = wizard.data
      step_values = data.fetch(:steps, {}).values.reduce({}, :merge)
      step_values.merge(data.except(:steps))
    end
  end
end
