module Registrations
  module StepDefinitions
    class Checkboxes < HtmlComponent
      def multiple_answers?
        config.dig("checkboxes", "multiple_answers") != false
      end
    end
  end
end
