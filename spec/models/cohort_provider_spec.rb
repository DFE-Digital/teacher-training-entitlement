require "rails_helper"

RSpec.describe CohortProvider do
  subject(:cohort_provider) { build(:cohort_provider) }

  describe "relationships" do
    it { is_expected.to belong_to(:cohort) }
    it { is_expected.to belong_to(:lead_provider) }
  end

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:cohort_id).scoped_to(:lead_provider_id) }
  end
end
