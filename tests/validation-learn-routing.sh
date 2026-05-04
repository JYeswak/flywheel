#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/validation-learn-routing.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

make_repo() {
  local repo="$TMP/repo"
  rm -rf "$repo"
  mkdir -p "$repo/.flywheel/validation-receipts" "$repo/.flywheel/validation-schema/v1"
  git -C "$repo" init -q >/dev/null 2>&1
  cp "$ROOT/.flywheel/validation-schema/v1/schema.json" "$repo/.flywheel/validation-schema/v1/schema.json"
  cp "$ROOT/.flywheel/validation-schema/v1/parse.sh" "$repo/.flywheel/validation-schema/v1/parse.sh"
  chmod +x "$repo/.flywheel/validation-schema/v1/parse.sh"
  printf 'fixture artifact\n' >"$repo/evidence.md"
  python3 - "$repo" <<'PY'
import json
import sys
from pathlib import Path

repo = Path(sys.argv[1])
receipts = repo / ".flywheel/validation-receipts"
base = {
    "schema_version": "validation-receipt/v1",
    "dispatch_id": "kscr-pass",
    "callback_ref": {
        "transport": "manual_fixture",
        "session": "flywheel",
        "pane": 3,
        "kind": "DONE",
        "received_at": "2026-05-03T23:55:00Z",
        "raw_ref": "DONE kscr fixture",
    },
    "status": "pass",
    "failure_classes": [],
    "evidence": [{"type": "path", "ref": "evidence.md"}],
    "artifact_checks": [{"artifact_id": "evidence", "path": "evidence.md", "status": "exists"}],
    "runtime_context": {
        "agent_context": {"status": "responsive", "probe_ref": "fixture://agent", "resolved_tools": ["ntm"]},
        "orchestrator_shell_context": {"status": "responsive", "probe_ref": "fixture://orch", "resolved_tools": ["ntm"]},
        "timeout": False,
        "context_drift": False,
    },
    "bead_actions": [{"action": "no_bead_reason", "reason": "fixture no issue"}],
    "learn_route": {"route": "ignore", "reason": "positive validation receipt", "dedupe_key": "kscr-pass"},
    "chain_blocker": {"next_phase": None, "capacity_available": False, "chain_blocked_reason": None},
}

def write(name, data):
    (receipts / name).write_text(json.dumps(data, sort_keys=True))

failed = dict(base)
failed["dispatch_id"] = "kscr-failed"
failed["status"] = "fail"
failed["failure_classes"] = ["artifact_missing"]
failed["artifact_checks"] = [{"artifact_id": "missing", "path": "missing.md", "status": "missing"}]
failed["learn_route"] = {"route": "review", "reason": "failed validation needs review", "dedupe_key": "kscr-failed"}
write("01-failed-review.json", failed)

positive = dict(base)
positive["dispatch_id"] = "kscr-positive"
positive["learn_route"] = {"route": "ignore", "reason": "positive validation receipt ignored", "dedupe_key": "kscr-positive"}
write("02-positive-ignore.json", positive)

skill = dict(base)
skill["dispatch_id"] = "kscr-skill"
skill["status"] = "fail"
skill["failure_classes"] = ["validation_skill_gap"]
skill["learn_route"] = {"route": "skill_extend", "reason": "failure needs skill extension", "dedupe_key": "kscr-skill"}
write("03-skill-extend.json", skill)

promote = dict(base)
promote["dispatch_id"] = "kscr-promote"
promote["status"] = "fail"
promote["failure_classes"] = ["callback_validation_skipped"]
promote["learn_route"] = {"route": "promote", "reason": "recurring failure follows L56 ladder", "dedupe_key": "kscr-promote"}
write("04-promote.json", promote)

unrouted = dict(base)
unrouted["dispatch_id"] = "kscr-unrouted"
unrouted["learn_route"] = {"route": "unknown", "reason": "invalid route fixture", "dedupe_key": "kscr-unrouted"}
write("05-unrouted.json", unrouted)
PY
  printf '%s\n' "$repo"
}

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

