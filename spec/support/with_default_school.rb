# frozen_string_literal: true

RSpec.shared_context "with default school", shared_context: :metadata do
  before do
    unless Institution.exists?(institution_reference_number: "100000", institutionable_type: "School")
      create(:school,
             urn: "100000",
             name: "open manchester school",
             address_1: "street 1",
             town: "manchester",
             establishment_status_code: "1",
             establishment_type_code: "1")
    end
  end
end

RSpec.configure do |config|
  config.include_context "with default school", :with_default_school
end
