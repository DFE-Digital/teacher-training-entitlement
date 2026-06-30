# Data Imports

This guide covers all workflows for importing data into the TTE service — from
production pipelines (GIAS schools, private childcare providers) through to
seed data for review apps and test data generators for sandbox environments.

---

## GIAS Schools (daily)

Downloads school data from the Azure edubase API every day and creates or updates
`School` and `Institution` records.

### How it works

```
ImportGiasSchools.new.call
```

The service downloads `edubasealldata<YYYYMMDD>.csv` from Azure, converts it from
ISO-8859-1 to UTF-8, and processes each row:

- If the URN has no existing `School` record, it creates one (plus its `Institution`)
- If a record exists and `LastChangedDate` is newer than the stored value, it updates
- If `refresh_all: true`, it ignores `LastChangedDate` and updates everything

### Daily cron

```ruby
# app/jobs/crons/update_schools_job.rb
# Runs at 4:30 AM every day
Crons::UpdateSchoolsJob.perform
```

### Edge case: same-day changes

`LastChangedDate` is a date column only (not datetime). If a school is changed
twice in one day, the second change is missed. The school is picked up on the
next date its `LastChangedDate` changes. To force a full refresh:

```ruby
ImportGiasSchools.new(refresh_all: true).call
```

### Key files

| File                                   | Purpose                                      |
|----------------------------------------|----------------------------------------------|
| `app/services/import_gias_schools.rb`  | Core import logic, CSV parsing, API download |
| `app/jobs/crons/update_schools_job.rb` | Scheduled cron wrapper                       |

---

## Private Childcare Providers (bi-annual)

