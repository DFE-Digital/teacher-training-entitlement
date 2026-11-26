module Registrations
  module JourneyStepTypes
    class HtmlPartial < Registrations::JourneyStep
      TYPE_AS_PARAM = "html_partial".freeze

      def self.permitted_params = %i[answer]
    end
  end
end
