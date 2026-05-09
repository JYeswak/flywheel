#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/tentacle-drift-sweep.sh"
RUNNER="$ROOT/.flywheel/scripts/jeff-intel-scheduled-runner.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/tentacle-drift-sweep.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    printf '  filter=%s file=%s\n' "$filter" "$file" >&2
    jq . "$file" >&2 || true
  fi
}

make_drift_repo() {
  local remote="$TMP/remote.git" upstream="$TMP/upstream" repo="$TMP/repo"
  git init --bare -q "$remote"
  git init -q -b main "$upstream"
  git -C "$upstream" config user.email test@example.com
  git -C "$upstream" config user.name "Tentacle Test"
  printf 'base\n' >"$upstream/file.txt"
  git -C "$upstream" add file.txt
  git -C "$upstream" commit -qm base
  git -C "$upstream" remote add origin "$remote"
  git -C "$upstream" push -q -u origin main
  git -C "$remote" symbolic-ref HEAD refs/heads/main
  git clone -q "$remote" "$repo"
  git -C "$repo" config user.email test@example.com
  git -C "$repo" config user.name "Tentacle Test"
  for n in 1 2 3; do
    printf 'change-%s\n' "$n" >>"$upstream/file.txt"
    git -C "$upstream" add file.txt
    git -C "$upstream" commit -qm "change $n"
  done
  git -C "$upstream" push -q origin main
  git -C "$repo" fetch -q origin main
  printf '%s\n' "$repo"
}

repo="$(make_drift_repo)"
head_before="$(git -C "$repo" rev-parse HEAD)"
remote_tracking_before="$(git -C "$repo" rev-parse origin/main)"
repos="$TMP/repos.jsonl"
ledger="$TMP/tentacle-drift.jsonl"
alerts="$TMP/tentacle-drift-alerts.jsonl"
jq -nc --arg path "$repo" '{name:"fixture-tentacle",path:$path,index_status:"verified_indexed"}' >"$repos"
jq -nc --arg path "$TMP/missing" '{name:"missing-tentacle",path:$path,index_status:"verified_indexed"}' >>"$repos"

bash -n "$SCRIPT" && pass "script syntax" || fail "script syntax"
"$SCRIPT" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.row_required_fields == ["repo","local_head","upstream_head","commits_behind","status"] and .thresholds.warn_commits == 50 and .thresholds.fail_commits == 200 and (.mutation_policy | contains("never fetches"))' "schema documents required fields and no-mutation policy"

"$SCRIPT" --doctor --repos-jsonl "$repos" --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.status == "pass" and .repo_count == 2' "doctor validates repo inventory"

"$SCRIPT" --repos-jsonl "$repos" --ledger "$ledger" --alert-ledger "$alerts" --warn-threshold 2 --fail-threshold 10 --now 2026-05-09T06:00:00Z --dry-run --json >"$TMP/dry.json"
assert_jq "$TMP/dry.json" '.status == "warn" and .dry_run == true and .repo_count == 2 and .alert_count == 2 and .warn_count == 1 and .missing_count == 1 and (.rows[] | select(.repo == "fixture-tentacle" and .commits_behind == 3 and .status == "warn" and (.local_head | length) == 40 and (.upstream_head | length) == 40))' "dry-run reports behind and missing rows"
if [[ ! -e "$ledger" && ! -e "$alerts" ]]; then
  pass "dry-run skips ledgers"
else
  fail "dry-run skips ledgers"
fi

"$SCRIPT" --repos-jsonl "$repos" --ledger "$ledger" --alert-ledger "$alerts" --warn-threshold 2 --fail-threshold 10 --now 2026-05-09T06:00:00Z --apply --json >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '.status == "warn" and .dry_run == false and .max_commits_behind == 3' "apply summary reports max drift"
jq -s 'length == 2 and (.[0] | has("repo") and has("local_head") and has("upstream_head") and has("commits_behind") and has("status"))' "$ledger" >/dev/null \
  && pass "apply writes required JSONL rows" || fail "apply writes required JSONL rows"
jq -s 'length == 2 and ([.[].repo] | sort) == ["fixture-tentacle","missing-tentacle"]' "$alerts" >/dev/null \
  && pass "apply writes alert path rows" || fail "apply writes alert path rows"

"$SCRIPT" --repos-jsonl "$repos" --ledger "$TMP/fail-ledger.jsonl" --alert-ledger "$TMP/fail-alerts.jsonl" --warn-threshold 1 --fail-threshold 2 --dry-run --json >"$TMP/fail-threshold.json"
assert_jq "$TMP/fail-threshold.json" '.fail_count == 1 and (.rows[] | select(.repo == "fixture-tentacle" and .status == "fail" and .commits_behind == 3))' "fail threshold classifies row"

head_after="$(git -C "$repo" rev-parse HEAD)"
remote_tracking_after="$(git -C "$repo" rev-parse origin/main)"
if [[ "$head_before" == "$head_after" && "$remote_tracking_before" == "$remote_tracking_after" ]]; then
  pass "sweep does not mutate target repo refs"
else
  fail "sweep does not mutate target repo refs"
fi

JEFF_INTEL_STATE_DIR="$TMP/schedule-state" FLYWHEEL_STATE_DIR="$TMP/flywheel-state" \
  TENTACLE_DRIFT_REPOS_JSONL="$repos" TENTACLE_DRIFT_LEDGER="$TMP/scheduled-ledger.jsonl" TENTACLE_DRIFT_ALERT_LEDGER="$TMP/scheduled-alerts.jsonl" \
  TENTACLE_DRIFT_WARN_THRESHOLD=2 TENTACLE_DRIFT_FAIL_THRESHOLD=10 JEFF_INTEL_NOW="2026-05-09T06:00:00Z" \
  "$RUNNER" --mode tentacle-drift --dry-run --json >"$TMP/runner-dry.json"
assert_jq "$TMP/runner-dry.json" '.status == "pass" and .mode == "tentacle-drift" and .dry_run == true and .tentacle_drift.status == "warn" and .tentacle_drift.alert_count == 2' "scheduled runner dry-run wraps drift sweep"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'FAIL tentacle-drift-sweep tests pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'PASS tentacle-drift-sweep tests pass=%s fail=0\n' "$pass_count"
