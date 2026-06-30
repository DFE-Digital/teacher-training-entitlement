[< Back to docs](../README.md) · [Development overview](./overview.md)

# Local setup

Four ways to run the service locally, in order of ease.

---

## Prerequisites

Versions are pinned in [`.tool-versions`](../../.tool-versions):

- **Ruby** 3.4.9
- **Node.js** 24.13.0
- **Yarn** 1.22.22
- **PostgreSQL** 14
- **Graphviz** (latest) — for Rails diagram generation
- **Terraform** 1.14.5 — only if working on infrastructure
- **kubectl** 1.29.0 — only if working on infrastructure

See [Azure access](../connecting-to-azure.md) for infra setup.

---

## Method 1 — Docker Compose (easiest)

Only Docker required.

```bash
docker compose up -d
# Open http://localhost:3000
```

The stack:

| Service  | Role                                 | Port |
|----------|--------------------------------------|------|
| `db`     | PostgreSQL 14 (postgres/postgres)    | 5432 |
| `web`    | Rails + webpack + Sass via `bin/dev` | 3000 |
| `worker` | Delayed Job                          | —    |
| `ops`    | Azure CLI + kubectl + Terraform      | —    |

Edit code on the host — the project directory is mounted as a volume.

Prefix commands with `docker compose run web`:

```bash
docker compose run web bundle exec rails c
docker compose run web bundle exec rails db:migrate
docker compose run web bundle exec rspec
```

Rebuild with `--build` when `Gemfile.lock` changes:

```bash
docker compose up -d --build
```

Parallel tests need an explicit `RAILS_ENV`:

```bash
docker compose run -e RAILS_ENV=test web bundle exec rake parallel:spec
```

The `ops` service is scaled to 0 by default. Start it manually for `az`,
`kubectl`, or konduit tasks (see [Azure access](../connecting-to-azure.md)):

```bash
docker compose run ops
```

### Konduit from ops

Edit `konduit.sh` after installing:

1. `open_tunnels()` — add `--address 0.0.0.0` to the `kubectl port-forward` call
2. `set_db_psql()` — replace `127.0.0.1:${LOCAL_PORT}` with `konduit:${LOCAL_PORT}`

Then:

```bash
docker compose run --rm --name konduit ops make <environment> konduit
```

---

## Method 2 — Local (no Docker)

Install all [prerequisites](#prerequisites) on your machine.

```bash
bundle install
yarn
bin/rails db:setup                            # creates, migrates, seeds dev + test
cp .env.template .env                         # then fill in secrets
./bin/dev                                     # launches foreman on http://localhost:3000
```

Foreman runs three processes from [`Procfile.dev`](../../Procfile.dev):

| Process | Command                  |
|---------|--------------------------|
| `web`   | `rails server -p 3000`   |
| `js`    | `yarn build --watch`     |
| `css`   | `yarn build:css --watch` |

---

## Method 3 — GitHub Codespaces

Pre-configured dev container (Ruby 3.4.7, Node 24.13.0).

1. Click **Code** → **Create codespace**
2. Wait for post-create script (installs deps, prepares DB)
3. Server starts automatically via `bin/dev`

Request access in `#digital-tools-support` on DfE Slack if needed.
See the [Codespaces docs](https://docs.github.com/en/codespaces/overview).

---

## Method 4 — Tilt

[Tilt](https://tilt.dev/) orchestrates docker-compose with a live-update UI
at http://localhost:10350.

```bash
tilt up                                         # full stack in containers
tilt up -- --local-web                          # run Rails/JS/CSS/worker on host
```

With `--local-web`, Tilt sets all required env vars automatically (encryption
keys, API secrets, etc.).

---

## Environment variables

Copy `.env.template` to `.env` and fill in secrets (ask a team member):

```
GOVUK_NOTIFY_API_KEY=           # ask team
HOSTING_DOMAIN=http://localhost:3000
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=           # see below
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=
TEACHER_AUTH_CLIENT_SECRET=     # ask team
TRS_API_URL=https://preprod.teacher-qualifications-api.education.gov.uk
SENTRY_DSN=                     # optional locally
```

If using Docker Compose or Tilt `--local-web`, these are set for you.

### Active Record Encryption

| Environment                       | Source                                     |
|-----------------------------------|--------------------------------------------|
| Development                       | `.env` (loaded via dotenv)                 |
| Test                              | Hardcoded in `config/environments/test.rb` |
| Review/Staging/Sandbox/Production | Azure Key Vault                            |

The three required variables (`PRIMARY_KEY`, `DETERMINISTIC_KEY`,
`KEY_DERIVATION_SALT`) can be obtained from a team member.

---

## Database

PostgreSQL databases:

| Name                  | Use                     |
|-----------------------|-------------------------|
| `cpd_tte_development` | Development             |
| `cpd_tte_test`        | Test (single worker)    |
| `cpd_tte_test<NN>`    | Test (parallel workers) |

```bash
bin/rails db:setup          # create + migrate + seed
bin/rails db:reset          # drop + recreate + migrate + seed
bin/rails db:migrate:status # inspect schema version
```

---

## Verifying it works

```bash
bundle exec rspec            # should pass (env-only failures are OK)
open http://localhost:3000    # should show the app
bundle exec rubocop          # should pass
bundle exec rake lint:scss   # if SCSS files changed
```

See [Specs and linting](../specs_and_linting.md) for more detail.

---

## Common commands

```bash
bin/rails c                              # console
bin/rails db:migrate                     # migrations
bundle exec rspec                        # full test suite
bundle exec rspec spec/file_spec.rb      # single file
bundle exec rspec spec/file_spec.rb:42   # single test
bundle exec rake parallel:setup && rake parallel:spec   # parallel tests
bundle exec rake jobs:work               # background worker
```

Prefix with `docker compose run web` when using Docker Compose.

---

## Troubleshooting

| Symptom                         | Fix                                                                 |
|---------------------------------|---------------------------------------------------------------------|
| `ActiveRecord::EncryptionError` | Set `ACTIVE_RECORD_ENCRYPTION_*` in `.env`                          |
| Port 3000 in use                | `lsof -ti:3000 \| xargs kill -9` or `PORT=3001 ./bin/dev`           |
| Assets not compiling            | `bin/rails assets:clobber && yarn && yarn build && yarn build:css`  |
| Worker not processing jobs      | Start with `bundle exec rake jobs:work`; check `delayed_jobs` table |
| `Gemfile.lock` changed          | `bundle install` (host) or `docker compose up -d --build` (Docker)  |
| Database connection error       | Ensure PostgreSQL is running and `DATABASE_URL` is set              |
