require "dfe/wizard/steps_processor/base"

module Registrations
  class BaseJourneyWizard
    include DfE::Wizard
    extend StepConfiguration

    attr_reader :journey_definition, :course, :current_user

    def initialize(session:, course: nil, journey_definition: nil, current_step: nil, current_step_params: {}, current_user: nil)
      @course = course || journey_definition&.course
      @journey_definition = journey_definition || JourneyDefinition.new(course:)
      @current_user = current_user
      repository = DfE::Wizard::Repository::Session.new(session:, key: :registrations)
      super(
        state_store: JourneyStateStore.new(repository:),
        current_step: current_step&.to_s&.underscore&.to_sym,
        current_step_params:,
      )
    end

    def route_strategy
      DfE::Wizard::RouteStrategy::DynamicRoutes.new(
        state_store:,
        path_builder: ->(step_id, _state, _helpers, _options) { "/registrations/#{journey_definition.slug}/#{step_id.to_s.dasherize}" },
      )
    end

    def save_current_step
      return false unless super

      current_step.capture_display_values! if current_step.respond_to?(:capture_display_values!)
      remove_unreachable_step_values!
      true
    end

    def execute_services(execute_point:)
      wizard_step = current_step
      case execute_point.to_sym
      when :before_show
        wizard_step.before_show if wizard_step.respond_to?(:before_show)
      when :after_update
        wizard_step.after_update if wizard_step.respond_to?(:after_update)
      end
      return unless wizard_step.respond_to?(:service_config)

      service_classes_for(wizard_step.service_config, execute_point).each do |service_class|
        service_class.new(wizard_step:).call
      end
    end

    def attribute_names
      definition_attributes = journey_definition.step_definitions.filter_map do |step|
        step.answer_key.to_sym if input_step?(step)
      end
      direct_step_attributes = steps_processor.step_definitions.flat_map do |step_id, step_class|
        next [] unless step_class <= Registrations::JourneyStep

        configured_key = step_config(step_id).with_indifferent_access[:answer_key]
        configured_key.present? ? [configured_key.to_sym] : step_class.attribute_names.map(&:to_sym)
      end

      (definition_attributes + direct_step_attributes).uniq
    end

    def permitted_params
      step_class = find_step(current_step_name)
      return step_class.permitted_params if step_class <= Registrations::JourneyStep

      step = journey_definition.find_step_by_slug(current_step_name.to_s.dasherize)
      input_step?(step) ? [step.answer_key.to_sym] : []
    end

    def raw_step_data(step_id)
      step_class = find_step(step_id)
      if step_class <= Registrations::JourneyStep
        configured_key = step_config(step_id).with_indifferent_access[:answer_key]
        if configured_key.present?
          value = state_store.read[configured_key]
          return value.nil? ? {} : { answer: value }
        end

        return state_store.read.with_indifferent_access.slice(*step_class.attribute_names).symbolize_keys
      end

      step = journey_definition.find_step_by_slug(step_id.to_s.dasherize)
      return {} unless input_step?(step)

      state_store.read.with_indifferent_access.slice(step.answer_key).symbolize_keys
    end

    def find_step_for_attribute(attribute_name)
      step = journey_definition.step_definitions.find do |candidate|
        input_step?(candidate) && candidate.answer_key.to_s == attribute_name.to_s
      end
      return step.slug.underscore.to_sym if step

      steps_processor.step_definitions.find { |step_id, step_class|
        next false unless step_class <= Registrations::JourneyStep

        configured_key = step_config(step_id).with_indifferent_access[:answer_key]
        step_attributes = configured_key.present? ? [configured_key.to_s] : step_class.attribute_names.map(&:to_s)
        step_attributes.include?(attribute_name.to_s)
      }&.first
    end

    def step_config(step_id)
      @resolved_step_configurations ||= {}
      @resolved_step_configurations[step_id.to_sym] ||= self.class.step_configurations.fetch(step_id.to_sym, {}).transform_values do |value|
        value.respond_to?(:call) ? value.call(self) : value
      end
    end

  protected

    def add_shared_wizard(shared_wizard)
      self.class.configure_steps(shared_wizard.step_configurations) if shared_wizard.respond_to?(:step_configurations)
      shared_wizard.add_to_graph
    end

    def add_node(graph, name:, step_class:, answers: [], texts: [], html_partial: nil, services: [], **attributes)
      step = StepDefinition.new(
        journey_definition:,
        name:,
        step_class:,
        **attributes,
      )

      journey_definition.add_step(step)
      step.set_answer_options!(answers:) if answers.present?
      texts.each { |text_attributes| step.add_text!(**text_attributes) }
      step.set_html_partial!(partial_name: html_partial) if html_partial.present?
      services.each { |service_attributes| step.add_service!(**service_attributes) }

      graph.add_node step.slug.underscore.to_sym, step_class, label: name
      step
    end

  private

    def input_step?(step)
      step && (step.state_store_key.present? || step.requires_answer?)
    end

    def service_classes_for(service_config, execute_point)
      service_config.filter_map { |service|
        next unless service.fetch("execute_point", service[:execute_point]).to_s == execute_point.to_s

        service.fetch("class_name", service[:class_name])
      }.map do |service_class|
        service_class = service_class.call(self) if service_class.respond_to?(:call)
        service_class.is_a?(Class) ? service_class : service_class.constantize
      end
    end

    def remove_unreachable_step_values!
      all_keys = attribute_names.map(&:to_s)
      reachable_keys = data.fetch(:steps, {}).values.flat_map(&:keys).map(&:to_s)
      unreachable_keys = all_keys - reachable_keys
      return if unreachable_keys.empty?

      state = state_store.read
      state.except!(*unreachable_keys)

      display_values = state["_display_values"]
      if display_values
        display_values.except!(*unreachable_keys)
        state.delete("_display_values") if display_values.empty?
      end

      state_store.clear
      state_store.write(state)
    end
  end
end
