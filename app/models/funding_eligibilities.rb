module FundingEligibilities
  RuleSet = Struct.new(:key, :name, keyword_init: true)

  STATE_FUNDED_SCHOOL = "state_funded_school".freeze

  RULE_SETS = [
    RuleSet.new(key: STATE_FUNDED_SCHOOL, name: "State-funded school"),
  ].freeze

  def self.available
    RULE_SETS
  end

  def self.keys
    available.map(&:key)
  end
end
