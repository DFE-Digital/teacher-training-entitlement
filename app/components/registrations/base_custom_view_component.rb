module Registrations
  class BaseCustomViewComponent < BaseComponent
    def initialize(step:, form:)
      @step = step
      @form = form
      @wizard = step.wizard
    end
  end
end
