require "rails_helper"

RSpec.describe "Registration state funded school steps" do
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let(:state_store) { Registration::StateStore.new(repository: DfE::Wizard::Repository::InMemory.new) }
  let(:wizard) { Registration::Wizard.new(course:, current_user: user, current_step: :teacher_catchment, state_store:) }

  def step(name, **attributes)
    wizard.step(name).tap { |step| step.assign_attributes(attributes) }
  end

  describe Registration::Steps::StateFundedSchool::TeacherCatchment do
    it { expect(step(:teacher_catchment)).not_to be_valid }
    it { expect(step(:teacher_catchment, teacher_catchment: "ENG")).to be_valid }
    it { expect(step(:teacher_catchment, teacher_catchment: "other")).to be_valid }
    it { expect(step(:teacher_catchment, teacher_catchment: "WLS")).not_to be_valid }

    it "saves with the dependent answers cleared" do
      expect(step(:teacher_catchment, teacher_catchment: "other").serializable_data).to eq(
        "teacher_catchment" => "other", "work_setting" => nil, "institution_id" => nil, "funding" => nil,
      )
    end

    it "keeps the dependent answers when the answer is unchanged" do
      state_store.write(teacher_catchment: "ENG", work_setting: Institution::OTHER)

      expect(step(:teacher_catchment, teacher_catchment: "ENG").serializable_data).to eq("teacher_catchment" => "ENG")
    end

    it "asks yes or no" do
      expect(step(:teacher_catchment).questions.first.options.map(&:label)).to eq(%w[Yes No])
    end
  end

  describe Registration::Steps::StateFundedSchool::WorkSetting do
    it { expect(step(:work_setting)).not_to be_valid }
    it { expect(step(:work_setting, work_setting: Institution::PRIVATE_INSTITUTION)).to be_valid }
    it { expect(step(:work_setting, work_setting: "nope")).not_to be_valid }

    it "saves with the school and funding answers cleared" do
      expect(step(:work_setting, work_setting: Institution::OTHER).serializable_data).to eq(
        "work_setting" => Institution::OTHER, "funding" => nil, "institution_id" => nil,
      )
    end

    it "keeps the school and funding answers when the answer is unchanged" do
      state_store.write(work_setting: Institution::OTHER, funding: "self")

      expect(step(:work_setting, work_setting: Institution::OTHER).serializable_data).to eq("work_setting" => Institution::OTHER)
    end

    it "offers the settings" do
      expect(step(:work_setting).options.map(&:value)).to eq([Institution::STATE_FUNDED_INSTITUTION, Institution::PRIVATE_INSTITUTION, Institution::OTHER])
    end
  end

  describe Registration::Steps::StateFundedSchool::ChooseSchool do
    let(:school) { create(:institution, name: "Hogwarts") }

    it { expect(step(:choose_school)).not_to be_valid }
    it { expect(step(:choose_school, institution_id: school.id.to_s)).to be_valid }
    it { expect(step(:choose_school, institution_id: "other")).to be_valid }
    it { expect(step(:choose_school, institution_id: "abc")).not_to be_valid }
    it { expect(step(:choose_school, institution_id: "0")).not_to be_valid }
    it { expect(step(:choose_school, institution_name: "x" * 65, institution_id: "other")).not_to be_valid }

    it "accepts a first search without a school" do
      expect(step(:choose_school, institution_name: "Hogwarts")).to be_valid
    end

    context "when a search was already made" do
      before { state_store.write(institution_name: "Nowhere at all") }

      it "requires a school" do
        expect(step(:choose_school, institution_name: "Nowhere at all")).not_to be_valid
      end

      it "shows the radio fallback only when there are results" do
        school
        question = step(:choose_school, institution_name: "Hogwarts").questions.first

        expect(question.options).to include(school.reload)
      end
    end

    it "searches the open schools by name" do
      school

      expect(step(:choose_school, institution_name: "Hogwarts").possible_institutions).to eq([school])
    end

    it "defaults the picker to the selected school" do
      expect(step(:choose_school, institution_id: school.id.to_s).questions.first.default_value).to eq(school.name_with_address)
    end
  end

  describe Registration::Steps::StateFundedSchool::PossibleFunding do
    it { expect(step(:possible_funding)).not_to be_valid }
    it { expect(step(:possible_funding, funding_amount: 200)).to be_valid }

    it "saves the funding amount and drops the funding choice" do
      expect(step(:possible_funding, funding_amount: 1).serializable_data).to eq("funding_amount" => 200, "funding" => nil)
    end
  end

  describe Registration::Steps::StateFundedSchool::IneligibleForFunding do
    subject(:step) { wizard.step(:ineligible_for_funding) }

    it { is_expected.to be_valid }

    context "when working outside England" do
      before { state_store.write(teacher_catchment: "other") }

      it { expect(step.template).to eq("ineligible_setting") }
    end

    context "when working in a private setting" do
      before { state_store.write(work_setting: Institution::PRIVATE_INSTITUTION) }

      it { expect(step.template).to eq("ineligible_setting") }
    end

    context "when the school is outside England" do
      before { state_store.write(work_setting: Institution::STATE_FUNDED_INSTITUTION, institution_id: create(:institution, :not_in_england).id.to_s) }

      it { expect(step.template).to eq("not_in_england") }
    end

    context "when previously funded" do
      before do
        create(:application, :with_funded_place, :accepted, user:, course:)
        state_store.write(work_setting: Institution::STATE_FUNDED_INSTITUTION, institution_id: create(:institution).id.to_s)
      end

      it { expect(step.template).to eq("previously_funded") }
    end

    context "when the work setting is other and previously funded" do
      before do
        create(:application, :with_funded_place, :accepted, user:, course:)
        state_store.write(work_setting: Institution::OTHER)
      end

      it { expect(step.template).to eq("ineligible_setting") }
    end

    context "when the school is funded" do
      before { state_store.write(work_setting: Institution::STATE_FUNDED_INSTITUTION, institution_id: create(:institution).id.to_s) }

      it "raises" do
        expect { step.template }.to raise_error(described_class::UnexpectedEligibilityStatusCode, /funded/)
      end
    end
  end

  describe Registration::Steps::StateFundedSchool::FundingYourCourse do
    %w[school trust self another employer].each do |funding|
      it { expect(step(:funding_your_course, funding:)).to be_valid }
    end

    it { expect(step(:funding_your_course)).not_to be_valid }
    it { expect(step(:funding_your_course, funding: "nope")).not_to be_valid }

    it "offers the four options" do
      expect(step(:funding_your_course).options.map(&:value)).to eq(%w[school trust self another])
    end
  end

  it "requires a signed in teacher on every step" do
    expect(FundingEligibilities::StateFundedSchool::STEPS.values.map(&:requires_user)).to all(be(true))
  end
end
