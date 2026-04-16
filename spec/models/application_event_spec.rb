require "rails_helper"

RSpec.describe ApplicationEvent do
  it { is_expected.to belong_to(:application) }
  it { is_expected.to belong_to(:lead_provider).optional }
  it { is_expected.to validate_presence_of(:event) }
end
