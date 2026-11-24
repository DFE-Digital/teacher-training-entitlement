require "rails_helper"

RSpec.describe Teachers::Query do
  let(:teacher) { create(:teacher, :with_one_login_id, email: "user@example.com") }
  let!(:matching_teacher) { create(:teacher, :with_one_login_id, email: "match@example.com") }

  describe "#teacher_with_matching_email" do
    subject { described_class.new(teacher:).teacher_with_matching_email }

    before { teacher.email = "match@example.com" }

    it "returns the matching teacher" do
      expect(subject).to eq matching_teacher
    end

    context "when the teacher passed is the only teacher that has that email" do
      subject { described_class.new(teacher: matching_teacher).teacher_with_matching_email }

      it "does not return the passed in teacher" do
        expect(subject).to be_nil
      end
    end
  end
end
