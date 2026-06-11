require "rails_helper"

RSpec.describe Applications::Resume, type: :model do
  subject(:service) { described_class.new(application:, course_cohort: target_course_cohort) }

  let(:application) { create(:application, :deferred, :with_declaration, course_cohort:) }
  let(:course_cohort) { create(:course_cohort, course:, cohort:, schedule:) }
  let(:course) { create(:course) }
  let(:cohort) { create(:cohort, :previous) }
  let(:schedule) { create(:schedule, training_starts_at: 1.year.ago, training_ends_at: 6.months.ago) }

  let(:target_course_cohort) do
    create(:course_cohort,
           course: target_course,
           cohort: target_cohort,
           schedule: target_schedule)
  end

  let(:target_course) { course }
  let(:target_cohort) { create(:cohort, :current) }
  let(:target_schedule) { create(:schedule, training_starts_at: 1.day.ago, training_ends_at: 1.day.from_now) }

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
      let(:target_schedule) { build(:schedule, training_starts_at: 1.day.from_now, training_ends_at: 2.days.from_now) }

      it { expect { service.call }.not_to change(application, :status) }
    end
  end
end
