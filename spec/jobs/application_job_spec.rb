require "rails_helper"

RSpec.describe ApplicationJob, type: :job do
  let :simple_job do
    Class.new(ApplicationJob) do
      def self.name
        "SimpleJob"
      end

      def perform
        teacher = Teacher.first
        teacher.email = "#{Time.zone.now.to_i}@example.com"
        teacher.save!
      end
    end
  end

  describe "PaperTrail whodunnit in jobs", :versioning do
    before do
      create(:teacher)
      simple_job.perform_now
    end

    it "sets whodunnit to the job class name" do
      expect(PaperTrail::Version.last.whodunnit).to eq("Background job: SimpleJob")
    end
  end
end
