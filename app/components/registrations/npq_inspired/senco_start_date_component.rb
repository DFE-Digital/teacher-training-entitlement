module Registrations
  module NpqInspired
    class SencoStartDateComponent < BaseComponent
      def initialize(step:, form:, registration_step:)
        @step = step
        @form = form
        @registration_step = registration_step
      end
    end
  end
end
