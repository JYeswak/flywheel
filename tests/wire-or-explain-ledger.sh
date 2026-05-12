#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/wire-or-explain-ledger.schema.json"
WRITER="$ROOT/.flywheel/scripts/wire-or-explain-ledger-writer.sh"
VERIFIER="$ROOT/.flywheel/scripts/wire-or-explain-chain-verifier.sh"
FIXTURES="$ROOT/tests/fixtures/wire-or-explain-ledger"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

validate_json() {
  python3 - "$SCHEMA" "$1" <<'PY'
import json
import sys
import jsonschema

schema_path, row_path = sys.argv[1], sys.argv[2]
with open(schema_path, "r", encoding="utf-8") as fh:
    schema = json.load(fh)
with open(row_path, "r", encoding="utf-8") as fh:
    row = json.load(fh)
jsonschema.Draft202012Validator(schema).validate(row)
PY
}

reject_json() {
  if validate_json "$1" >/dev/null 2>&1; then
    printf 'expected schema rejection for %s\n' "$1" >&2
    exit 1
  fi
}

jq -e '.schema_name=="flywheel.wire-or-explain.v1"' "$SCHEMA" >/dev/null

for fixture in \
  "$FIXTURES/valid-wired.json" \
  "$FIXTURES/valid-deferred.json" \
  "$FIXTURES/valid-unwired.json" \
  "$FIXTURES/valid-questionably-wired.json" \
  "$FIXTURES/valid-not-required.json" \
  "$FIXTURES/valid-bypassed.json" \
  "$FIXTURES/valid-skill-candidate.json" \
  "$FIXTURES/valid-worker-branch.json"; do
  validate_json "$fixture"
done

for field in artifact_class consumer owner verification_probe tick_status_consequence; do
  invalid="$TMPDIR/missing-$field.json"
  jq "del(.$field)" "$FIXTURES/valid-wired.json" > "$invalid"
  reject_json "$invalid"
done

for field in branch_ref git_ref reset_intent_hash; do
  invalid="$TMPDIR/worker-branch-missing-$field.json"
  jq "del(.$field)" "$FIXTURES/valid-worker-branch.json" > "$invalid"
  reject_json "$invalid"
done

ledger="$TMPDIR/zest-ledger.jsonl"
first_receipt="$TMPDIR/first-receipt.json"
second_receipt="$TMPDIR/second-receipt.json"
duplicate_receipt="$TMPDIR/duplicate-receipt.json"

bash "$WRITER" --row "$FIXTURES/valid-wired.json" --ledger "$ledger" --json > "$first_receipt"
bash "$WRITER" --row "$FIXTURES/valid-deferred.json" --ledger "$ledger" --json > "$second_receipt"
bash "$WRITER" --row "$FIXTURES/valid-wired.json" --ledger "$ledger" --json > "$duplicate_receipt"

jq -e '.status=="appended" and .ledger_written==true and .sequence_num==1' "$first_receipt" >/dev/null
jq -e '.status=="appended" and .ledger_written==true and .sequence_num==2' "$second_receipt" >/dev/null
jq -e '.status=="duplicate" and .ledger_written==false and .duplicate_of_sequence_num==1' "$duplicate_receipt" >/dev/null
test "$(wc -l "$ledger" | awk '{print $1}')" = "2"

python3 - "$ledger" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    rows = [json.loads(line) for line in fh if line.strip()]
assert rows[0]["sequence_num"] == 1
assert rows[0]["prev_hash"] == "0" * 64
assert len(rows[0]["checksum"]) == 64
assert rows[1]["sequence_num"] == 2
assert rows[1]["prev_hash"] == rows[0]["checksum"]
PY

bash "$VERIFIER" --ledger "$ledger" --json | jq -e '.status=="pass" and .row_count==2 and .tampered_count==0' >/dev/null

tampered="$TMPDIR/tampered.jsonl"
python3 - "$ledger" "$tampered" <<'PY'
import json
import sys

src, dst = sys.argv[1], sys.argv[2]
with open(src, "r", encoding="utf-8") as fh:
    rows = [json.loads(line) for line in fh if line.strip()]
rows[0]["payload"]["evidence_output_hash"] = "SECRET_FIXTURE_VALUE"
with open(dst, "w", encoding="utf-8") as fh:
    for row in rows:
        fh.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")
PY

set +e
tamper_output="$(bash "$VERIFIER" --ledger "$tampered" --json 2>&1)"
tamper_status=$?
set -e
test "$tamper_status" -eq 1
printf '%s\n' "$tamper_output" | jq -e '.status=="fail" and .tampered_count>=1' >/dev/null
if printf '%s\n' "$tamper_output" | grep -q 'SECRET_FIXTURE_VALUE'; then
  printf 'verifier leaked tampered payload value\n' >&2
  exit 1
fi

python3 - "$ledger" <<'PY'
import json
import sys
from collections import defaultdict

rebuilt = defaultdict(int)
with open(sys.argv[1], "r", encoding="utf-8") as fh:
    for line in fh:
        row = json.loads(line)
        rebuilt[(row["state"], row["artifact_class"])] += 1
assert sum(rebuilt.values()) == 2
assert rebuilt[("wired", "finding")] == 1
assert rebuilt[("deferred", "finding")] == 1
PY

jq -e '.artifact_class=="skill_candidate" and .event_type=="feedback_fuckup_finding"' "$FIXTURES/valid-skill-candidate.json" >/dev/null

echo OK_wire_or_explain_ledger
