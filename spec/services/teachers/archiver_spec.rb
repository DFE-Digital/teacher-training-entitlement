require "rails_helper"

RSpec.describe Teachers::Archiver do
  let(:teacher) { create(:teacher, :with_one_login_id, email: "test1@example.com") }
  let(:archive_time) { 2.days.ago }

  subject { described_class.new(teacher:) }

  describe ".archive!" do
    it "archives teacher" do
      expect(teacher).not_to be_archived

      travel_to archive_time do
        subject.archive!
      end

      expect(teacher.archived_email).to eq("test1@example.com")
      expect(teacher.email).to eq("archived-test1@example.com")
      expect(teacher.one_login_id).to be_nil
      expect(teacher.provider).to be_nil
      expect(teacher.archived_at.to_s).to eq(archive_time.to_s)
      expect(teacher).to be_archived
    end

    context "when already archived" do
      let(:teacher) { create(:teacher, :archived) }

      it "raises error" do
        expect(teacher).to be_archived

        expect {
          subject.archive!
        }.to raise_error ArgumentError, "Teacher already archived"
      end
    end
  end

  describe ".set_one_login_id_to_nil!" do
    let(:teacher) { create(:teacher, :archived, :with_one_login_id) }

    it "sets one_login_id to nil" do
      subject.set_one_login_id_to_nil!

      expect(teacher.one_login_id).to be_nil
    end
  end
end
