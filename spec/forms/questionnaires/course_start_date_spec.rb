require "rails_helper"

RSpec.describe Questionnaires::CourseStartDate, type: :model do
  describe "#next_step" do
    subject { instance.next_step }

    before { instance.wizard = wizard }

    let(:instance) { described_class.new }
    let(:wizard) { RegistrationWizard.new(store:, request:, current_step: :course_start_date, current_user:) }
    let(:request) { nil }
    let(:store) { {} }
    let(:current_user) { create :user }

    context "when selecting no" do
      before { instance.course_start_date = "no" }

      it { is_expected.to eq :cannot_register_yet }
    end

    context "when selecting yes" do
      before { instance.course_start_date = "yes" }

      it { is_expected.to eq :choose_your_course }
    end
  end
end
