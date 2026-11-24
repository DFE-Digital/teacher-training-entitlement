require "dfe/wizard/steps_processor/base"

module Registrations
  class BaseJourneyWizard
    include DfE::Wizard

    attr_reader :journey_definition, :course_definition, :current_user

    def initialize(session:, course_definition: nil, journey_definition: nil, current_step: nil, current_step_params: {}, current_user: nil)
      @course_definition = course_definition
      @journey_definition = journey_definition || JourneyDefinition.new(course_definition:)
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

      current_step.capture_display_values!
      remove_unreachable_step_values!
      true
    end

    def execute_services(execute_point:)
      wizard_step = current_step
      service_classes_for(wizard_step.service_config, execute_point).each do |service_class|
        service_class.new(wizard_step:).call
      end
    end

    def attribute_names
      journey_definition.step_definitions.filter_map { |step|
        step.answer_key.to_sym if input_step?(step)
      }.uniq
    end

    def permitted_params
      step = journey_definition.find_step_by_slug(current_step_name.to_s.dasherize)
      input_step?(step) ? [step.answer_key.to_sym] : []
    end

    def raw_step_data(step_id)
      step = journey_definition.find_step_by_slug(step_id.to_s.dasherize)
      return {} unless input_step?(step)

      state_store.read.with_indifferent_access.slice(step.answer_key).symbolize_keys
    end

    def find_step_for_attribute(attribute_name)
      step = journey_definition.step_definitions.find do |candidate|
        input_step?(candidate) && candidate.answer_key.to_s == attribute_name.to_s
      end
      step&.graph_id
    end

  protected

    def add_shared_journey(journey_class, graph:, after:, before:, **dependencies)
      journey_class.new(add_node: method(:add_node), state_store:, **dependencies).add_to_graph(
        graph:,
        after:,
        before:,
      )
    end

    def add_node(graph, name:, step_class:, answers: [], texts: [], html_partial: nil, view_component: nil, services: [], **attributes)
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
      step.set_view_component!(component_class_name: view_component) if view_component.present?
      services.each { |service_attributes| step.add_service!(**service_attributes) }

      graph.add_node step.graph_id, step_class, label: name
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
      }.map(&:constantize)
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
