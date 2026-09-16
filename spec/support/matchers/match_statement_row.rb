RSpec::Matchers.define :match_statement_row do |expected|
  match do |actual|
    @mismatches = {}
    @milestone = "milestone: #{expected[:declaration_type]}"
    expected.each do |key, expected_value|
      actual_value = actual[key]
      @mismatches[key] = { expected: expected_value, actual: actual_value } unless values_match_field?(expected_value, actual_value)
    end

    @mismatches.empty?
  end

  failure_message do
    details = @mismatches.map { |key, diff|
      <<~MSG
        row field #{key}:
          expected: #{format_field(diff[:expected])}
          actual:   #{format_field(diff[:actual])}
      MSG
    }.join("\n")

    [@milestone, details].join("\n")
  end

  def values_match_field?(expected_value, actual_value)
    if collection?(expected_value) || collection?(actual_value)
      ids(actual_value).sort == ids(expected_value).sort
    else
      actual_value == expected_value
    end
  end

  def collection?(value)
    value.is_a?(Enumerable) || value.is_a?(ActiveRecord::Relation)
  end

  def ids(value)
    return [] if value.nil?

    Array(value).map { |v| v.respond_to?(:id) ? v.id : v }
  end

  def format_field(value)
    collection?(value) ? ids(value).inspect : value.inspect
  end
end