run_route() {
  local name="$1"; shift
  local out="$TMP/$name.json"
  FLYWHEEL_FUCKUP_LOG="$TMP/fuckup-log.jsonl" \
  FLYWHEEL_VALIDATION_LEARN_LEDGER="$TMP/validation-learn-ledger.jsonl" \
    "$BIN" validation-learn --repo "$repo" "$@" --json >"$out"
  printf '%s\n' "$out"
}

repo="$(make_repo)"

review_out="$(run_route review --review)"
assert_jq "$review_out" '(.unrouted_validation_events | length) == 1 and (.pending_validation_events | length) == 4' "B09_AG6 review lists unrouted and pending events"

failed_out="$(run_route failed --receipt .flywheel/validation-receipts/01-failed-review.json --apply)"
assert_jq "$failed_out" '.results[0].action == "logged_fuckup" and .results[0].applied == true' "B09_AG2 failed validation logs fuckup"
if [[ "$(wc -l <"$TMP/fuckup-log.jsonl" | tr -d ' ')" == "1" ]]; then
  pass "B09_AG2 exactly one fuckup after first failed receipt"
else
  fail "B09_AG2 exactly one fuckup after first failed receipt"
fi

dup_out="$(run_route duplicate --receipt .flywheel/validation-receipts/01-failed-review.json --apply)"
assert_jq "$dup_out" '.results[0].action == "linked_existing"' "B09_AG5 duplicate receipt links existing event"
if [[ "$(wc -l <"$TMP/fuckup-log.jsonl" | tr -d ' ')" == "1" ]]; then
  pass "B09_AG5 duplicate failed receipt does not create second fuckup"
else
  fail "B09_AG5 duplicate failed receipt does not create second fuckup"
fi

positive_out="$(run_route positive --receipt .flywheel/validation-receipts/02-positive-ignore.json --apply)"
assert_jq "$positive_out" '.results[0].action == "ignored_positive"' "B09_AG3 positive validation is ignored with explicit route"
if [[ "$(wc -l <"$TMP/fuckup-log.jsonl" | tr -d ' ')" == "1" ]]; then
  pass "B09_AG3 positive validation not written as fuckup"
else
  fail "B09_AG3 positive validation not written as fuckup"
fi

skill_out="$(run_route skill --receipt .flywheel/validation-receipts/03-skill-extend.json --apply)"
assert_jq "$skill_out" '.results[0].action == "logged_fuckup"' "B09_AG7 skill-extension routing logs once"
if jq -e 'select(.source_event_id == "validation:kscr-skill" and .should_become == "skill")' "$TMP/fuckup-log.jsonl" >/dev/null; then
  pass "B09_AG7 skill-extension row marks should_become=skill"
else
  fail "B09_AG7 skill-extension row marks should_become=skill"
fi

promote_out="$(run_route promote --receipt .flywheel/validation-receipts/04-promote.json --apply)"
assert_jq "$promote_out" '.results[0].action == "logged_fuckup"' "B09_AG4 promote route enters L56 via fuckup-log"
if jq -e 'select(.source_event_id == "validation:kscr-promote" and .should_become == "rule" and .rule_violated_or_proven == "L56 fuckup-log -> INCIDENTS -> canonical L-rule promotion ladder")' "$TMP/fuckup-log.jsonl" >/dev/null; then
  pass "B09_AG4 recurring failure follows L56 ladder"
else
  fail "B09_AG4 recurring failure follows L56 ladder"
fi

assert_jq "$TMP/validation-learn-ledger.jsonl" 'select(.schema_version == "validation-learn-ledger/v1" and .dedupe_key == "kscr-failed")' "B09_AG1 ledger records learn_route enum"

post_review_out="$(run_route post-review --review)"
assert_jq "$post_review_out" '(.pending_validation_events | map(.dedupe_key) | index("kscr-failed") | not) and (.unrouted_validation_events | length) == 1' "B09_AG5 routed receipt removed from pending review"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
