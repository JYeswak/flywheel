#!/usr/bin/env bash
# Synthetic regression test for sync-canonical-doctrine.sh.
set -euo pipefail

ROOT="/Users/josh/Developer/flywheel"
SYNC="$ROOT/.flywheel/scripts/sync-canonical-doctrine.sh"
BEGIN="<!-- BEGIN-CANONICAL-FLYWHEEL-DOCTRINE -->"
END="<!-- END-CANONICAL-FLYWHEEL-DOCTRINE -->"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/sync-canonical-doctrine-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

CANONICAL="$TMP/source/AGENTS.md"
mkdir -p "$(dirname "$CANONICAL")"
printf '# Canonical doctrine\n\n## L61 - synthetic ecosystem rule\nbody\n\n## L70 - synthetic no-punt rule\nbody\n' >"$CANONICAL"

for repo in repo-a repo-b repo-c; do
  mkdir -p "$TMP/repos/$repo/.flywheel"
done
cp "$CANONICAL" "$TMP/repos/repo-a/.flywheel/AGENTS-CANONICAL.md"
printf 'old doctrine\n' >"$TMP/repos/repo-b/.flywheel/AGENTS-CANONICAL.md"
printf 'older doctrine\n' >"$TMP/repos/repo-c/.flywheel/AGENTS-CANONICAL.md"

printf '# Repo A local instructions\n\nKeep this line.\n' >"$TMP/repos/repo-a/AGENTS.md"
printf '# Repo B local instructions\n\n%s\nstale block\n%s\n\nKeep after block.\n' "$BEGIN" "$END" >"$TMP/repos/repo-b/AGENTS.md"

rc=0
dry="$(SYNC_CANONICAL_SOURCE="$CANONICAL" SYNC_CANONICAL_ROOTS="$TMP/repos" SYNC_CANONICAL_LOOPS_DIR="$TMP/no-loops" "$SYNC" --dry-run --json 2>&1)" || rc=$?
if [[ "$rc" -ne 1 ]]; then
  printf 'FAIL: dry-run expected rc=1 for drift, got %s\n%s\n' "$rc" "$dry" >&2
  exit 1
fi
if [[ "$(jq -r '.canonical_drifted_count' <<<"$dry")" != "2" ]]; then
  printf 'FAIL: dry-run expected canonical_drifted_count=2\n%s\n' "$dry" >&2
  exit 1
fi
if [[ "$(jq -r '.root_drifted_count' <<<"$dry")" != "3" ]]; then
  printf 'FAIL: dry-run expected root_drifted_count=3\n%s\n' "$dry" >&2
  exit 1
fi
if [[ "$(jq -r '[.root_details[] | select(.status=="drifted" and (.missing_rules | index("L70")))] | length' <<<"$dry")" != "3" ]]; then
  printf 'FAIL: dry-run expected L70 root drift detection for all repos\n%s\n' "$dry" >&2
  exit 1
fi

apply="$(SYNC_CANONICAL_SOURCE="$CANONICAL" SYNC_CANONICAL_ROOTS="$TMP/repos" SYNC_CANONICAL_LOOPS_DIR="$TMP/no-loops" "$SYNC" --apply --json)"
if [[ "$(jq -r '.status' <<<"$apply")" != "ok" || "$(jq -r '.canonical_synced_count' <<<"$apply")" != "2" || "$(jq -r '.root_synced_count' <<<"$apply")" != "3" ]]; then
  printf 'FAIL: apply expected status=ok canonical_synced_count=2 root_synced_count=3\n%s\n' "$apply" >&2
  exit 1
fi
if ! ls "$TMP/repos/repo-b/.flywheel"/AGENTS-CANONICAL.md.bak.* >/dev/null 2>&1; then
  printf 'FAIL: repo-b canonical snapshot backup missing before overwrite\n%s\n' "$apply" >&2
  exit 1
fi
if ! grep -q 'old doctrine' "$TMP/repos/repo-b/.flywheel"/AGENTS-CANONICAL.md.bak.*; then
  printf 'FAIL: repo-b canonical snapshot backup did not preserve prior content\n' >&2
  exit 1
