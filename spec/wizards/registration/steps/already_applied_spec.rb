require "rails_helper"

RSpec.describe Registration::Steps::AlreadyApplied do
  subject(:step) { wizard.step(:already_applied) }

  let(:course) { create(:course) }
  let(:course_cohort) { course.course_cohorts.first }
  let(:user) { create(:user) }
  let(:state_store) { Registration::StateStore.new(repository: DfE::Wizard::Repository::InMemory.new) }
  let(:wizard) { Registration::Wizard.new(course:, current_user: user, current_step: :already_applied, state_store:) }

  before { state_store.write(course_start_date: course_cohort.ecf_id) }

  it { is_expected.not_to be_valid }

  context "when the teacher has an application for the start date" do
    before { create(:application, user:, course_cohort:, status: :rejected) }

    it { is_expected.to be_valid }
  end
end
