# frozen_string_literal: true

require "rails_helper"

RSpec.describe ParticipantIdChange, type: :model do
  subject { build(:participant_id_change) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:teacher) }
    it { is_expected.to validate_presence_of(:from_participant_id) }
    it { is_expected.to validate_presence_of(:to_participant_id) }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF ID must be unique").allow_nil }
  end

  describe "associations" do
    it { is_expected.to belong_to(:teacher).class_name("Teacher") }
  end
end
