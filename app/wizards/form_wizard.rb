class FormWizard
  include DfE::Wizard

  STEP_NAMES = %i[start].freeze

  attr_reader :registration_journey, :registration_step

  def initialize(params:, session:, registration_journey:, registration_step:)
    @params = params
    @registration_journey = registration_journey
    @registration_step = registration_step

    super(current_step: registration_step&.slug&.to_sym || :exit,
          current_step_params: params,
          state_store: DefaultStore.new(
            repository: DfE::Wizard::Repository::Session.new(
              session:,
              key: "registrations_#{registration_journey.id}".to_sym,
            ),
          ))
  end

  def store_current_step_answers
    state = state_store.read.to_h.symbolize_keys
    state.delete(:step_answer)

    if registration_step.custom_step?
      state.merge!(params.require(registration_step.slug).permit(current_step.form_param_names))
    else
      answer_key = registration_step.answer_key.to_sym
      answer_value = params.dig(current_step_name, :step_answer) || params[:step_answer]
      clear_previous_branch_answers(state, answer_key, answer_value)
      state[answer_key] = answer_value
    end

    state_store.clear
    state_store.write(state)
  end

  def steps_processor
    DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: self) do |graph|
      registration_steps = @registration_journey.registration_steps.to_a

      graph.root registration_steps.first.slug.to_sym

      registration_steps.each do |registration_step|
        graph.add_node registration_step.slug.to_sym, registration_step.step_class

        next_step = registration_journey_graph.default_next_step_for(registration_step)
        graph.add_edge from: registration_step.slug.to_sym, to: next_step.slug.to_sym if next_step

        potential_transitions = potential_transitions_for(registration_step, registration_steps)
        next if potential_transitions.empty?

        graph.add_custom_branching_edge(
          from: registration_step.slug.to_sym,
          conditional: -> { branch_step_for(registration_step) },
          potential_transitions:,
        )
      end
    end
  end

  def route_strategy
    DfE::Wizard::RouteStrategy::DynamicRoutes.new(
      state_store:,
      path_builder: lambda { |step_id, _state_store, url_helpers, options|
        url_helpers.registration_path(registration_journey.slug, step_id.to_s.dasherize, **options)
      },
    )
  end

  def previous_step
    registration_journey_graph
      .previous_step_for(registration_step, state_store:)
      &.slug
      &.to_sym
  end

private

  attr_reader :params

  def clear_previous_branch_answers(state, answer_key, answer_value)
    previous_answer = state[answer_key]
    return if previous_answer.blank? || previous_answer == answer_value

    registration_journey_graph
      .branch_steps_for_answer(registration_step, previous_answer)
      .flat_map(&:stored_answer_keys)
      .each { |answer_key_to_clear| state.delete(answer_key_to_clear) }
  end

  def branch_step_for(registration_step)
    answer = state_store[registration_step.answer_key]

    registration_step.next_registration_step_for(answer:)&.slug&.to_sym
  end

  def potential_transitions_for(registration_step, registration_steps)
    return [] if registration_step.answer_data.empty?

    registration_step.answer_data.filter_map do |answer|
      next_step_id = answer["next_step_id"]
      next if next_step_id.blank?

      next_step = registration_steps.find { |step| step.id == next_step_id.to_i }
      next unless next_step

      { label: answer["name"], nodes: [next_step.slug.to_sym] }
    end
  end

  def registration_journey_graph
    @registration_journey_graph ||= RegistrationJourneyGraph.new(registration_journey)
  end
end
