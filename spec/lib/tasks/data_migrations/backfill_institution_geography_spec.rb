require "rails_helper"

RSpec.describe "data_migrations:backfill_institution_geography" do
  subject(:run_task) { Rake::Task["data_migrations:backfill_institution_geography"].invoke(dry_run) }

  let(:dry_run) { "false" }

  after { Rake::Task["data_migrations:backfill_institution_geography"].reenable }

  it "backfills geography for each institution type" do
    school = create(:school).institution
    welsh_school = create(:school, :in_wales).institution
    overseas_school = create(:school, establishment_type_code: "1", la_code: "704").institution
    private_provider = create(:private_childcare_provider).institution
    local_authority = create(:local_authority).institution

    Institution.update_all(alpha3_country_code: nil, subdivision_code: nil)
    overseas_school.update_columns(alpha3_country_code: "GBR", subdivision_code: "ENG")
    expect(Institution).to receive(:transaction).once.and_call_original

    run_task

    expect(school.reload).to have_attributes(alpha3_country_code: "GBR", subdivision_code: "ENG")
    expect(welsh_school.reload).to have_attributes(alpha3_country_code: "GBR", subdivision_code: "WLS")
    expect(overseas_school.reload).to have_attributes(alpha3_country_code: nil, subdivision_code: nil)
    expect(private_provider.reload).to have_attributes(alpha3_country_code: "GBR", subdivision_code: "ENG")
    expect(local_authority.reload).to have_attributes(alpha3_country_code: "GBR", subdivision_code: "ENG")
  end
end
