module Registration
  # The graph a funding eligibility rule set draws its steps on. It is the
  # steps processor DSL, plus the state store its branching predicates read.
  class RuleSetGraph < SimpleDelegator
    attr_reader :state_store

    def initialize(dsl, state_store:)
      super(dsl)
      @state_store = state_store
    end
  end
end
