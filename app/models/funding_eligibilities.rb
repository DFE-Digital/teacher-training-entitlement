# Registry of the funding eligibility rule sets a course can be linked to
# (courses.funding_eligibility holds a rule set key). Not to be confused with
# the FundingEligibility service, which computes an application's result.
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

  def self.name_for(key)
    available.find { _1.key == key }&.name
  end
end
