#!/usr/bin/env bash
# Decides whether the commit being deployed is still the tip of the deploy branch.
#
# Deploy jobs for different pushes can finish their tests out of order (an older
# run can pass after a newer one). Each deploy stage runs this inside its
# per-environment lock: a run whose commit is no longer the branch tip is
# obsolete and must not deploy over a newer commit.
#
# Required env: SHA (commit under deployment)
# Optional env: REMOTE (default origin), BRANCH (default main)
# Writes fresh=true|false to $GITHUB_OUTPUT. Fails (non-zero) if the tip cannot be
# determined, so an unknown state never deploys and never silently skips.
set -euo pipefail

: "${SHA:?SHA is required}"
REMOTE="${REMOTE:-origin}"
BRANCH="${BRANCH:-main}"
OUTPUT="${GITHUB_OUTPUT:-/dev/null}"
SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/null}"

tip=$(git ls-remote --exit-code "$REMOTE" "refs/heads/${BRANCH}" | cut -f1)
if [[ ! "$tip" =~ ^[0-9a-f]{40}$ ]]; then
  echo "::error::Could not determine the tip of ${BRANCH} (got '${tip}')"
  exit 1
fi

if [ "$tip" = "$SHA" ]; then
  echo "fresh=true" >> "$OUTPUT"
  echo "${SHA} is the tip of ${BRANCH}"
else
  echo "fresh=false" >> "$OUTPUT"
  echo "::notice::Skipping deploy: ${SHA} is superseded by ${tip} on ${BRANCH}"
  echo "Skipped deploy of \`${SHA}\`: superseded by \`${tip}\` on \`${BRANCH}\`" >> "$SUMMARY"
fi
