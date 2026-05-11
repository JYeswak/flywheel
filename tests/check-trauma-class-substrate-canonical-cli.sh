#!/usr/bin/env bash
# Canonical-CLI surface tests for check-trauma-class-substrate.sh
# (bead flywheel-1hshd.12 — wave-4-general-12 partial → passing).
# Verifies AG3 strict gates + sister-pattern surfaces (doctor 6+ probes,
# health, repair 2 scopes + apply contract, validate 3 subjects, audit,
# why 3 states, quickstart). Pre-existing scanner behavior is covered
# by tests/check-trauma-class-substrate-test.sh and unaffected here.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/check-trauma-class-substrate.sh"
TMP="$(mktemp -d -t tcs-cli.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
LOG="$TMP/runs.jsonl"

pass=0; fail=0
ok()  { printf 'PASS %s\n' "$1"; pass=$((pass+1)); }
bad() { printf 'FAIL %s\n' "$1" >&2; fail=$((fail+1)); }
expect_rc() { [[ "$1" == "$2" ]] && ok "$3 rc=$1" || bad "$3 expected_rc=$2 got=$1"; }
expect_jq() { jq -e "$2" "$1" >/dev/null && ok "$3" || { bad "$3"; jq . "$1" >&2 || true; }; }

# Test 1: --info AG3.1 (.name + .version + .capabilities)
"$SCRIPT" --info --json >"$TMP/info.json"
expect_jq "$TMP/info.json" '.name == "check-trauma-class-substrate.sh" and .version and (.capabilities|type=="array") and (.capabilities|length>=3)' "AG3.1 --info has name+version+capabilities"

# Test 2: --schema AG3.2 (.input_schema + .output_schema)
"$SCRIPT" --schema --json >"$TMP/schema.json"
expect_jq "$TMP/schema.json" '.input_schema and .output_schema and (.surfaces|index("doctor"))' "AG3.2 --schema has input/output schemas"

# Test 3: --examples AG3.3 (.examples > 0)
"$SCRIPT" --examples --json >"$TMP/examples.json"
expect_jq "$TMP/examples.json" '.examples | length >= 3' "AG3.3 --examples has >=3 entries"

# Test 4: doctor AG3.4 (.checks, >= 5 named probes)
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" doctor --json >"$TMP/doctor.json"
expect_jq "$TMP/doctor.json" '.checks | length >= 5' "AG3.4 doctor has >=5 checks"
expect_jq "$TMP/doctor.json" '[.checks[].name] | index("PlistBuddy_available")' "doctor includes PlistBuddy probe (load-bearing)"

# Test 5: health binds audit log
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" health --json >"$TMP/health.json"
expect_jq "$TMP/health.json" '.audit_log == "'"$LOG"'" and .stale_threshold_seconds and (.status=="pass" or .status=="warn")' "health binds audit_log + stale_threshold"

# Test 6: repair --dry-run audit_log_dir
"$SCRIPT" repair --scope audit_log_dir --dry-run --json >"$TMP/repair-dry.json"
expect_jq "$TMP/repair-dry.json" '.status == "ok" and .mode == "dry_run" and .scope == "audit_log_dir"' "repair --dry-run audit_log_dir"

# Test 7: repair --apply without --idempotency-key returns rc=3
set +e; "$SCRIPT" repair --scope audit_log_dir --apply --json >"$TMP/repair-refused.json"; rc=$?; set -e
expect_rc "$rc" 3 "repair --apply without key refused"
expect_jq "$TMP/repair-refused.json" '.status == "refused"' "repair refused has status=refused"

# Test 8: repair registry_path REPORT-ONLY scope
"$SCRIPT" repair --scope registry_path --dry-run --json >"$TMP/repair-report.json"
expect_jq "$TMP/repair-report.json" '.status == "report" and .scope == "registry_path" and (.readable|type=="boolean")' "repair registry_path REPORT-ONLY"

# Test 9: repair unknown scope returns rc=64
set +e; "$SCRIPT" repair --scope bogus --json >"$TMP/repair-unk.json"; rc=$?; set -e
expect_rc "$rc" 64 "repair unknown_scope rc=64"

