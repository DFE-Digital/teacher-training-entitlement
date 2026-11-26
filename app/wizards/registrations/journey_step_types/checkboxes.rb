module Registrations
  module JourneyStepTypes
    class Checkboxes < Registrations::JourneyStep
      TYPE_AS_PARAM = "checkboxes".freeze

      attr_accessor :answer

      def self.permitted_params = %i[answer]

      def self.answer_options
        const_defined?(:ANSWER_OPTIONS, false) ? const_get(:ANSWER_OPTIONS) : []
      end

      def multiple_answers?
        return step_config[:multiple_answers] unless step_config[:multiple_answers].nil?

        !self.class.const_defined?(:MULTIPLE_ANSWERS, false) || self.class::MULTIPLE_ANSWERS
      end

      def valid?(context = nil)
        valid = super(context)
        return false unless valid
        return true unless step_config[:answer_key].present? && step_config[:requires_answer]

        errors.add(:answer, step_config[:required_answer_message].presence || "Select an answer") if answer.blank?
        errors.empty?
      end
    end
  end
end
