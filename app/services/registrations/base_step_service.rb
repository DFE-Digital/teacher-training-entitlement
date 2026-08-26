module Registrations
  #
  # Base service class for running logic after steps
  #
  class BaseStepService
    def initialize(wizard:)
      @wizard = wizard
    end

    def call
      raise "Must be implemented"
    end

  protected

    attr_reader :wizard
  end
end
