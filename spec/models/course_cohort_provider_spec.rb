require "rails_helper"

RSpec.describe CourseCohortProvider do
  subject(:course_cohort_provider) { create(:course_cohort_provider) }

  describe "relationships" do
    it { is_expected.to belong_to(:course_cohort) }
    it { is_expected.to belong_to(:lead_provider) }
  end

  describe "validations" do
    it { is_expected.to validate_numericality_of(:recruitment_target).only_integer.is_greater_than_or_equal_to(0).allow_nil }
  end
end
