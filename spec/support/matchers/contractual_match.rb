RSpec::Matchers.define :be_a_contractual_match do |expected|
  match do |actual|
    actual.attribute_names.all? do |attribute|
      attr = attribute.to_sym
      next true if attr == :course_cohort

      a_value = actual.public_send(attr)
      b_value = expected.public_send(attr)
      a_value == b_value
    end
  end
  description do |actual|
    expected_attrs = actual.attributes_from(expected)
    "be a contractual match of #{expected_attrs}"
  end
  failure_message do |actual|
    expected_attrs = actual.attributes_from(expected)
    "expected contract #{actual.attributes} to match #{expected_attrs}"
  end
end
