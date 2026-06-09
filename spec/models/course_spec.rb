require "rails_helper"

RSpec.describe Course do
  subject { build(:course) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:identifier).with_message("Identifier already exists, enter a unique one") }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF ID must be unique").allow_nil }
  end
end
