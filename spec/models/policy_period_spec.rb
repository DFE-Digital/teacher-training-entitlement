require "rails_helper"

RSpec.describe PolicyPeriod, type: :model do
  describe "relationships" do
    it { is_expected.to have_many(:course_cohorts) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:start_date) }
    it { is_expected.to validate_presence_of(:end_date) }
  end
end
