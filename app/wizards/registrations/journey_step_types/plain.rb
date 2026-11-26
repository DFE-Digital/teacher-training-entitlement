module Registrations
  module JourneyStepTypes
    class Plain < Registrations::JourneyStep
      TYPE_AS_PARAM = "plain".freeze

      def self.permitted_params = []
    end
  end
end
