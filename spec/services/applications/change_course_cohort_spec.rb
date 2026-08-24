require "rails_helper"

RSpec.describe Applications::ChangeCourseCohort, type: :model do
  subject(:service) { described_class.new(application:, course_cohort: target_course_cohort) }

  let(:application) { create(:application, :accepted, course_cohort:) }
  let(:course_cohort) { create(:course_cohort, course:, cohort:) }
  let(:course) { create(:course) }
  let(:cohort) { create(:cohort, :current) }

  let(:target_course_cohort) do
    create(:course_cohort,
           course: target_course,
           cohort: target_cohort)
  end

  let(:target_course) { course }
  let(:target_cohort) { create(:cohort, :next) }

  describe "happy path" do
    it "updates application course_cohort" do
      expect { service.call }.to change(application, :course_cohort).from(course_cohort).to(target_course_cohort)
    end
  end

  describe "errors scenarios" do
    context "when application training has already started" do
      let(:application) { create(:application, :accepted, :with_declaration, course_cohort:) }

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
      before do
        create(:milestone, :started, course_cohort: target_course_cohort, acceptance_window_start_date: 1.day.ago, acceptance_window_end_date: 2.days.from_now)
      end

      it { expect { service.call }.not_to change(application, :course_cohort) }
    end
  end
end
