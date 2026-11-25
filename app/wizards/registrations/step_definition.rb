module Registrations
  class StepDefinition
    FORM_CLASS_CACHE = {}
    FORM_CLASS_CACHE_MUTEX = Mutex.new

    SERVICE_EXECUTE_POINT_OPTIONS = {
      before_show: "execute service before step",
      after_update: "execute service after step",
    }.freeze

    attr_accessor :journey_definition, :previous_step_slug, :branch_join_step_slug, :requires_answer, :display_on_check_answers
    attr_reader :name, :slug, :step_class, :answer_options, :config, :state_store_key, :answer_display_name, :redirect_path, :redirect_state_store_key, :required_answer_message

    def initialize(journey_definition: nil, step_class: nil, type: nil, name: nil, slug: nil, previous_step_slug: nil,
                   branch_join_step_slug: nil, config: {}, state_store_key: nil,
                   answer_display_name: nil, redirect_path: nil, redirect_state_store_key: nil,
                   requires_answer: nil, required_answer_message: nil, display_on_check_answers: true, **)
      @journey_definition = journey_definition
      @name = name
      @slug = slug.presence || name.to_s.parameterize
      @step_class = step_class || type&.constantize || Registrations::StepDefinitions::Plain
      @previous_step_slug = previous_step_slug
      @branch_join_step_slug = branch_join_step_slug
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

    def graph_id
      slug.to_s.underscore.to_sym
    end

    def type
      step_class.name
    end

    def previous_step
      journey_definition.find_step_by_slug(previous_step_slug)
    end

    def branch_join_step
      journey_definition.find_step_by_slug(branch_join_step_slug)
    end

    def branch_decision_steps
      journey_definition.step_definitions.select { |step| step.branch_join_step_slug == slug }
    end

    def default_next_step
      conditional_next_steps = answer_options.filter_map(&:next_step)
      explicit_next_steps = journey_definition.step_definitions.select do |step|
        step.previous_step == self && !conditional_next_steps.include?(step)
      end

      if explicit_next_steps.many?
        raise ArgumentError, "Registration step #{slug} has multiple default next steps"
      end
      return explicit_next_steps.first if explicit_next_steps.any?

      find_innermost_branch&.branch_join_step
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
      point = execute_point.to_sym
      unless point.in?(SERVICE_EXECUTE_POINT_OPTIONS.keys)
        raise ArgumentError, "execute_point must be one of #{SERVICE_EXECUTE_POINT_OPTIONS.keys.join(', ')} - was given '#{execute_point}'"
      end

      services = config["services"] ||= []
      services << { "class_name" => class_name, "execute_point" => point.to_s }
    end

    def set_html_partial!(partial_name:)
      config["html_partial"] = { "partial_name" => partial_name } if partial_name.present?
    end

    def set_view_component!(component_class_name:)
      return unless valid_view_component_class?(component_class_name)

      config["view_component"] = { "component_class_name" => component_class_name }
    end

    def update!(attributes = {})
      attributes.each do |attribute, value|
        public_send("#{attribute}=", value)
      end
      self
    end

    def save!
      self
    end

    def view_component_class
      view_component_class_for(view_component_class_name)
    end

    def view_component_class_name
      config.dig("view_component", "component_class_name")
    end

    def view_component_class_for(class_name)
      klass = class_name.safe_constantize if class_name.present?
      klass if valid_view_component_class?(klass)
    end

    def valid_view_component_class?(class_name_or_class)
      klass = class_name_or_class.is_a?(Class) ? class_name_or_class : class_name_or_class&.safe_constantize
      klass.is_a?(Class) && klass < Registrations::BaseCustomViewComponent
    end

    # DfE Wizard needs a concrete form class declaring the step's state-store
    # key. Compatible steps share a cached subclass while retaining the type's
    # behavior and their declared attribute names.
    def form_class
      has_input = state_store_key.present? || requires_answer?
      input_key = answer_key.to_sym if has_input
      required_message = if requires_answer?
                           required_answer_message.presence || default_required_answer_message
                         end

      cache_key = [step_class, input_key, requires_answer?, required_message]

      FORM_CLASS_CACHE_MUTEX.synchronize do
        FORM_CLASS_CACHE[cache_key] ||= build_form_class(input_key:, required_message:)
      end
    end

    def next_step_for(answers:)
      answer_key_for_route = answer_options.find(&:has_state_store_answer_key?)&.state_store_key || answer_key
      value = answers[answer_key_for_route.to_sym]
      answer_options.find { |answer| answer.answer_matches?(answer_value: value) }&.next_step
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

    def redirect_target_for(state_store:, answer: nil)
      resolved_redirect_target(state_store:, answer:)
    end

    def display_answer_value(value:)
      if step_class <= Registrations::StepDefinitions::InstitutionChoice && value.to_s.match?(/\A\d+\z/)
        return Institution.find_by(id: value)&.name || value
      end

      answer_options.find { |answer| answer.answer_matches?(answer_value: value) }&.name || value
    end

  private

    # Walks backwards to the nearest branch whose join has not already been
    # crossed, so nested branches reach their own join first.
    def find_innermost_branch
      crossed_join_slugs = Set.new
      crossed_join_slugs.add(slug) if branch_decision_steps.any?

      branch_step = previous_step

      while branch_step
        branch_join_step = branch_step.branch_join_step
        return branch_step if branch_join_step && !crossed_join_slugs.include?(branch_join_step.slug)

        crossed_join_slugs.add(branch_step.slug) if branch_step.branch_decision_steps.any?
        branch_step = branch_step.previous_step
      end
    end

    def build_form_class(input_key:, required_message:)
      Class.new(step_class) do
        if input_key
          attribute input_key, ActiveModel::Type::Value.new
          validates input_key, presence: { message: required_message } if required_message
        end

        define_singleton_method(:permitted_params) do
          input_key ? [input_key] : []
        end
      end
    end

    def default_required_answer_message
      step_class <= Registrations::StepDefinitions::InstitutionChoice ? "Select an institution" : "Select an answer"
    end

    def state_store_value_for(state_store, key)
      state_store[key] || state_store[key.to_sym]
    end

    def required_type?
      step_class <= Registrations::StepDefinitions::RadioButtons || step_class <= Registrations::StepDefinitions::InstitutionChoice
    end
  end
end
