# Runs the examples against both registration journeys: the legacy one, and the
# dfe-wizard one with its feature flag on. Remove with the legacy journey.
module RegistrationJourneys
  def registration_journeys(&block)
    context("with the legacy registration journey", &block)
    context("with the dfe-wizard registration journey", :dfe_wizard_registration, &block)
  end
end

RSpec.configure do |config|
  config.extend RegistrationJourneys

  config.before(:each, :dfe_wizard_registration) do
    Flipper.enable(Feature::REGISTRATION_DFE_WIZARD)
  end
end
