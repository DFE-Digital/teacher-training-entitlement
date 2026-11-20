module Registrations
  module Steps
    class Create
      def initialize(registration_journey:, step_class:, answers: [], previous_step_id: nil, config: {}, **attributes)
        @registration_journey = registration_journey
        @step_class = step_class
        @answers = answers
        @previous_step_id = previous_step_id
        @config = config
        @attributes = attributes
      end

      def call
        RegistrationStep.transaction do
          registration_step = @step_class.new(
            **@attributes,
            registration_journey: @registration_journey,
            previous_step_id: @previous_step_id,
            config: @config,
          )
          build_answers(registration_step)
          registration_step.save!
          registration_step
        end
      end

    private

      def build_answers(registration_step)
        @answers.each_with_index do |answer, position|
          answer = answer.to_h.deep_symbolize_keys
          next if answer[:name].blank?

          registration_step.registration_step_answers.build(
            **answer.slice(:name, :hint, :next_step_id, :redirect_path, :redirect_state_store_key, :state_store_key).compact_blank,
            value: answer[:value],
            position:,
          )
        end
      end
    end
  end
end
