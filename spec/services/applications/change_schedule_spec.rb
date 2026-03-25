require "rails_helper"

RSpec.describe Applications::ChangeSchedule, type: :model do
  subject(:service) { described_class.new(application:, course_cohort: target_course_cohort) }

  let(:application) { create(:application, :accepted, course_cohort:) }
  let(:course_cohort) { create(:course_cohort, course:, cohort:, schedule:) }
  let(:course) { create(:course) }
  let(:cohort) { create(:cohort, :current) }
  let(:schedule) { create(:schedule, training_starts_at: 1.month.from_now, training_ends_at: 6.months.from_now) }

  let(:target_course_cohort) do
    create(:course_cohort,
           course: target_course,
           cohort: target_cohort,
           schedule: target_schedule)
  end

  let(:target_course) { course }
  let(:target_cohort) { create(:cohort, :next) }
  let(:target_schedule) { create(:schedule, training_starts_at: 1.day.from_now, training_ends_at: 2.days.from_now, change_training_dates: false) }

  describe "happy path" do
    it "updates application course_cohort" do
      expect { service.call }.to change(application, :course_cohort).from(course_cohort).to(target_course_cohort)
    end
  end

  describe "errors scenarios" do
    context "when application training has already started" do
      let(:application) { create(:application, :active, :with_declaration, course_cohort:) }

      it { expect { service.call }.not_to change(application, :course_cohort) }
    end

    context "when application missing" do
      let(:application) { nil }

      it { is_expected.to validate_presence_of(:application).with_message("The entered '#/application' is missing from your request. Check details and try again.") }
    end

    context "when target course cohort has a different course than application" do
      let(:target_course) { create(:course, name: "other course") }

      it { expect { service.call }.not_to change(application, :course_cohort) }
    end

    context "when target course cohort is already in training" do
      let(:target_schedule) { build(:schedule, training_starts_at: 1.day.ago, training_ends_at: 2.days.from_now) }

      it { expect { service.call }.not_to change(application, :course_cohort) }
    end
  end
end
