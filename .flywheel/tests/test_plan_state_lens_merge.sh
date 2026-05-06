#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
BIN="$ROOT/.flywheel/scripts/plan-state-lens-merge.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/plan-state-lens-merge.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

make_plan() {
  local dir="$1"
  mkdir -p "$dir"
  cat >"$dir/STATE.json" <<'JSON'
{
  "schema_version": 3,
  "plan_slug": "fixture-plan",
  "current_phase": "audit",
  "refine_round": 4,
  "convergence_streak": 2,
  "artifacts": {"refine_r4": "fixture"}
}
JSON
}

state_sha() {
  jq -S 'walk(if type=="object" then del(.state_written_sha) else . end)' "$1" | shasum -a 256 | awk '{print "sha256:" $1}'
}

append_lens() {
  local plan="$1" lens="$2" row="$3" out="$4"
  "$BIN" append --plan "$plan" --lens "$lens" --row-json "$row" --json >"$out"
}

bash -n "$BIN" && pass "helper_syntax" || fail "helper_syntax"
"$BIN" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.name == "plan-state-lens-merge" and (.subcommands | length == 3) and (.canonical_cli_flags | index("--quiet"))' "info exposes subcommands and canonical flags"

plan1="$TMP/plan1"
make_plan "$plan1"
append_lens "$plan1" security '{"audit_lens_identity_key":"security-v1","findings_by_severity":{"critical":0,"high":1,"medium":4,"low":1},"audit_disposition":"auto_advance"}' "$TMP/append1.json"
"$BIN" derived --plan "$plan1" --json >"$TMP/derived1.json"
assert_jq "$TMP/append1.json" '.status == "appended" and .race_detected == false' "single append succeeds"
assert_jq "$TMP/derived1.json" '.audit_lenses_complete == ["security"] and .audit_findings_count == 6 and .audit_findings_by_severity.high == 1' "single lens derived summary correct"

plan2="$TMP/plan2"
make_plan "$plan2"
base_sha="$(state_sha "$plan2/STATE.json")"
append_lens "$plan2" security '{"audit_lens_identity_key":"sec","findings_by_severity":{"high":1},"audit_disposition":"auto_advance"}' "$TMP/p2a.json"
append_lens "$plan2" idempotency "{\"audit_lens_identity_key\":\"idem\",\"state_observed_sha\":\"$base_sha\",\"findings_by_severity\":{\"medium\":4,\"low\":1},\"audit_disposition\":\"auto_advance\"}" "$TMP/p2b.json"
append_lens "$plan2" cross-cutting "{\"audit_lens_identity_key\":\"csr\",\"state_observed_sha\":\"$base_sha\",\"findings_by_severity\":{\"high\":2,\"medium\":3,\"low\":1},\"audit_disposition\":\"auto_advance\"}" "$TMP/p2c.json"
"$BIN" derived --plan "$plan2" --json >"$TMP/derived2.json"
assert_jq "$TMP/p2b.json" '.status == "appended" and .race_detected == true and .retry_count == 1' "stale observed hash retries"
assert_jq "$TMP/derived2.json" '([.audit_lenses_complete[]] | sort) == (["cross-cutting","idempotency","security"] | sort) and .audit_findings_count == 12 and .effective_lenses_count == 3' "three lens derived summary correct"

assert_jq "$plan2/STATE.json" '.refine_round == 4 and .convergence_streak == 2 and .artifacts.refine_r4 == "fixture"' "existing summary fields preserved"

plan_bad="$TMP/plan-bad"
mkdir -p "$plan_bad"
cat >"$plan_bad/STATE.json" <<'JSON'
{"lens_merge_rows":[{"lens":"bad","ts":"2026-05-06T00:00:00Z","audit_lens_identity_key":"bad","state_written_sha":"sha256:x"}]}
JSON
set +e
"$BIN" validate --plan "$plan_bad" --json >"$TMP/bad.json"
bad_rc=$?
set -e
[[ "$bad_rc" -eq 1 ]] && pass "malformed validate exits nonzero" || fail "malformed validate exits nonzero"
assert_jq "$TMP/bad.json" '.status == "fail" and .malformed_count == 1' "missing state_observed_sha fails validate"

plan3="$TMP/plan3"
make_plan "$plan3"
append_lens "$plan3" idempotency '{"audit_lens_identity_key":"idem-old","findings_by_severity":{"high":1},"audit_disposition":"auto_advance"}' "$TMP/p3a.json"
append_lens "$plan3" idempotency '{"audit_lens_identity_key":"idem-new","supersedes":"idem-old","findings_by_severity":{"medium":2},"audit_disposition":"auto_advance"}' "$TMP/p3b.json"
"$BIN" derived --plan "$plan3" --json >"$TMP/derived3.json"
assert_jq "$plan3/STATE.json" '(.lens_merge_rows | length) == 2 and .lens_merge_rows[1].supersedes == "idem-old"' "supersede keeps old row"
assert_jq "$TMP/derived3.json" '.audit_lenses_complete == ["idempotency"] and .audit_findings_count == 2 and .audit_findings_by_severity.high == 0 and .audit_findings_by_severity.medium == 2' "supersede row wins in derived"

"$BIN" validate --plan "$plan3" --json >"$TMP/valid.json"
assert_jq "$TMP/valid.json" '.status == "pass" and .row_count == 2' "validate passes complete rows"

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$pass_count" -ge 11 && "$fail_count" == "0" ]]
