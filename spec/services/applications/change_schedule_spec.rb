require "rails_helper"

RSpec.describe Applications::ChangeSchedule, type: :model do
  subject(:service) { described_class.new(application:, cohort: target_cohort) }

  let(:application) { create(:application, :accepted, course:, cohort:) }
  let(:course) { create(:course) }
  let(:cohort) { create(:cohort, :current, course:, training_starts_at: 1.month.from_now, training_ends_at: 6.months.from_now) }
  let(:target_course) { course }
  let(:target_cohort) { create(:cohort, :next, course: target_course, training_starts_at: 1.day.from_now, training_ends_at: 2.days.from_now) }

  describe "happy path" do
    it "updates application cohort" do
      expect { service.call }.to change(application, :cohort).from(cohort).to(target_cohort)
    end
  end

  describe "errors scenarios" do
    context "when application training has already started" do
      let(:cohort) { create(:cohort, :current, course:, training_starts_at: 1.day.ago, training_ends_at: 6.months.from_now) }
      let(:application) { create(:application, :accepted, :with_declaration, course:, cohort:) }

      it { expect { service.call }.not_to change(application, :cohort) }
    end

    context "when application missing" do
      let(:application) { nil }

      it { is_expected.to validate_presence_of(:application).with_message("The entered '#/application' is missing from your request. Check details and try again.") }
    end

    context "when target course cohort has a different course than application" do
      let(:target_course) { create(:course, name: "other course") }

      it { expect { service.call }.not_to change(application, :cohort) }
    end

    context "when target course cohort is already in training" do
      let(:target_cohort) { create(:cohort, :next, course: target_course, training_starts_at: 1.day.ago, training_ends_at: 2.days.from_now) }

      it { expect { service.call }.not_to change(application, :cohort) }
    end
  end
end
