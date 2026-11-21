require "rails_helper"

RSpec.describe Registration::CheckAnswersPresenter do
  subject(:presenter) { described_class.new(wizard) }

  let(:course) { create(:course) }
  let(:course_cohort) { course.course_cohorts.first }
  let(:provider) { course_cohort.lead_providers.first }
  let(:state_store) { Registration::StateStore.new(repository: DfE::Wizard::Repository::InMemory.new) }
  let(:wizard) { Registration::Wizard.new(course:, current_user: create(:user), current_step: :check_answers, state_store:) }
  let(:school) { create(:institution) }

  def rows
    presenter.call.to_h { [_1.key, [_1.value, _1.change_step]] }
  end

  before do
    state_store.write(course_start_date: course_cohort.ecf_id, lead_provider_id: provider.id.to_s, teacher_catchment: "ENG")
  end

  it "starts with the shared rows" do
    expect(rows.first(3)).to eq(
      [
        ["Course", [course.name, nil]],
        ["Course start", [course_cohort.name, :course_start_date]],
        ["Provider", [provider.name, :choose_your_provider]],
      ],
    )
  end

  it "always asks about the workplace in England" do
    expect(rows["Workplace in England"]).to eq(["Yes", :teacher_catchment])
  end

  it "says No for a workplace outside England" do
    state_store.write(teacher_catchment: "other")

    expect(rows["Workplace in England"]).to eq(["No", :teacher_catchment])
  end

  it "has no work setting, workplace or funding rows until answered" do
    expect(rows.keys).to eq(["Course", "Course start", "Provider", "Workplace in England"])
  end

  it "adds the rows of the rule set for each answer" do
    state_store.write(work_setting: Institution::STATE_FUNDED_INSTITUTION, institution_id: school.id.to_s, funding: "trust")

    expect(rows.except("Course", "Course start", "Provider", "Workplace in England")).to eq(
      "Work setting" => ["State-funded nursery, pre-school, school or academy trust", :work_setting],
      "Workplace" => [school.name_with_address, :choose_school],
      "Course funding" => ["My trust is paying", :funding_your_course],
    )
  end
end
