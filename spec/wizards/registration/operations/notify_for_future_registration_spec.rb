require "rails_helper"

RSpec.describe Registration::Operations::NotifyForFutureRegistration do
  subject(:result) { described_class.new(repository: nil, step:).execute }

  let(:user) { create(:user) }
  let(:course) { create(:course) }
  let(:state_store) { Registration::StateStore.new(repository: DfE::Wizard::Repository::InMemory.new) }
  let(:wizard) { Registration::Wizard.new(course:, current_user: user, current_step: :course_start_date, state_store:) }
  let(:step) { Registration::Steps::CourseStartDate.new(course_start_date:, wizard:) }

  context "when later is picked" do
    let(:course_start_date) { "later" }

    it "flags the user for future registration notification" do
      expect { result }.to change { user.reload.notify_user_for_future_reg }.to(true)
    end

    it { is_expected.to eq(success: true) }
  end

  context "when a start date is picked" do
    let(:course_start_date) { course.course_cohorts.first.ecf_id }

    before { user.update!(notify_user_for_future_reg: true) }

    it "clears the flag" do
      expect { result }.to change { user.reload.notify_user_for_future_reg }.to(false)
    end
  end
end
