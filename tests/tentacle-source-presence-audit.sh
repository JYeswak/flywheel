#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/tentacle-source-presence-audit.sh"
TMPDIR="$(mktemp -d -t tentacle-source-test.XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

mkdir -p "$TMPDIR/root/present_adopted" "$TMPDIR/root/present_eval"
cat >"$TMPDIR/manifest.json" <<'JSON'
[
  {"name":"present-adopted","repo":"present_adopted","adoption_status":"adopted","expected_path":"present_adopted"},
  {"name":"missing-adopted","repo":"missing_adopted","adoption_status":"adopted","expected_path":"missing_adopted"},
  {"name":"present-eval","repo":"present_eval","adoption_status":"evaluating","expected_path":"present_eval"},
  {"name":"missing-eval","repo":"missing_eval","adoption_status":"evaluating","expected_path":"missing_eval"}
]
JSON

bash -n "$SCRIPT"

"$SCRIPT" --schema >/dev/null
"$SCRIPT" --info >/dev/null
"$SCRIPT" --examples | jq -e '.examples | length >= 4' >/dev/null
"$SCRIPT" repair --dry-run --json | jq -e '.planned_actions == [] and .actual_actions == []' >/dev/null
"$SCRIPT" help exit-codes | rg -q 'exit codes'
"$SCRIPT" completion bash | rg -q 'tentacle-source-presence-audit'

json="$TMPDIR/audit.json"
"$SCRIPT" --root "$TMPDIR/root" --manifest "$TMPDIR/manifest.json" --json >"$json"

jq -e '
  .schema_version == "tentacle-source-presence-audit/v1" and
  .status == "warn" and
  .total == 4 and
  .source_present_count == 2 and
  .source_missing_count == 2 and
  .auto_clone_attempted == false
' "$json" >/dev/null || fail "summary mismatch"

jq -e '
  any(.rows[]; .name == "present-adopted" and .source_present == true and .route == "none") and
  any(.rows[]; .name == "missing-adopted" and .source_present == false and .route == "warn" and .route_reason == "surface_only_no_auto_clone_policy") and
  any(.rows[]; .name == "missing-eval" and .source_present == false and .route == "warn")
' "$json" >/dev/null || fail "row routing mismatch"

"$SCRIPT" validate --root "$TMPDIR/root" --manifest "$TMPDIR/manifest.json" --json \
  | jq -e '.validation == "pass" and .source_missing_count == 2' >/dev/null || fail "validation mismatch"

printf 'PASS tests/tentacle-source-presence-audit.sh\n'
