RSpec::Matchers.define :validate_param do |attribute|
  match do |record|
    record.valid?
    messages = record.errors[attribute]

    if @expected_message
      messages.include?(@expected_message)
    else
      messages.any?
    end
  end

  chain :with_message do |message|
    @expected_message = message
  end

  failure_message do |record|
    actual = record.errors[attribute]
    if @expected_message
      "expected #{record.class}##{attribute} to have error '#{@expected_message}', but got: #{actual.inspect}"
    else
      "expected #{record.class}##{attribute} to have errors, but got none"
    end
  end

  failure_message_when_negated do |record|
    "expected #{record.class}##{attribute} not to have error '#{@expected_message}', but it did"
  end

  description do
    msg = "validate :#{attribute}"
    msg += " with message '#{@expected_message}'" if @expected_message
    msg
  end
end
