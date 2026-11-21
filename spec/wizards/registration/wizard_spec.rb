require "rails_helper"

RSpec.describe Registration::Wizard do
  include DfE::Wizard::Test::RSpecMatchers

  subject(:wizard) do
    described_class.new(course:, current_user: user, current_step:, state_store:)
  end

  let(:current_step) { :course_start_date }
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let(:state_store) { Registration::StateStore.new(repository: DfE::Wizard::Repository::InMemory.new) }

  it { is_expected.to have_root_step(:course_start_date) }

  describe "branching" do
    it { is_expected.to have_next_step(:choose_your_provider).from(:course_start_date).when(course_start_date: "some-ecf-id") }
    it { is_expected.to have_next_step(:cannot_register_yet).from(:course_start_date).when(course_start_date: "later") }
    it { is_expected.to have_next_step(:share_provider).from(:choose_your_provider) }
    it { is_expected.to have_next_step(:check_answers).from(:share_provider) }
    it { is_expected.to have_next_step(:registration_submitted).from(:check_answers) }
  end

  describe "flow path" do
    let(:current_step) { :registration_submitted }

    before { state_store.write(course_start_date: "some-ecf-id") }

    it { is_expected.to have_flow_path(%i[course_start_date choose_your_provider share_provider check_answers registration_submitted]) }
  end

  describe "flow path when starting later" do
    let(:current_step) { :cannot_register_yet }

    before { state_store.write(course_start_date: "later") }

    it { is_expected.to have_flow_path(%i[course_start_date cannot_register_yet]) }
  end

  describe "previous steps" do
    it { is_expected.to have_previous_step(:course_start_date).from(:choose_your_provider) }
    it { is_expected.to have_previous_step(:choose_your_provider).from(:share_provider) }
    it { is_expected.to have_previous_step(:share_provider).from(:check_answers) }
  end

  describe "#route_strategy" do
    it { is_expected.to resolve_step(:choose_your_provider).to("/registration/#{course.identifier}/choose-your-provider") }
  end

  describe "step attribute names" do
    it "are unique across steps" do
      names = described_class::STEPS.values.flat_map { _1.attribute_names.map(&:to_s) }

      expect(names).to eq(names.uniq)
    end
  end

  describe "#first_incomplete_step" do
    context "when nothing is answered" do
      it { expect(wizard.first_incomplete_step).to eq(:course_start_date) }
    end

    context "when the start date is answered" do
      let(:cohort) { create(:cohort, :current) }
      let(:course_cohort) { create(:course_cohort, course:, cohort:) }

      before { state_store.write(course_start_date: course_cohort.ecf_id) }

      it { expect(wizard.first_incomplete_step).to eq(:choose_your_provider) }
    end

    context "when starting later" do
      before { state_store.write(course_start_date: "later") }

      it { expect(wizard.first_incomplete_step).to eq(:cannot_register_yet) }
    end
  end
end
