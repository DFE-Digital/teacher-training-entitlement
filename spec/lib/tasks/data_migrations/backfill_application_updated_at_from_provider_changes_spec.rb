require "rails_helper"

RSpec.describe "data_migrations:backfill_application_updated_at_from_provider_changes" do
  subject(:run_task) { Rake::Task[task_name].invoke }

  let(:task_name) { "data_migrations:backfill_application_updated_at_from_provider_changes" }
  let(:old_updated_at) { Time.zone.local(2026, 7, 1, 10, 0, 0) }
  let(:older_provider_updated_at) { Time.zone.local(2026, 7, 2, 9, 0, 0) }
  let(:latest_provider_updated_at) { Time.zone.local(2026, 7, 3, 12, 0, 0) }
  let(:old_provider) { create(:lead_provider) }
  let(:new_provider) { create(:lead_provider) }
  let(:application) { create(:application, lead_provider: old_provider) }

  before do
    application.update_columns(updated_at: old_updated_at)
    application.current_application_lead_provider.update_columns(updated_at: older_provider_updated_at)

    create(
      :application_lead_provider,
      :unassigned,
      application:,
      lead_provider: new_provider,
      updated_at: latest_provider_updated_at,
    )
  end

  after do
    ENV.delete("DRY_RUN")
    Rake::Task[task_name].reenable
  end

  it "prints the application id and updated_at values without updating in dry-run mode" do
    expect { run_task }
      .to output(
        a_string_including(
          "Application #{application.id}: #{old_updated_at} -> #{latest_provider_updated_at}",
          "Dry run: true",
          "Would update 1 applications",
        ),
      ).to_stdout

    expect(application.reload.updated_at).to eq(old_updated_at)
  end

  context "when DRY_RUN is false" do
    before do
      ENV["DRY_RUN"] = "false"
    end

    it "updates the application updated_at value" do
      expect { run_task }
        .to output(
          a_string_including(
            "Application #{application.id}: #{old_updated_at} -> #{latest_provider_updated_at}",
            "Dry run: false",
            "Updated 1 applications",
          ),
        ).to_stdout

      expect(application.reload.updated_at).to eq(latest_provider_updated_at)
    end
  end
end
