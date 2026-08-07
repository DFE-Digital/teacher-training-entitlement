require "rails_helper"

RSpec.describe "data_migrations:backfill_statement_data" do
  subject(:run_task) { Rake::Task["data_migrations:backfill_statement_data"].invoke }

  after { Rake::Task["data_migrations:backfill_statement_data"].reenable }

  it "backfills statement start_date and frequency" do
    statement = create(:statement)
    statement.update_columns(start_date: nil, frequency: nil, month: 3, year: 2025)

    run_task

    expect(statement.reload).to have_attributes(
      start_date: Date.new(2025, 3, 1),
      frequency: "monthly",
    )
  end

  it "backfills declaration statement_id from statement_items" do
    declaration = create(:declaration)
    statement = declaration.statement
    declaration.update_columns(statement_id: nil)
    create(:statement_item, declaration:, statement:)

    run_task

    expect(declaration.reload.statement_id).to eq(statement.id)
  end
end
