require "rails_helper"

RSpec.describe "data_migrations:backfill_delivery_partnership_course_cohorts" do
  subject(:run_task) { Rake::Task[task_name].invoke }

  let(:task_name) { "data_migrations:backfill_delivery_partnership_course_cohorts" }
  let(:cohort) { create(:cohort) }
  let(:lead_provider) { create(:lead_provider) }
  let(:course_cohort) { create(:course_cohort, cohort:, lead_provider:) }
  let(:delivery_partnership) do
    create(:delivery_partnership, cohort:, lead_provider:, course_cohort: nil)
  end

  after { Rake::Task[task_name].reenable }

  it "links a delivery partnership to its matching course cohort" do
    course_cohort
    delivery_partnership

    expect { run_task }
      .to change { delivery_partnership.reload.course_cohort }
      .from(nil).to(course_cohort)
  end

  it "skips a delivery partnership without a matching course cohort" do
    delivery_partnership

    expect { run_task }.not_to(change { delivery_partnership.reload.course_cohort })
  end

  it "skips a delivery partnership with multiple matching course cohorts" do
    course_cohort
    create(:course_cohort, cohort:, course: create(:course), lead_provider:)
    delivery_partnership

    expect { run_task }.not_to(change { delivery_partnership.reload.course_cohort })
  end

  it "does not update records during a dry run" do
    course_cohort
    delivery_partnership

    expect { Rake::Task[task_name].invoke(true) }
      .not_to(change { delivery_partnership.reload.course_cohort })
  end
end
