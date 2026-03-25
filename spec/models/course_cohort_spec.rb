require "rails_helper"

RSpec.describe CourseCohort do
  subject(:course_cohort) { create(:course_cohort) }

  describe "relationships" do
    it { is_expected.to belong_to(:course) }
    it { is_expected.to belong_to(:cohort) }
    it { is_expected.to belong_to(:schedule) }
    it { is_expected.to have_many(:course_cohort_providers).dependent(:destroy) }
    it { is_expected.to have_many(:lead_providers).through(:course_cohort_providers) }
  end

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive }
  end
end
