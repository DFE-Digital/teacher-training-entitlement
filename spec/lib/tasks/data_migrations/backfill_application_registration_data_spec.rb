require "rails_helper"

RSpec.describe "data_migrations:backfill_application_registration_data" do
  subject(:run_task) { Rake::Task["data_migrations:backfill_application_registration_data"].invoke }

  after { Rake::Task["data_migrations:backfill_application_registration_data"].reenable }

  it "copies raw application data into registration data" do
    application = create(
      :application,
      raw_application_data: {
        "course_cohort_ecf_id" => SecureRandom.uuid,
        "funding" => "self",
      },
      registration_data: {},
    )

    run_task

    expect(application.reload.registration_data).to eq(application.raw_application_data)
  end

  it "does not overwrite existing registration data" do
    application = create(
      :application,
      raw_application_data: { "funding" => "self" },
      registration_data: { "existing" => "value" },
    )

    run_task

    expect(application.reload.registration_data).to eq("existing" => "value")
  end
end
