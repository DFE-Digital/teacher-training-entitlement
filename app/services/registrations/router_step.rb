module Registrations
  # Request-scoped form/context object for a persisted registration step.
  # It resolves the submitted or stored answer and exposes the configured
  # answer record where one exists; custom steps may use values with no answer row.
  class RouterStep
    DISPLAY_VALUES_KEY = "_display_values".freeze

    include ActiveModel::Model

    attr_reader :state_store, :current_user

    validate :validate_required_answer

    def initialize(params:, session:, current_user: nil)
      @params = params
      @current_user = current_user
      @state_store = StateStore.new(session:, key: :registrations)
      super()
    end

    def slug
      registration_step&.slug&.to_sym || :exit
    end

    def name
      registration_step&.name
    end

    def registration_journey_slug
      registration_journey.slug
    end

    def captured_values
      state_store.read
    end

    def redirect_target
      registration_step.redirect_target_for(answer: step_answer, state_store:)
    end

    def step_answer
      step_params = params[slug]
      if step_params.respond_to?(:key?) && (step_params.key?(:step_answer) || step_params.key?("step_answer"))
        return step_params[:step_answer]
      end

      answer_key = registration_step.answer_key
      if step_params.respond_to?(:key?) && (step_params.key?(answer_key) || step_params.key?(answer_key.to_s))
        return step_params[answer_key]
      end

      if params.respond_to?(:key?) && (params.key?(:step_answer) || params.key?("step_answer"))
        return params[:step_answer]
      end

      state_store[registration_step.answer_key]
    end

    def registration_journey
      @registration_journey ||= RegistrationJourney.find_by_slug(params[:journey_slug])
    end

    def registration_step
      @registration_step ||= if params[:step_slug].nil?
                               registration_journey.start_step
                             else
                               registration_journey.registration_steps.find_by_slug(params[:step_slug])
                             end
    end

    def store_answer!
      state = state_store.read.to_h.symbolize_keys
      state.delete(:step_answer)

      answer_key = registration_step.answer_key.to_sym
      clear_previous_branch_answers(state, answer_key, step_answer)
      state[answer_key] = step_answer
      store_display_values!(state:, answer_key:)

      state_store.clear
      state_store.write(state)
    end

  private

    attr_reader :params

    def validate_required_answer
      return unless registration_step&.requires_answer?
      return if selected_answer?

      error_message = registration_step.is_a?(RegistrationSteps::InstitutionChoice) ? "Select an institution" : "Select an answer"
      errors.add(:step_answer, registration_step.required_answer_message.presence || error_message)
    end

    def selected_answer?
      return step_answer.present? unless registration_step.is_a?(RegistrationSteps::Checkboxes)

      selected_values = Array(step_answer)
      registration_step.registration_step_answers.any? do |answer|
        selected_values.any? { |value| answer.answer_matches?(answer_value: value) }
      end
    end

    # Changing a branch decision removes answers from the path that was
    # previously selected, while preserving the shared join and later steps.
    def clear_previous_branch_answers(state, answer_key, answer_value)
      previous_answer = state[answer_key]
      return if previous_answer.blank? || previous_answer == answer_value

      answers_to_clear_for(registration_step:, state:)
      .each do |answer_key_to_clear|
        state.delete(answer_key_to_clear)
        delete_display_values_for(state:, answer_key: answer_key_to_clear)
      end
    end

    # Store labels separately so journey logic and application creation keep using
    # the canonical values submitted by each form.
    def store_display_values!(state:, answer_key:)
      display_values = state[DISPLAY_VALUES_KEY.to_sym] ||= {}
      display_values.delete(answer_key.to_s)

      values = Array(step_answer).each_with_object({}) do |value, labels|
        display_value = view_component_display_value_for(value:)
        labels[value.to_s] = display_value if display_value.present? && display_value.to_s != value.to_s
      end

      display_values[answer_key.to_s] = values if values.present?
      state.delete(DISPLAY_VALUES_KEY.to_sym) if display_values.empty?
    end

    def delete_display_values_for(state:, answer_key:)
      display_values = state[DISPLAY_VALUES_KEY.to_sym]
      return unless display_values

      display_values.delete(answer_key.to_s)
      display_values.delete(answer_key.to_sym)
      state.delete(DISPLAY_VALUES_KEY.to_sym) if display_values.empty?
    end

    def view_component_display_value_for(value:)
      return unless registration_step.respond_to?(:view_component_class)

      component_class = registration_step.view_component_class
      return unless component_class

      component_class.new(router_step: self, form: nil).display_value_for(value:)
    end

    # Returns answer keys on the previously selected branch so the wizard can
    # remove those values before storing a changed answer:
    #
    #     [Choice] -> [Old branch steps] -> [Join] -> [Shared steps]
    #                  clear answers       keep
    def answers_to_clear_for(registration_step:, state:)
      steps = RegistrationSteps::BranchTraversal::BranchTree.new(
        registration_journey:,
        registration_step:,
        answers: state,
      ).call

      steps.map(&:answer_key).map(&:to_sym)
    end
  end
end