# Test 10: validate root-path absolute OK
"$SCRIPT" validate root-path /Users/josh >"$TMP/v-rp-ok.json"
expect_jq "$TMP/v-rp-ok.json" '.status == "ok" and .subject == "root-path"' "validate root-path absolute OK"

# Test 11: validate root-path relative rc=1
set +e; "$SCRIPT" validate root-path some/relative >"$TMP/v-rp-bad.json"; rc=$?; set -e
expect_rc "$rc" 1 "validate root-path relative rc=1"
expect_jq "$TMP/v-rp-bad.json" '.status == "reject" and .reason == "not_absolute_path"' "validate root-path reject reason"

# Test 12: validate class-name enum members
for cn in silent-write destructive-default unregistered-process; do
  "$SCRIPT" validate class-name "$cn" >"$TMP/v-cn-$cn.json"
  expect_jq "$TMP/v-cn-$cn.json" '.status == "ok"' "validate class-name $cn OK"
done

# Test 13: validate class-name unknown rc=1
set +e; "$SCRIPT" validate class-name bogus-class >"$TMP/v-cn-bad.json"; rc=$?; set -e
expect_rc "$rc" 1 "validate class-name unknown rc=1"

# Test 14: validate unknown subject rc=64
set +e; "$SCRIPT" validate fictitious-subject >"$TMP/v-sub-bad.json"; rc=$?; set -e
expect_rc "$rc" 64 "validate unknown_subject rc=64"

# Test 15: audit empty
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" audit --json >"$TMP/audit-empty.json"
expect_jq "$TMP/audit-empty.json" '.status == "missing" or .status == "empty"' "audit empty/missing"

# Test 16: audit with rows
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '{"ts":"%s","action":"smoke","class":"silent-write","run_id":"r1"}\n' "$TS" > "$LOG"
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" audit --json >"$TMP/audit-row.json"
expect_jq "$TMP/audit-row.json" '.status == "pass" and .row_count == 1' "audit with row pass"

# Test 17: why found (3rd state)
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" why "$TS" --json >"$TMP/why-found.json"
expect_jq "$TMP/why-found.json" '.status == "found" and .row.run_id == "r1"' "why found"

# Test 18: why not_found (2nd state)
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" why no-such-id --json >"$TMP/why-nf.json"
expect_jq "$TMP/why-nf.json" '.status == "not_found"' "why not_found"

# Test 19: why unavailable (1st state — audit log absent)
SCAFFOLD_AUDIT_LOG="$TMP/missing.jsonl" "$SCRIPT" why anything --json >"$TMP/why-unavail.json"
expect_jq "$TMP/why-unavail.json" '.status == "unavailable" and .reason == "audit_log_missing"' "why unavailable"

# Test 20: quickstart
"$SCRIPT" quickstart --json >"$TMP/qs.json"
expect_jq "$TMP/qs.json" '.command == "quickstart" and (.steps | length >= 3)' "quickstart steps"

# Test 21: backward-compat — bare invocation falls through to native scanner
# The native scanner reads from --root paths; bare scan with --json against
# an isolated empty dir must emit "[]" with rc=0 (no findings).
EMPTY_ROOT="$TMP/empty-root"; mkdir -p "$EMPTY_ROOT"
EMPTY_REG="$TMP/empty-registry.jsonl"; : > "$EMPTY_REG"
EMPTY_LA="$TMP/empty-launchagents"; mkdir -p "$EMPTY_LA"
EMPTY_PS="$TMP/empty-ps.txt"; : > "$EMPTY_PS"
"$SCRIPT" --json --root "$EMPTY_ROOT" --launchagents-dir "$EMPTY_LA" --registry "$EMPTY_REG" --local-bin-dir "$TMP/local-bin" --ps-fixture "$EMPTY_PS" >"$TMP/native.json"
expect_jq "$TMP/native.json" 'type == "array" and length == 0' "backward-compat: bare --json native scanner emits []"

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
