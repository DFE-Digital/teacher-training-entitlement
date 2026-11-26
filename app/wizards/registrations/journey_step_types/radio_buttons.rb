module Registrations
  module JourneyStepTypes
    class RadioButtons < Registrations::JourneyStep
      TYPE_AS_PARAM = "radio_buttons".freeze

      def self.permitted_params = %i[answer]

      def self.answer_options
        const_defined?(:ANSWER_OPTIONS, false) ? const_get(:ANSWER_OPTIONS) : []
      end

      def valid?(context = nil)
        valid = super(context)
        return false unless valid
        return true unless step_config[:answer_key].present? && step_config.fetch(:requires_answer, true)

        errors.add(:answer, step_config[:required_answer_message].presence || "Select an answer") if answer.blank?
        errors.empty?
      end
    end
  end
end
