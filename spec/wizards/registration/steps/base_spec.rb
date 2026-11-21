require "rails_helper"

RSpec.describe Registration::Steps::Base do
  Registration::Wizard::STEPS.each do |step_name, step_class|
    it "requires authentication on #{step_name}" do
      expect(step_class.requires_user).to be(true)
    end
  end
end
