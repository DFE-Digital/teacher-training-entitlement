require "rails_helper"

RSpec.describe AdminService::DashboardStats do
  let(:start_time) { 7.days.ago.at_beginning_of_day }

  let(:teacher_auth_applications_created_before_start_time) { 3 }
  let(:non_teacher_auth_applications_created_before_start_time) { 4 }
  let(:applications_created_before_start_time) do
    teacher_auth_applications_created_before_start_time + non_teacher_auth_applications_created_before_start_time
  end

  let(:teacher_auth_applications_created_since_start_time) { 5 }
  let(:non_teacher_auth_applications_created_since_start_time) { 6 }
  let(:applications_created_since_start_time) do
    teacher_auth_applications_created_since_start_time + non_teacher_auth_applications_created_since_start_time
  end

  let(:applications_created_all_time) do
    applications_created_before_start_time + applications_created_since_start_time
  end
  let(:teacher_auth_applications_created_all_time) do
    teacher_auth_applications_created_before_start_time + teacher_auth_applications_created_since_start_time
  end
  let(:non_teacher_auth_applications_created_all_time) do
    non_teacher_auth_applications_created_before_start_time + non_teacher_auth_applications_created_since_start_time
  end

  before do
    create_list(
      :application,
      teacher_auth_applications_created_before_start_time,
      :with_teacher_auth_user,
      created_at: start_time - 1.day,
    )

    create_list(
      :application,
      non_teacher_auth_applications_created_before_start_time,
      :without_teacher_auth_user,
      created_at: start_time - 1.day,
    )

    create_list(
      :application,
      teacher_auth_applications_created_since_start_time,
      :with_teacher_auth_user,
      created_at: start_time + 1.day,
    )

    create_list(
      :application,
      non_teacher_auth_applications_created_since_start_time,
      :without_teacher_auth_user,
      created_at: start_time + 1.day,
    )
  end

  # Test these methods with a start_time
  # applications_created
  # teacher_auth_applications_created
  # non_teacher_auth_applications_created
  # teacher_auth_applications_created_percentage
  # non_teacher_auth_applications_created_percentage
  context "with a start_time" do
    subject { described_class.new(start_time:) }

    it "returns the correct number of applications created" do
      expect(subject.applications_created).to eq(applications_created_since_start_time)
    end

    it "returns the correct number of teacher auth applications created" do
      expect(subject.teacher_auth_applications_created).to eq(teacher_auth_applications_created_since_start_time)
    end

    it "returns the correct number of non teacher auth applications created" do
      expect(subject.non_teacher_auth_applications_created).to eq(non_teacher_auth_applications_created_since_start_time)
    end

    it "returns the correct percentage of teacher auth applications created" do
      expect(subject.teacher_auth_applications_created_percentage).to eq(
        (teacher_auth_applications_created_since_start_time / applications_created_since_start_time.to_f * 100).to_i,
      )
    end

    it "returns the correct percentage of non teacher auth applications created" do
      expect(subject.non_teacher_auth_applications_created_percentage).to eq(
        (non_teacher_auth_applications_created_since_start_time / applications_created_since_start_time.to_f * 100).to_i,
      )
    end
  end

  context "without a start_time" do
    subject { described_class.new }

    it "returns the correct number of applications created" do
      expect(subject.applications_created).to eq(applications_created_all_time)
    end

    it "returns the correct number of teacher auth applications created" do
      expect(subject.teacher_auth_applications_created).to eq(teacher_auth_applications_created_all_time)
    end

    it "returns the correct number of non teacher auth applications created" do
      expect(subject.non_teacher_auth_applications_created).to eq(non_teacher_auth_applications_created_all_time)
    end

    it "returns the correct percentage of teacher auth applications created" do
      expect(subject.teacher_auth_applications_created_percentage).to eq(
        (teacher_auth_applications_created_all_time / applications_created_all_time.to_f * 100).to_i,
      )
    end

    it "returns the correct percentage of non teacher auth applications created" do
      expect(subject.non_teacher_auth_applications_created_percentage).to eq(
        (non_teacher_auth_applications_created_all_time / applications_created_all_time.to_f * 100).to_i,
      )
    end

    # context where no applications have been created
    context "where no applications have been created" do
      let(:teacher_auth_applications_created_before_start_time) { 0 }
      let(:non_teacher_auth_applications_created_before_start_time) { 0 }
      let(:teacher_auth_applications_created_since_start_time) { 0 }
      let(:non_teacher_auth_applications_created_since_start_time) { 0 }

      it "returns 0 for applications_created" do
        expect(subject.applications_created).to eq(0)
      end

      it "returns 0 for teacher_auth_applications_created" do
        expect(subject.teacher_auth_applications_created).to eq(0)
      end

      it "returns 0 for non_teacher_auth_applications_created" do
        expect(subject.non_teacher_auth_applications_created).to eq(0)
      end

      it "returns 0 for teacher_auth_applications_created_percentage" do
        expect(subject.teacher_auth_applications_created_percentage).to be_nil
      end

      it "returns 0 for non_teacher_auth_applications_created_percentage" do
        expect(subject.non_teacher_auth_applications_created_percentage).to be_nil
      end
    end
  end
end
