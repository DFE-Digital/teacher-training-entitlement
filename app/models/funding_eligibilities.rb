# Registry of the funding eligibility rule sets a course can be linked to
# (courses.funding_eligibility holds a rule set key). Not to be confused with
# Application#funding_eligibility, which stores the result of a rule set.
module FundingEligibilities
  class UnknownRuleSet < StandardError; end

  FUNDED_ELIGIBILITY_RESULT = :funded
  NOT_IN_ENGLAND = :not_in_england
  PREVIOUSLY_FUNDED = :previously_funded
  INELIGIBLE_SETTING = :ineligible_setting
  MARKED_INELIGIBLE_BY_POLICY = :marked_ineligible_by_policy

  STATE_FUNDED_SCHOOL = "state_funded_school".freeze

  def self.available
    @available ||= [StateFundedSchool.new].freeze
  end

  def self.keys
    available.map(&:key)
  end

  def self.name_for(key)
    available.find { _1.key == key }&.name
  end

  def self.for_course(course)
    raise ArgumentError, "course is required" if course.nil?

    available.find { _1.key == course.funding_eligibility } ||
      raise(UnknownRuleSet, "Unknown funding eligibility rule set #{course.funding_eligibility.inspect} for course #{course.name.inspect}")
  end
end
