require "rails_helper"

RSpec.describe Registration::Steps::CourseStartDate do
  subject(:step) { wizard.step(:course_start_date) }

  let(:course) { create(:course) }
  let(:state_store) { Registration::StateStore.new(repository: DfE::Wizard::Repository::InMemory.new) }
  let(:wizard) { Registration::Wizard.new(course:, current_user: create(:user), current_step: :course_start_date, state_store:) }
  let(:course_cohort) { course.course_cohorts.first }

  describe "validations" do
    it "is invalid when blank" do
      expect(step).not_to be_valid
    end

    it "explains what to do when blank" do
      step.valid?

      expect(step.errors[:course_start_date]).to include("Choose your course start date.")
    end

    it "explains what to do when the date is not open" do
      state_store.write(course_start_date: "nope")
      invalid_step = wizard.step(:course_start_date)
      invalid_step.valid?

      expect(invalid_step.errors[:course_start_date]).to include("Choose a valid course start date.")
    end

    it "is valid for an open start date of the course" do
      state_store.write(course_start_date: course_cohort.ecf_id)

      expect(wizard.step(:course_start_date)).to be_valid
    end

    it "is valid for later" do
      state_store.write(course_start_date: "later")

      expect(wizard.step(:course_start_date)).to be_valid
    end

    it "is invalid for a start date of another course" do
      other = create(:course_cohort, course: create(:course), cohort: create(:cohort, :next, registration_starts_at: 1.day.ago.to_date))
      state_store.write(course_start_date: other.ecf_id)

      expect(wizard.step(:course_start_date)).not_to be_valid
    end
  end

  describe "#options" do
    it "lists the open start dates of the selected course, then later" do
      expect(step.options.map(&:value)).to eq([course_cohort.ecf_id, "later"])
    end

    it "does not list start dates of other courses" do
      other = create(:course_cohort, course: create(:course), cohort: create(:cohort, :current, registration_starts_at: 2.days.ago.to_date))

      expect(step.options.map(&:value)).not_to include(other.ecf_id)
    end

    it "does not list cohorts that are closed for registration" do
      closed = create(:course_cohort, course:, cohort: create(:cohort, :previous))

      expect(step.options.map(&:value)).not_to include(closed.ecf_id)
    end

    it "is shown with a single open start date" do
      expect(step.options.size).to eq(2)
    end

    context "when the start date is in the past" do
      before { course_cohort.update!(training_starts_at: 1.week.ago.to_date) }

      it "has a hint saying the course has already started" do
        expect(step.options.first.hint).to eq("This course has already started.")
      end
    end

    context "when the start date is in the future" do
      before { course_cohort.update!(training_starts_at: 1.week.from_now.to_date) }

      it "has no hint" do
        expect(step.options.first.hint).to be_nil
      end
    end
  end
end