fi
if ! ls "$TMP/repos/repo-a"/AGENTS.md.bak.* >/dev/null 2>&1; then
  printf 'FAIL: repo-a root AGENTS.md backup missing before canonical block insert\n%s\n' "$apply" >&2
  exit 1
fi
if ! grep -q 'Keep this line.' "$TMP/repos/repo-a"/AGENTS.md.bak.*; then
  printf 'FAIL: repo-a root AGENTS.md backup did not preserve prior content\n' >&2
  exit 1
fi
if ! ls "$TMP/repos/repo-b"/AGENTS.md.bak.* >/dev/null 2>&1; then
  printf 'FAIL: repo-b root AGENTS.md backup missing before canonical block replace\n%s\n' "$apply" >&2
  exit 1
fi
if ! grep -q 'stale block' "$TMP/repos/repo-b"/AGENTS.md.bak.*; then
  printf 'FAIL: repo-b root AGENTS.md backup did not preserve prior block\n' >&2
  exit 1
fi

for repo in repo-a repo-b repo-c; do
  if ! diff -q "$CANONICAL" "$TMP/repos/$repo/.flywheel/AGENTS-CANONICAL.md" >/dev/null 2>&1; then
    printf 'FAIL: %s target did not match canonical after apply\n' "$repo" >&2
    exit 1
  fi
  if [[ "$(grep -c 'L70' "$TMP/repos/$repo/AGENTS.md")" -lt 1 ]]; then
    printf 'FAIL: %s root AGENTS.md missing L70 after apply\n' "$repo" >&2
    exit 1
  fi
done
if ! grep -q 'Keep this line.' "$TMP/repos/repo-a/AGENTS.md"; then
  printf 'FAIL: repo-a root AGENTS.md lost local content outside canonical block\n' >&2
  exit 1
fi
if ! grep -q 'Keep after block.' "$TMP/repos/repo-b/AGENTS.md"; then
  printf 'FAIL: repo-b root AGENTS.md lost trailing content outside canonical block\n' >&2
  exit 1
fi

post="$(SYNC_CANONICAL_SOURCE="$CANONICAL" SYNC_CANONICAL_ROOTS="$TMP/repos" SYNC_CANONICAL_LOOPS_DIR="$TMP/no-loops" "$SYNC" --dry-run --json)"
if [[ "$(jq -r '.status' <<<"$post")" != "ok" || "$(jq -r '.drifted_count' <<<"$post")" != "0" ]]; then
  printf 'FAIL: post-apply dry-run expected clean status\n%s\n' "$post" >&2
  exit 1
fi

before_hash="$(shasum -a 256 "$TMP/repos/repo-a/AGENTS.md" | awk '{print $1}')"
rerun="$(SYNC_CANONICAL_SOURCE="$CANONICAL" SYNC_CANONICAL_ROOTS="$TMP/repos" SYNC_CANONICAL_LOOPS_DIR="$TMP/no-loops" "$SYNC" --apply --json)"
after_hash="$(shasum -a 256 "$TMP/repos/repo-a/AGENTS.md" | awk '{print $1}')"
if [[ "$(jq -r '.synced_count' <<<"$rerun")" != "0" || "$before_hash" != "$after_hash" ]]; then
  printf 'FAIL: idempotent re-run changed root AGENTS.md\n%s\n' "$rerun" >&2
  exit 1
fi

missing_rc=0
missing="$(SYNC_CANONICAL_SOURCE="$TMP/missing/AGENTS.md" SYNC_CANONICAL_ROOTS="$TMP/repos" SYNC_CANONICAL_LOOPS_DIR="$TMP/no-loops" "$SYNC" --dry-run --json 2>&1)" || missing_rc=$?
if [[ "$missing_rc" -ne 2 ]]; then
  printf 'FAIL: missing source expected rc=2, got %s\n%s\n' "$missing_rc" "$missing" >&2
  exit 1
fi
if [[ "$(jq -r '.errors[0].code // empty' <<<"$missing")" != "source_missing" ]]; then
  printf 'FAIL: missing source expected source_missing code\n%s\n' "$missing" >&2
  exit 1
fi

printf 'PASS: sync-canonical-doctrine synthetic test passed\n'
