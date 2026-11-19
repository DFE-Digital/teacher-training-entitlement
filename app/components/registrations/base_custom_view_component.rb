module Registrations
  class BaseCustomViewComponent < BaseComponent
    def initialize(router_step:, form:)
      @router_step = router_step
      @form = form
    end

    # Components with dynamic answers expose their submitted value and the
    # human-readable label together, so the label can be saved with the answer.
    # For example: [{ value: "cohort-123", display_value: "December 2026" }].
    # If you're happy with the normal value then leave this as is
    def answer_options
      []
    end

    # Optional display-label lookup for a submitted choice. Returns the original
    # value when no matching option is found.
    def display_value_for(value:)
      answer_options
        .find { |option| option[:value].to_s == value.to_s }
        &.fetch(:display_value) || value
    end
  end
end
