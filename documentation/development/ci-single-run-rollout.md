[< Back to overview](overview.md)

# CI single-run rollout

Moves tests, lint and main deployment into one run per branch push. Behaviour is
in [Specs and Linting](specs-and-linting.md#ci). This page records verification
status and rollout tasks. The earlier API-polling gate design was replaced by this
approved native design and no longer exists.

## Status

**Observed (before merge):**
- 25 focused ordering examples (real git and workflow wiring) pass; a mutation
  that breaks the freshness check is caught.
- RuboCop (1127 files) is clean; actionlint and ShellCheck are clean; workflow
  structure tests are clean.
- Second review found no BLOCKING findings.

**Not executed:** the full RSpec suite and an end-to-end GitHub workflow run.

## Rollout tasks

All are human actions; none is done by the code change.

- [ ] Inventory required checks, rulesets, branch protection, strict rules and
      merge queue (not verified; do not assume what is required today).
- [ ] After a real run, record the contexts emitted for `Lint ruby`,
      `Lint SCSS`, `Run Rspec (6, N)` and `All checks passed`, and map the old
      names (Deploy's nested `RSpec / ...` and old gate) to them.
- [ ] Migrate required checks in the ruleset (approval needed; no settings are
      edited by this change). Confirm a representative PR has no obsolete
      required check stuck pending, and Dependabot auto-merge is not stranded.
- [ ] Verify on GitHub: a branch push without a PR runs one suite; PR open/label
      adds none; a main push deploys through staging, sandbox, production; two
      rapid main pushes skip the superseded run; a failing newest commit leaves
      environments unchanged; a `deploy`-labelled PR still gets a review app.
- [ ] Decide on fork PR support, merge queue handling and head-only PR testing.

## Known follow-up

Domains deployment lacks per-domain freshness checks, and
`Deploy Domains Infrastructure` shares the concurrency group `deploy_production`
with the production entry of the `Deploy Domains` matrix. Domains may be stale or
interleaved. A superseded run can also end green with later stages skipped. The
deployment chain is not claimed to be race-free.
