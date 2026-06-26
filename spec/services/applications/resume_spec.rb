require "rails_helper"

RSpec.describe Applications::Resume, type: :model do
  subject(:service) { described_class.new(application:, cohort: target_cohort) }

  let(:application) { create(:application, :deferred, :with_declaration, course:, cohort:) }
  let(:course) { create(:course) }
  let(:cohort) { create(:cohort, :previous, course:, training_starts_at: 1.year.ago, training_ends_at: 6.months.ago) }
  let(:target_course) { course }
  let(:target_cohort) { create(:cohort, :current, course: target_course, training_starts_at: 1.day.ago, training_ends_at: 1.day.from_now) }

  describe "happy path" do
    it "updates application status" do
      expect { service.call }.to change(application, :status).from(Application::DEFERRED).to(Application::STARTED)
    end

    it "updates the cohort" do
      expect { service.call }.to change(application, :cohort).from(cohort).to(target_cohort)
    end
  end

  describe "errors scenarios" do
    (Application::STATUSES - [Application::DEFERRED]).each do |status|
      context "when application is #{status}" do
        let(:application) { create(:application, status, :with_declaration, course:, cohort:) }

        it { expect { service.call }.not_to change(application, :status) }
      end
    end

    context "when course cohort has a different course than application" do
      let(:target_course) { create(:course, name: "other course") }

      it { expect { service.call }.not_to change(application, :status) }
    end

    context "when course cohort has a cohort not currently in training" do
      let(:target_cohort) { create(:cohort, :current, course: target_course, training_starts_at: 1.day.from_now, training_ends_at: 2.days.from_now) }

      it { expect { service.call }.not_to change(application, :status) }
    end
  end
end
