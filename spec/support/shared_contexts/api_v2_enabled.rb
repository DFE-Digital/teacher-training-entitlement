RSpec.shared_context("with API V2 enabled") do
  before { Flipper.enable(Feature::API_V2_ENABLED) }
end