Data acquired from Ofsted twice a year via
[GOV.UK statistical data sets](https://www.gov.uk/government/statistical-data-sets/childcare-providers-and-inspections-management-information).
Creates `PrivateChildcareProvider` and `Institution` records.

### Acquiring the CSV files

1. Download from the link above. The latest release (as of early 2025) is the
   December 2024 data published January 2025.
2. Rename files:
   - `Management information - childcare providers and inspections - most recent inspections data as at 31 December 2024` → `childcare_providers.csv`
   - `Management information - childcare providers and inspections - registered childminder agencies as at 31 December 2024` → `childminder_agencies.csv`
3. Delete non-header rows so the first line is the CSV header.
4. Test import locally before committing. File format changes may require updates
   to the CSV row wrapper classes.

### Running the import

```bash
# Childcare providers
bundle exec rake 'private_childcare_providers:import[lib/private_childcare_providers/2024-12-31/childcare_providers.csv,childcare_providers]'

# Childminder agencies
bundle exec rake 'private_childcare_providers:import[lib/private_childcare_providers/2024-12-31/childminder_agencies.csv,childminder_agencies]'
```

Two parser types are available via the second argument:

| Parser                 | CSV Row Wrapper                  | Data Source                     |
|------------------------|----------------------------------|---------------------------------|
| `childcare_providers`  | `ChildcareProviderWrappedCSVRow` | Main provider data              |
| `childminder_agencies` | `ChildminderAgencyWrappedCSVRow` | Registered childminder agencies |

### Encoding

CSV files are read as `ISO-8859-1` and converted to UTF-8 with
`translate_unicode_characters` (handles the `\u0096` → `\u2013` en-dash).

### File storage

Historical snapshots are stored under `lib/private_childcare_providers/` in
date-stamped directories (e.g. `2024-12-31/`, `2025-03-31/`).

### Key files

| File                                                           | Purpose                                               |
|----------------------------------------------------------------|-------------------------------------------------------|
| `app/services/importers/import_private_childcare_providers.rb` | Core import service with both CSV row wrapper classes |
| `lib/tasks/private_childcare_providers.rake`                   | Rake task definition                                  |
| `lib/private_childcare_providers/`                             | Historical CSV snapshots                              |
| `spec/fixtures/files/`                                         | Test data                                             |

---

## Delivery Partners

Creates `DeliveryPartner` and `DeliveryPartnership` records from CSV. Supports
both import (with optional dry-run) and export.

### Import partners

```bash
# Real run
bundle exec rake 'delivery_partners:partners:import[path.csv,false]'

# Dry run (transaction is rolled back)
bundle exec rake 'delivery_partners:partners:import[path.csv]'
```

CSV columns: `ECF Id`, `Name`. Raises if any delivery partners already exist.

### Import partnerships

DeliveryPartnerships join lead providers, cohorts, and delivery partners.

```bash
bundle exec rake 'delivery_partners:partnerships:import[path.csv,false]'
```

CSV columns: `Lead Provider ECF Id`, `Cohort`, `Delivery Partner ECF Id`.

### Export

```bash
bundle exec rake 'delivery_partners:partners:export[output.csv]'
bundle exec rake 'delivery_partners:partnerships:export[output.csv]'
```

### Dry-run mode

Both import tasks accept a second argument (`dry_run`). When omitted or `true`,
the transaction is rolled back after logging the count. Pass `false` to commit.

### Key files

| File                               | Purpose                 |
|------------------------------------|-------------------------|
| `lib/tasks/delivery_partners.rake` | All import/export tasks |

---

## Seed Data (review apps only)

Seeds run via `db:seed:replant` in CI for review apps (see
`.github/actions/deploy-environment-to-aks/action.yml` line 85). Gated to
`development`, `review`, and `sandbox` environments.

### Entry point

`db/seeds.rb` guards itself:

```ruby
return unless Rails.env.in?(%w[development review sandbox])
```

It loads sequential seed files from `db/seeds/base/` in order (courses first,
then feature flags, childcare providers, schools, lead providers, users,
contracts, test data, API tokens, statements).

### Bulk inserts

Schools and private childcare providers use `insert_all` in batches of 1000 for
performance. Source CSVs are at `db/seeds/data/schools.csv` and
`db/seeds/data/private_childcare_providers.csv`.

```ruby
# From db/seeds/base/add_schools.rb
CSV.foreach(Rails.root.join("db/seeds/data/schools.csv"), headers: true)
   .each_slice(1000) do |batch|
  School.insert_all(batch.map { |row| row.to_h.slice(*School.column_names) })
  # … plus Institution records
end
```

Contracts and declarations use FactoryBot (`add_contracts.rb`,
`add_declarations.rb`).

### Key files

| File                                                   | Purpose                    |
|--------------------------------------------------------|----------------------------|
| `db/seeds.rb`                                          | Guard and loader           |
| `db/seeds/base/`                                       | 12 sequential seed modules |
| `db/seeds/data/`                                       | Bulk-insert CSV sources    |
| `.github/actions/deploy-environment-to-aks/action.yml` | CI invocation              |

---

## Test Data Generators (non-production)

All generators are gated to `development`, `review`, and `sandbox` environments.

### APITestScenariosSeeder

Creates applications in every state (pending, accepted, rejected, started,
completed, deferred, withdrawn, reassigned) for API integration testing.
Configured via `config/api_test_scenarios.yml`.

```ruby
ValidTestDataGenerators::APITestScenariosSeeder.new(
  lead_provider: lp, course_identifier: "tte-early-years"
).call
```

### ApplicationsPopulater and PendingApplicationsPopulater

Random test data generators. `PendingApplicationsPopulater` is a subclass that
creates only pending applications (no declarations).

```ruby
ValidTestDataGenerators::ApplicationsPopulater.populate(
  lead_provider: lp, cohort:, number_of_participants: 50
)
ValidTestDataGenerators::PendingApplicationsPopulater.populate(
  lead_provider: lp, cohort:, number_of_participants: 50
)
```

### StatementsPopulater

Creates monthly statements with correct states (paid, payable) for a given
lead provider and cohort.

```ruby
ValidTestDataGenerators::StatementsPopulater.populate(lead_provider: lp, cohort:)
```

### SandboxSharedData

Creates consistent, repeatable test users per lead provider from a YAML
configuration. Overrides parent `ApplicationsPopulater` behaviour.

```yaml
# db/seeds/sandbox_shared_data.yml
Provider Name:
  - name: "Test User"
    email: "test@example.com"
    trn: "1234567"
    date_of_birth: "1990-01-01"
```

### Key files

| File                                                                        | Purpose                         |
|-----------------------------------------------------------------------------|---------------------------------|
| `app/services/valid_test_data_generators/api_test_scenarios_seeder.rb`      | Full-state API test scenarios   |
| `app/services/valid_test_data_generators/applications_populater.rb`         | Random application data         |
| `app/services/valid_test_data_generators/pending_applications_populater.rb` | Pending-only subset             |
| `app/services/valid_test_data_generators/statements_populater.rb`           | Monthly statement state machine |
| `app/services/valid_test_data_generators/sandbox_shared_data.rb`            | Deterministic sandbox users     |
| `app/controllers/admin/api_test_scenarios_controller.rb`                    | Admin UI trigger                |
| `config/api_test_scenarios.yml`                                             | Scenario definitions            |
| `db/seeds/sandbox_shared_data.yml`                                          | Sandbox user definitions        |

---

## Related: Exporters

The service also exports data. The most notable exporter is:

- **`Exporters::TadDataRequest`** — generates CSV for Teacher Assessment Data (TAD)
  requests. Invoked by per-cohort rake tasks under `lib/tasks/tad_requests/`
  (spring 2022, autumn 2023, autumn 2023 npqeyl, autumn 2023 npqll, autumn 2024
  senco, spring 2025 senco).

These are separate from imports but often mentioned alongside them. See the
individual rake files for usage.

---

## Key Files Summary

| Area              | Key Files                                                                                                    |
|-------------------|--------------------------------------------------------------------------------------------------------------|
| GIAS Schools      | `app/services/import_gias_schools.rb`, `app/jobs/crons/update_schools_job.rb`                                |
| Private Childcare | `app/services/importers/import_private_childcare_providers.rb`, `lib/tasks/private_childcare_providers.rake` |
| Eligibility Lists | `config/initializers/pp50_institutions.rb`, `config/data/autumn_2025/`                                       |
| Pupil Premium     | `app/services/set_high_pupil_premiums.rb`, `config/data/high_pupil_premiums_2021_2022.csv`                   |
| Delivery Partners | `lib/tasks/delivery_partners.rake`                                                                           |
| Seed Data         | `db/seeds.rb`, `db/seeds/base/`, `db/seeds/data/`                                                            |
| Test Data         | `app/services/valid_test_data_generators/*.rb`                                                               |
| Exports           | `app/services/exporters/tad_data_request.rb`, `lib/tasks/tad_requests/`                                      |
