require "rails_helper"

RSpec.describe "data_migrations:backfill_declaration_milestones" do
  subject(:run_task) { Rake::Task["data_migrations:backfill_declaration_milestones"].invoke }

  let(:course_cohort) { create(:course_cohort) }
  let(:application) { create(:application, :accepted, course_cohort:) }

  after { Rake::Task["data_migrations:backfill_declaration_milestones"].reenable }

  it "creates a milestone matching the declaration type for the declaration course cohort" do
    create_legacy_declaration(declaration_type: Milestone::STARTED)

    expect { run_task }.to change(Milestone, :count).by(1)

    expect(course_cohort.milestones.pluck(:declaration_type)).to contain_exactly(
      Milestone::STARTED,
    )
  end

  it "uses the course cohort schedule acceptance window for created milestones" do
    create_legacy_declaration(declaration_type: Milestone::STARTED)

    run_task

    expect(course_cohort.milestones).to all(
      have_attributes(
        acceptance_window_start_date: course_cohort.schedule.acceptance_window_start,
        acceptance_window_end_date: course_cohort.schedule.acceptance_window_end,
      ),
    )
  end

  it "links each declaration to the matching milestone" do
    started_declaration = create_legacy_declaration(declaration_type: Milestone::STARTED)
    completed_declaration = create_legacy_declaration(declaration_type: Milestone::COMPLETED)

    run_task

    expect(started_declaration.reload.milestone).to eq(course_cohort.milestones.find_by(declaration_type: Milestone::STARTED))
    expect(completed_declaration.reload.milestone).to eq(course_cohort.milestones.find_by(declaration_type: Milestone::COMPLETED))
  end

  it "does not replace an existing milestone link" do
    milestone = create(:milestone, :started, course_cohort:)
    declaration = create(:declaration, :started, application:, milestone:, cohort_id: course_cohort.cohort_id)

    expect { run_task }.not_to(change { declaration.reload.milestone })
  end

  it "does not change records when run as a dry run" do
    declaration = create_legacy_declaration(declaration_type: Milestone::STARTED)

    expect { Rake::Task["data_migrations:backfill_declaration_milestones"].invoke(true) }
      .not_to change(Milestone, :count)

    expect(declaration.reload.milestone).to be_nil
  end

  def create_legacy_declaration(declaration_type:)
    lead_provider = application.lead_provider
    statement = Statement.find_or_create_by!(lead_provider:, start_date: Date.current.beginning_of_month, frequency: :monthly)

    Declaration.create!(
      application:,
      cohort_id: course_cohort.cohort_id,
      declaration_date: application.schedule.training_starts_at + 1.day,
      declaration_type:,
      lead_provider:,
      statement:,
      state: :submitted,
    )
  end
end
