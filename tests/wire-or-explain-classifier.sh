#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="$ROOT/.flywheel/scripts/wire-or-explain-classifier.py"
FIXTURES="$ROOT/tests/fixtures/wire-or-explain-classifier"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/wire-or-explain-classifier.XXXXXX")"
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
    jq . "$file" || true
  fi
}

run_fixture() {
  local name="$1"
  "$BIN" classify --event "$FIXTURES/$name.json" --json >"$TMP/$name.out"
}

write_schema() {
  python3 -c '
import json
import sys
from pathlib import Path

required = [
    "schema_name", "schema_version", "identity_key", "timestamp", "session_id",
    "event_type", "actor", "target", "payload", "metadata", "prev_hash",
    "checksum", "sequence_num", "state", "producer", "owner", "consumer",
    "blocking_scope", "owning_orch", "ship_repo", "ship_actor",
    "artifact_class", "subject", "predicate", "branch_ref", "git_ref",
    "reset_intent_hash", "deferral_owner", "deferral_until",
    "auto_fire_trigger", "drain_receipt_shape", "verification_probe",
    "tick_status_consequence", "stock", "inflow", "action_ledger",
]
schema = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
    "required": required,
    "properties": {
        "schema_name": {"const": "flywheel.wire-or-explain.v1"},
        "artifact_class": {"type": "string"},
        "payload": {"type": "object"},
        "metadata": {"type": "object"},
    },
}
Path(sys.argv[1]).write_text(json.dumps(schema, sort_keys=True), encoding="utf-8")
' "$1"
}

python3 -m py_compile "$BIN" && pass "python_syntax" || fail "python_syntax"
"$BIN" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.name == "wire-or-explain-classifier" and .surface == "The Zest Press"' "info_surface_uses_zest_press"
"$BIN" doctor --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.status == "pass" and (.required_row_fields | index("artifact_class"))' "doctor_exposes_required_fields"

run_fixture script
assert_jq "$TMP/script.out" '.status == "pass" and .row.artifact_class == "finding" and .row.metadata.classifier_artifact_class == "script" and (.row.payload.evidence_root_hash | startswith("sha256:")) and (.row.metadata.action_ledger_pointer | length > 0)' "script_commit_classified"

run_fixture l_rule
assert_jq "$TMP/l_rule.out" '.row.artifact_class == "finding" and .row.metadata.classifier_artifact_class == "l_rule" and .row.consumer == "doctrine-3-surface-divergence-probe"' "l_rule_doctrine_classified"

run_fixture dispatch_template
assert_jq "$TMP/dispatch_template.out" '.row.artifact_class == "dispatch_packet" and .row.metadata.classifier_artifact_class == "dispatch_template" and .row.consumer == "dispatch-and-log"' "dispatch_template_classified"

run_fixture cli_surface
assert_jq "$TMP/cli_surface.out" '.row.artifact_class == "finding" and .row.metadata.classifier_artifact_class == "cli_surface" and (.row.verification_probe | test("CLI doctor"))' "doctor_status_cli_surface_classified"

run_fixture worker_branch
assert_jq "$TMP/worker_branch.out" '.row.artifact_class == "worker_branch" and .row.metadata.classifier_artifact_class == "worker_branch_artifact" and (.row.branch_ref | startswith("refs/workers/")) and (.row.payload.identity_proof_hash | startswith("sha256:"))' "worker_branch_records_ref_and_identity_hash"

run_fixture reset_guard
assert_jq "$TMP/reset_guard.out" '.row.artifact_class == "finding" and .row.metadata.classifier_artifact_class == "reset_guard_artifact" and (.row.reset_intent_hash | startswith("sha256:")) and .row.payload.orphan_commits == ["aaa111","bbb222","ccc333"]' "reset_guard_records_hash_and_sorted_orphans"

run_fixture jeff_corpus
assert_jq "$TMP/jeff_corpus.out" '.row.artifact_class == "finding" and .row.metadata.classifier_artifact_class == "jeff_corpus_consumer_path" and .row.consumer == "socraticode://jeff-corpus"' "jeff_consumer_path_classified"

run_fixture skill_candidate
assert_jq "$TMP/skill_candidate.out" '.row.artifact_class == "skill_candidate" and .row.state == "unwired" and .row.metadata.classifier_artifact_class == "skill_candidate" and (.row.consumer | test("skillos"))' "skill_candidate_routes_to_skillos"

run_fixture no_wire_required
assert_jq "$TMP/no_wire_required.out" '.row.artifact_class == "finding" and .row.metadata.classifier_artifact_class == "no_wire_required" and .row.state == "not_required" and .row.consumer != "NONE"' "no_wire_required_proof_classified"

"$BIN" classify --event "$FIXTURES/script.json" --json >"$TMP/script-again.out"
id1="$(jq -r '.row.metadata.row_identity' "$TMP/script.out")"
id2="$(jq -r '.row.metadata.row_identity' "$TMP/script-again.out")"
if [[ "$id1" == "$id2" ]]; then pass "stable_row_identity"; else fail "stable_row_identity"; fi

ledger="$TMP/ledger.jsonl"
"$BIN" classify --event "$FIXTURES/script.json" --ledger "$ledger" --apply --json >"$TMP/apply1.out"
"$BIN" classify --event "$FIXTURES/script.json" --ledger "$ledger" --apply --json >"$TMP/apply2.out"
line_count="$(wc -l <"$ledger" | tr -d ' ')"
if [[ "$line_count" == "1" ]]; then pass "idempotent_apply_no_duplicate_rows"; else fail "idempotent_apply_no_duplicate_rows"; fi
assert_jq "$TMP/apply2.out" '.status == "duplicate" and .appended == false' "duplicate_receipt_emitted"

set +e
"$BIN" classify --event "$FIXTURES/secret_evidence.json" --json >"$TMP/secret.out"
secret_rc=$?
set -e
if [[ "$secret_rc" == "1" ]]; then pass "secret_evidence_refused_rc"; else fail "secret_evidence_refused_rc"; fi
assert_jq "$TMP/secret.out" '.status == "refused" and .reason_code == "secret_looking_evidence" and .redaction_count >= 1 and (.row? | not)' "secret_evidence_redaction_counts_only"

schema="$TMP/b1-schema.json"
write_schema "$schema"
"$BIN" classify --event "$FIXTURES/script.json" --schema "$schema" --json >"$TMP/schema.out"
assert_jq "$TMP/schema.out" '.schema_validation.status == "passed"' "output_validates_against_b1_schema_shape"

if [[ -f "$ROOT/.flywheel/validation-schema/v1/wire-or-explain-ledger.schema.json" ]]; then
  "$BIN" classify --event "$FIXTURES/script.json" --schema "$ROOT/.flywheel/validation-schema/v1/wire-or-explain-ledger.schema.json" --json >"$TMP/live-schema.out"
  assert_jq "$TMP/live-schema.out" '.schema_validation.status == "passed"' "output_validates_against_live_f03_schema"
else
  pass "live_f03_schema_deferred_pending"
fi

tail -n 1 "$ROOT/.flywheel/wire-or-explain-classifier/README.md" | grep -qx 'Part of the Yuzu Method framework by ZestStream.' \
  && pass "readme_yuzu_footer" || fail "readme_yuzu_footer"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'FAILURES %s/%s\n' "$fail_count" "$((pass_count + fail_count))" >&2
  exit 1
fi

printf 'PASS wire-or-explain-classifier %s checks\n' "$pass_count"
