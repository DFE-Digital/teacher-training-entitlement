require "rails_helper"

RSpec.describe ProviderCourseProfile, type: :model do
  subject { build(:provider_course_profile) }

  it { is_expected.to belong_to(:course) }
  it { is_expected.to belong_to(:lead_provider) }
  it { is_expected.to validate_uniqueness_of(:course_id).scoped_to(:lead_provider_id) }
end
