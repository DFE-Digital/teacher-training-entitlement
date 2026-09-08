require "rails_helper"

RSpec.describe Applications::Resume, type: :model do
  subject(:service) { described_class.new(application:, course_cohort: target_course_cohort) }

  let(:application) { create(:application, :deferred, :with_declaration, course_cohort:) }
  let(:course_cohort) { create(:course_cohort, course:, cohort:) }
  let(:course) { create(:course) }
  let(:cohort) { create(:cohort, :previous) }

  let(:target_course_cohort) do
    create(:course_cohort,
           course: target_course,
           cohort: target_cohort)
  end

  let(:target_course) { course }
  let(:target_cohort) { create(:cohort, :current) }

  before do
    create(:milestone, :started, course_cohort: target_course_cohort, acceptance_window_start_date: 1.day.ago, acceptance_window_end_date: 1.day.from_now)
  end

  describe "happy path" do
    it "updates application status" do
      expect { service.call }.to change(application, :status).from(Application::DEFERRED).to(Application::STARTED)
    end

    it "updates the course_cohort" do
      expect { service.call }.to change(application, :course_cohort).from(course_cohort).to(target_course_cohort)
    end
  end

  describe "errors scenarios" do
    (Application::STATUSES - [Application::DEFERRED]).each do |status|
      context "when application is #{status}" do
        let(:application) { create(:application, status, :with_declaration, course_cohort:) }

        it { expect { service.call }.not_to change(application, :status) }
      end
    end

    context "when course cohort has a different course than application" do
      let(:target_course) { create(:course, name: "other course") }

      it { expect { service.call }.not_to change(application, :status) }
    end

    context "when course cohort has a cohort not currently in training" do
      before do
        target_course_cohort.milestones.destroy_all
        create(:milestone, :started, course_cohort: target_course_cohort, acceptance_window_start_date: 1.day.from_now, acceptance_window_end_date: 2.days.from_now)
      end

      it { expect { service.call }.not_to change(application, :status) }
    end
  end
end
