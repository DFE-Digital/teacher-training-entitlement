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

  context "when the teacher is signed in" do
    it { is_expected.to have_root_step(:course_start_date) }
  end

  context "when the teacher is signed out" do
    let(:user) { nil }
    let(:current_step) { :sign_in }

    it { is_expected.to have_root_step(:sign_in) }
    it { is_expected.to have_next_step(:course_start_date).from(:sign_in) }
    it { is_expected.to have_previous_step(:sign_in).from(:course_start_date) }
    it { expect(wizard.first_incomplete_step).to eq(:sign_in) }

    context "when a later step is asked for" do
      let(:current_step) { :choose_your_provider }

      it { is_expected.not_to be_valid_path_to_current_step }
    end
  end

  describe "branching" do
    it { is_expected.to have_next_step(:choose_your_provider).from(:course_start_date).when(course_start_date: "some-ecf-id") }
    it { is_expected.to have_next_step(:cannot_register_yet).from(:course_start_date).when(course_start_date: "later") }
    it { is_expected.to have_next_step(:teacher_catchment).from(:choose_your_provider) }
    it { is_expected.to have_next_step(:check_answers).from(:share_provider) }
    it { is_expected.to have_next_step(:registration_submitted).from(:check_answers) }
  end

  describe "flow path" do
    let(:current_step) { :registration_submitted }

    before { state_store.write(course_start_date: "some-ecf-id", teacher_catchment: "other") }

    it do
      expect(wizard).to have_flow_path(
        %i[course_start_date choose_your_provider teacher_catchment ineligible_for_funding funding_your_course share_provider check_answers registration_submitted],
      )
    end
  end

  describe "submitted page" do
    let(:current_step) { :registration_submitted }

    it { is_expected.not_to be_valid_path_to_current_step }
    it { expect(wizard.first_incomplete_step).to eq(:course_start_date) }

    context "when the answers are complete but not submitted" do
      let(:course_cohort) { course.course_cohorts.first }

      before do
        state_store.write(
          course_start_date: course_cohort.ecf_id,
          lead_provider_id: course_cohort.lead_providers.first.id,
          teacher_catchment: "other",
          funding: "self",
          can_share_choices: "1",
        )
      end

      it "stops at check answers" do
        expect(wizard.first_incomplete_step).to eq(:check_answers)
      end

      it { is_expected.not_to be_valid_path_to_current_step }
    end

    context "when the answers were cleared after submitting" do
      before { state_store.write(submitted_application_id: create(:application, user:).id) }

      it { is_expected.to be_valid_path_to_current_step }
    end
  end

  describe "flow path when starting later" do
    let(:current_step) { :cannot_register_yet }

    before { state_store.write(course_start_date: "later") }

    it { is_expected.to have_flow_path(%i[course_start_date cannot_register_yet]) }
  end

  describe "previous steps" do
    it { is_expected.to have_previous_step(:course_start_date).from(:choose_your_provider) }
    it { is_expected.to have_previous_step(:funding_your_course).from(:share_provider) }
    it { is_expected.to have_previous_step(:share_provider).from(:check_answers) }
  end

  describe "#route_strategy" do
    it { is_expected.to resolve_step(:choose_your_provider).to("/registration/#{course.identifier}/choose-your-provider") }
  end

  describe "step attribute names" do
    it "are unique across steps" do
      names = wizard.step_definitions.values.flat_map { _1.attribute_names.map(&:to_s) }

      expect(names).to eq(names.uniq)
    end
  end

  describe "state funded school steps" do
    let(:state_funded) { Institution::STATE_FUNDED_INSTITUTION }
    let(:school) { create(:institution) }

    it { is_expected.to have_next_step(:work_setting).from(:teacher_catchment).when(teacher_catchment: "ENG") }
    it { is_expected.to have_next_step(:ineligible_for_funding).from(:teacher_catchment).when(teacher_catchment: "other") }
    it { is_expected.to have_next_step(:choose_school).from(:work_setting).when(work_setting: state_funded) }
    it { is_expected.to have_next_step(:ineligible_for_funding).from(:work_setting).when(work_setting: "private_institution") }
    it { is_expected.to have_next_step(:ineligible_for_funding).from(:work_setting).when(work_setting: "other") }
    it { is_expected.to have_next_step(:possible_funding).from(:choose_school).when(work_setting: state_funded, institution_id: school.id.to_s) }
    it { is_expected.to have_next_step(:choose_school).from(:choose_school).when(work_setting: state_funded, institution_id: "other") }
    it { is_expected.to have_next_step(:share_provider).from(:possible_funding) }
    it { is_expected.to have_next_step(:funding_your_course).from(:ineligible_for_funding) }
    it { is_expected.to have_next_step(:share_provider).from(:funding_your_course) }

    context "when the school is outside England" do
      let(:school) { create(:institution, :not_in_england) }

      it { is_expected.to have_next_step(:ineligible_for_funding).from(:choose_school).when(work_setting: state_funded, institution_id: school.id.to_s) }
    end

    context "when the teacher was previously funded" do
      before { create(:application, :with_funded_place, :accepted, user:, course:) }

      it { is_expected.to have_next_step(:ineligible_for_funding).from(:choose_school).when(work_setting: state_funded, institution_id: school.id.to_s) }
    end
  end

  describe "a rule set that adds a different step" do
    include_context "with a single step funding eligibility rule set"

    let(:course) { create(:course, funding_eligibility: "single_step") }
    let(:current_step) { :favourite_colour }

    it { is_expected.to have_next_step(:favourite_colour).from(:choose_your_provider) }
    it { is_expected.to have_next_step(:share_provider).from(:favourite_colour) }
    it { expect(wizard.step_names).to include(:favourite_colour) }
    it { expect(wizard.step_names).not_to include(:teacher_catchment) }

    it "has the rule set rows in check answers" do
      state_store.write(favourite_colour: "red")

      expect(wizard.check_answers_rows.map(&:key)).to eq(["Course start", "Course", "Provider", "Favourite colour"])
    end
  end

  describe "a course with an unknown rule set" do
    before { course.update_column(:funding_eligibility, "removed") }

    it "fails loudly" do
      expect { wizard }.to raise_error(FundingEligibilities::UnknownRuleSet)
    end
  end

  describe "a rule set whose attribute names clash with the shared steps" do
    include_context "with a single step funding eligibility rule set"

    let(:course) { create(:course, funding_eligibility: "single_step") }

    before do
      stub_const("TestFundingEligibilities::ColourStep", Class.new do
        include Registration::Steps::Base

        attribute :lead_provider_id

        def self.permitted_params
          %i[lead_provider_id]
        end
      end)
    end

    it "raises a clear error" do
      expect { wizard }.to raise_error(described_class::AttributeNameClash, /lead_provider_id/)
    end
  end

  describe "authentication position" do
    let(:test_step) do
      Class.new do
        include Registration::Steps::Base

        self.requires_user = false
        attribute :colour
        validates :colour, presence: true

        def self.permitted_params
          %i[colour]
        end
      end
    end

    context "when sign_in comes after a step that needs no authentication" do
      let(:user) { nil }

      before do
        stub_const("Registration::Wizard::STEPS", described_class::STEPS.merge(colour: test_step))
        stub_const("Registration::Wizard::HEAD_STEPS", %i[colour sign_in course_start_date])
      end

      it { is_expected.to have_root_step(:colour) }
      it { is_expected.to have_next_step(:sign_in).from(:colour) }

      it "stays on the step before sign_in once it is answered" do
        state_store.write(colour: "red")

        expect(wizard.first_incomplete_step).to eq(:sign_in)
      end

      context "when the teacher has signed in" do
        let(:user) { create(:user) }

        it { is_expected.to have_next_step(:course_start_date).from(:colour) }
      end
    end

    context "when sign_in comes after a step that needs authentication" do
      before do
        stub_const("Registration::Wizard::HEAD_STEPS", %i[course_start_date sign_in])
      end

      it "raises a clear error" do
        expect { wizard }.to raise_error(described_class::AuthenticationOrderError, /course_start_date/)
      end
    end

    context "when sign_in is missing from HEAD_STEPS" do
      before do
        stub_const("Registration::Wizard::HEAD_STEPS", %i[course_start_date])
      end

      it "raises a clear error" do
        expect { wizard }.to raise_error(described_class::AuthenticationOrderError, /sign_in is missing/)
      end
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
