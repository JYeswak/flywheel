#!/usr/bin/env bash
# test-fleet-mission-alignment-probe.sh
#
# Smoke test for fleet-mission-alignment-probe.sh using a tmpdir fixture
# with 3 fake repos: fresh, stale-warn, stale-error, plus an unlocked one.
#
# Bead: flywheel-4cbbr
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROBE="${SCRIPT_DIR}/fleet-mission-alignment-probe.sh"

TMP="$(mktemp -d -t fleet-mission-test.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

make_repo() {
  local name="$1" status="$2" locked_at="$3"
  local dir="$TMP/$name/.flywheel"
  mkdir -p "$dir"
  if [ "$status" = "unlocked" ]; then
    cat >"$dir/MISSION.md" <<EOF
status: draft
EOF
  else
    cat >"$dir/MISSION.md" <<EOF
status: locked
locked_at: $locked_at
schema_version: mission.v1
mission_lock_id: test-$name
EOF
  fi
}

# Build fixture set.
now_epoch="$(date -u +%s)"
fresh_ts="$(date -u -r "$now_epoch" +%Y-%m-%dT%H:%M:%SZ)"
warn_ts="$(date -u -r "$((now_epoch - 200*3600))" +%Y-%m-%dT%H:%M:%SZ)"   # ~200h ago
error_ts="$(date -u -r "$((now_epoch - 800*3600))" +%Y-%m-%dT%H:%M:%SZ)"  # ~800h ago

make_repo fresh-repo locked "$fresh_ts"
make_repo warn-repo  locked "$warn_ts"
make_repo error-repo locked "$error_ts"
make_repo unlocked-repo unlocked ""

out="$("$PROBE" --root "$TMP" --json --quiet)"

echo "$out" | jq .

assert_eq() {
  local name="$1" want="$2" got="$3"
  if [ "$got" != "$want" ]; then
    printf 'FAIL %s: want=%s got=%s\n' "$name" "$want" "$got" >&2
    exit 1
  fi
  printf 'ok   %s = %s\n' "$name" "$got"
}

assert_eq schema_version "fleet-mission-alignment.v1" "$(jq -r .schema_version <<<"$out")"
assert_eq total_repos 4 "$(jq -r .total_repos <<<"$out")"
assert_eq fresh_count 1 "$(jq -r .fresh_count <<<"$out")"
assert_eq stale_warn_count 1 "$(jq -r .stale_warn_count <<<"$out")"
assert_eq stale_error_count 1 "$(jq -r .stale_error_count <<<"$out")"
assert_eq unlocked_count 1 "$(jq -r .unlocked_count <<<"$out")"
assert_eq missing_count 0 "$(jq -r .missing_count <<<"$out")"
assert_eq status critical "$(jq -r .status <<<"$out")"

# Worst should be unlocked-repo (rank 4) over stale-error (rank 3).
assert_eq worst_status unlocked "$(jq -r .worst_status <<<"$out")"
assert_eq worst_repo unlocked-repo "$(jq -r .worst_repo <<<"$out")"

# dashboard_line shape
line="$(jq -r .dashboard_line <<<"$out")"
case "$line" in
  "Mission alignment: 1/4 fresh, 2 stale (worst=unlocked-repo:unlocked)") : ;;
  *) printf 'FAIL dashboard_line: %s\n' "$line" >&2; exit 1 ;;
esac
printf 'ok   dashboard_line = %s\n' "$line"

# Test ok status: only fresh repo present.
rm -rf "$TMP/warn-repo" "$TMP/error-repo" "$TMP/unlocked-repo"
out2="$("$PROBE" --root "$TMP" --json --quiet)"
assert_eq ok_status ok "$(jq -r .status <<<"$out2")"
assert_eq ok_fresh 1 "$(jq -r .fresh_count <<<"$out2")"

# Test degraded: only warn repo.
rm -rf "$TMP/fresh-repo"
make_repo warn-only locked "$warn_ts"
out3="$("$PROBE" --root "$TMP" --json --quiet)"
assert_eq degraded_status degraded "$(jq -r .status <<<"$out3")"

printf '\nAll fleet-mission-alignment-probe smoke tests passed.\n'
