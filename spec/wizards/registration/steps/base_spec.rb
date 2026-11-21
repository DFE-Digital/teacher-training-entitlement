require "rails_helper"

RSpec.describe Registration::Steps::Base do
  Registration::Wizard::STEPS.except(:sign_in).each do |step_name, step_class|
    it "requires authentication on #{step_name}" do
      expect(step_class.requires_user).to be(true)
    end
  end

  it "does not require authentication on sign_in" do
    expect(Registration::Steps::SignIn.requires_user).to be(false)
  end
end
