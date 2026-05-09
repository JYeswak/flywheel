#!/usr/bin/env bash
# Regression test: sync-canonical-doctrine.sh discovers + writes to every
# named stamped repo, including newly-stamped terratitle and zeststream-infra.
#
# Fixture-based — never touches real /Users/josh/Developer trees or canonical
# AGENTS.md. Locks in the bead flywheel-ngfe acceptance contract:
#   - discovery covers all 6 stamped names: alpsinsurance, mobile-eats,
#     skillos, terratitle, zeststream-infra, zesttube
#   - apply writes to every one of them
#   - re-running is idempotent (zero further drift)
set -euo pipefail

ROOT="/Users/josh/Developer/flywheel"
SYNC="$ROOT/.flywheel/scripts/sync-canonical-doctrine.sh"

STAMPED_REPOS=(
  alpsinsurance
  mobile-eats
  skillos
  terratitle
  zeststream-infra
  zesttube
)

TMP="$(mktemp -d "${TMPDIR:-/tmp}/sync-stamped-repos-coverage.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

CANONICAL="$TMP/source/AGENTS.md"
mkdir -p "$(dirname "$CANONICAL")"
printf '# Canonical doctrine\n\n## L66 - synthetic outbound-jeff-issues rule\nbody\n\n## L107 - synthetic shared-surface-writes rule\nbody\n' >"$CANONICAL"

for repo in "${STAMPED_REPOS[@]}"; do
  mkdir -p "$TMP/repos/$repo/.flywheel"
  printf 'stale doctrine for %s\n' "$repo" >"$TMP/repos/$repo/.flywheel/AGENTS-CANONICAL.md"
  printf '# %s local instructions\n\nKeep this line.\n' "$repo" >"$TMP/repos/$repo/AGENTS.md"
done

# Phase 1: dry-run drift detection
rc=0
dry="$(SYNC_CANONICAL_SOURCE="$CANONICAL" \
       SYNC_CANONICAL_ROOTS="$TMP/repos" \
       SYNC_CANONICAL_LOOPS_DIR="$TMP/no-loops" \
       "$SYNC" --dry-run --json 2>&1)" || rc=$?
if [[ "$rc" -ne 1 ]]; then
  printf 'FAIL: dry-run expected rc=1 for drift, got %s\n%s\n' "$rc" "$dry" >&2
  exit 1
fi
if [[ "$(jq -r '.canonical_drifted_count' <<<"$dry")" != "6" ]]; then
  printf 'FAIL: expected canonical_drifted_count=6, got %s\n%s\n' \
    "$(jq -r '.canonical_drifted_count' <<<"$dry")" "$dry" >&2
  exit 1
fi
if [[ "$(jq -r '.root_drifted_count' <<<"$dry")" != "6" ]]; then
  printf 'FAIL: expected root_drifted_count=6, got %s\n%s\n' \
    "$(jq -r '.root_drifted_count' <<<"$dry")" "$dry" >&2
  exit 1
fi

# Every stamped repo name MUST appear in dry-run drift details.
for repo in "${STAMPED_REPOS[@]}"; do
  hit="$(jq -r --arg name "$repo" '[.details[] | select(.target | test("/repos/" + $name + "/"))] | length' <<<"$dry")"
  if [[ "$hit" != "1" ]]; then
    printf 'FAIL: dry-run details missing stamped repo %s (hit=%s)\n%s\n' "$repo" "$hit" "$dry" >&2
    exit 1
  fi
done

# Phase 2: apply writes to all 6
apply="$(SYNC_CANONICAL_SOURCE="$CANONICAL" \
         SYNC_CANONICAL_ROOTS="$TMP/repos" \
         SYNC_CANONICAL_LOOPS_DIR="$TMP/no-loops" \
         "$SYNC" --apply --json)"
if [[ "$(jq -r '.status' <<<"$apply")" != "ok" ]]; then
  printf 'FAIL: apply expected status=ok\n%s\n' "$apply" >&2
  exit 1
fi
if [[ "$(jq -r '.canonical_synced_count' <<<"$apply")" != "6" ]]; then
  printf 'FAIL: expected canonical_synced_count=6, got %s\n%s\n' \
    "$(jq -r '.canonical_synced_count' <<<"$apply")" "$apply" >&2
  exit 1
fi
if [[ "$(jq -r '.root_synced_count' <<<"$apply")" != "6" ]]; then
  printf 'FAIL: expected root_synced_count=6, got %s\n%s\n' \
    "$(jq -r '.root_synced_count' <<<"$apply")" "$apply" >&2
  exit 1
fi

# File-level proof: every stamped repo got the canonical mirror updated.
for repo in "${STAMPED_REPOS[@]}"; do
  if ! diff -q "$CANONICAL" "$TMP/repos/$repo/.flywheel/AGENTS-CANONICAL.md" >/dev/null 2>&1; then
    printf 'FAIL: %s canonical mirror did not match source after apply\n' "$repo" >&2
    exit 1
  fi
  if ! grep -q 'L66' "$TMP/repos/$repo/AGENTS.md"; then
    printf 'FAIL: %s root AGENTS.md missing L66 after apply\n' "$repo" >&2
    exit 1
  fi
  if ! grep -q 'L107' "$TMP/repos/$repo/AGENTS.md"; then
    printf 'FAIL: %s root AGENTS.md missing L107 after apply\n' "$repo" >&2
    exit 1
  fi
  if ! grep -q 'Keep this line.' "$TMP/repos/$repo/AGENTS.md"; then
    printf 'FAIL: %s root AGENTS.md lost local content outside canonical block\n' "$repo" >&2
    exit 1
  fi
done

# Phase 3: idempotent re-run — apply twice yields zero further drift.
post="$(SYNC_CANONICAL_SOURCE="$CANONICAL" \
        SYNC_CANONICAL_ROOTS="$TMP/repos" \
        SYNC_CANONICAL_LOOPS_DIR="$TMP/no-loops" \
        "$SYNC" --dry-run --json)"
if [[ "$(jq -r '.status' <<<"$post")" != "ok" ]]; then
  printf 'FAIL: post-apply dry-run expected status=ok\n%s\n' "$post" >&2
  exit 1
fi
if [[ "$(jq -r '.drifted_count' <<<"$post")" != "0" ]]; then
  printf 'FAIL: post-apply expected drifted_count=0, got %s\n%s\n' \
    "$(jq -r '.drifted_count' <<<"$post")" "$post" >&2
  exit 1
fi

printf 'PASS: sync-canonical-doctrine.sh discovers + writes all 6 stamped repos (incl. terratitle, zeststream-infra)\n'
