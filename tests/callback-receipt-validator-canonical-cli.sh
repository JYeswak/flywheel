#!/usr/bin/env bash
# tests/callback-receipt-validator-canonical-cli.sh
# flywheel-1hshd.9 (wave-4-general-9).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/callback-receipt-validator.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# NEW canonical surfaces
"$SCRIPT" --schema --json 2>/dev/null | jq -e '.schema_version' >/dev/null && pass "--schema --json NEW" || fail "--schema"
"$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor" and (.checks | length >= 5)' >/dev/null && pass "doctor 5+ probes" || fail "doctor"
"$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null && pass "health envelope" || fail "health"
"$SCRIPT" repair --scope none --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run"' >/dev/null && pass "repair --dry-run" || fail "repair --dry-run"
"$SCRIPT" repair --scope none --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "repair --apply rc=3" || fail "repair rc=$rc"
"$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate"' >/dev/null && pass "validate envelope" || fail "validate"
"$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit"' >/dev/null && pass "audit envelope" || fail "audit"
"$SCRIPT" why some-id 2>/dev/null | jq -e '.command == "why"' >/dev/null && pass "why envelope" || fail "why"
"$SCRIPT" help check 2>/dev/null | grep -q 'topic:' && pass "help check" || fail "help"
"$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart"' >/dev/null && pass "quickstart" || fail "quickstart"

# Fillin-specific
"$SCRIPT" doctor --json 2>/dev/null | jq -e '(.checks[] | select(.name == "fix_bead_opener_executable")) and (.checks[] | select(.name == "ledger_writable"))' >/dev/null && pass "doctor: fix_bead_opener + ledger probes" || fail "doctor probes"
"$SCRIPT" repair --scope ledger-rotate --dry-run --json 2>/dev/null | jq -e '.scope == "ledger-rotate"' >/dev/null && pass "repair ledger-rotate non-stub" || fail "repair ledger-rotate"
"$SCRIPT" repair --scope fix-bead-opener-prime --dry-run --json 2>/dev/null | jq -e '.scope == "fix-bead-opener-prime" and has("fix_bead_opener")' >/dev/null && pass "repair fix-bead-opener-prime non-stub" || fail "repair fix-bead-opener-prime"
"$SCRIPT" validate --ledger 2>/dev/null | jq -e '.subject == "ledger" and has("pass_count") and has("refuse_count")' >/dev/null && pass "validate --ledger probes decision counts" || fail "validate ledger"
"$SCRIPT" validate --row-json='{"schema_version":"x","version":"v","ts":"2026-05-11T00:00:00Z","decision":"PASS"}' 2>/dev/null | jq -e '.valid == true' >/dev/null && pass "validate --row-json schema (4 required)" || fail "validate row"

# Backward-compat: --info preserved
"$SCRIPT" --info --json 2>/dev/null | jq -e '.name == "callback-receipt-validator.sh" and has("exit_codes")' >/dev/null && pass "BACKWARD-COMPAT --info preserved" || fail "--info backward-compat"

# Backward-compat: check command still works (the wrapper depends on this).
# flywheel-0u9ch: isolate from prod beads. Without CALLBACK_RECEIPT_FIX_BEAD_OPENER=/bin/true
# the validator's open_fix_bead() auto-invokes the real callback-fix-bead-opener.sh
# against the live REPO and writes a test-fixture bead (e.g., fix-t-1-l112-mismatch)
# into the prod .beads/issues.jsonl. /bin/true is executable + a no-op; the validator
# sees it as present and the output parse falls through to "created_unparsed" without
# touching the prod DB.
out="$(echo "DONE flywheel-test l112_observed=foo task_id=t-1 josh_request_id=null mission_fitness=adjacent mission_fitness_evidence=test br_close_executed=yes git_committed=yes callback_delivery_verified=true" | CALLBACK_RECEIPT_FIX_BEAD_OPENER=/bin/true "$SCRIPT" check --callback-stdin --dispatch-file /tmp/dispatch_nonexistent.md --json 2>&1 || true)"
printf '%s' "$out" | head -1 | jq -e '.schema_version == "callback-receipt-decision/v1" and has("decision")' >/dev/null && pass "BACKWARD-COMPAT check command tri-state output" || fail "check command"

# Wrapper integration test — pipe a malformed callback through wrapper → validator.
# Same isolation: wrapper invokes the validator; without the env override the
# validator's open_fix_bead would write another prod bead from "DONE bad".
out="$(echo "DONE bad" | CALLBACK_RECEIPT_FIX_BEAD_OPENER=/bin/true $HOME/.claude/commands/flywheel/_shared/callback-receipt-validator-wrapper.sh --dispatch-file /tmp/dispatch_test.md --json 2>&1 || true)"
printf '%s' "$out" | grep -qE 'UNVERIFIABLE|REFUSE|decision|schema_version' && pass "BACKWARD-COMPAT wrapper→validator chain intact" || fail "wrapper-validator chain"

# Magic comment + lint
grep -q '# flywheel-cli-surface: true' "$SCRIPT" && pass "L6 magic comment present" || fail "L6 missing"
"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
[[ "$rc" -eq 0 ]] && pass "canonical-cli-lint RC=0 (was RC=1 from L5)" || fail "lint RC=$rc"

# --help shows usage
"$SCRIPT" --help 2>&1 | head -3 | grep -qE 'usage:|callback-receipt-validator' && pass "--help shows usage" || fail "--help"


if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
