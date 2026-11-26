module Registrations
  module JourneyStepTypes
    class CheckAnswers < Registrations::JourneyStep
      TYPE_AS_PARAM = "check_answers".freeze

      def self.permitted_params = []
    end
  end
end
