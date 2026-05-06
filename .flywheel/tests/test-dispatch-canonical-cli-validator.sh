#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/dispatch-canonical-cli-validator.sh"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/dispatch-canonical-cli-decision.schema.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dispatch-canonical-cli-validator.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
outputs=()

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

schema_validate() {
  python3 - "$SCHEMA" "$1" <<'PY'
import json
import sys
from pathlib import Path
from jsonschema import Draft202012Validator

schema = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
payload = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
Draft202012Validator.check_schema(schema)
Draft202012Validator(schema, format_checker=Draft202012Validator.FORMAT_CHECKER).validate(payload)
PY
}

write_complete_dispatch() {
  local path="$1"
  cat >"$path" <<'EOF'
# DISPATCH: fixture canonical CLI

## Required artifacts

Path: `.flywheel/scripts/fixture-cli.sh`

CLI shape:
```
fixture-cli.sh check --dispatch-file <path> [--json]
fixture-cli.sh --info|--help|--examples
```

JSON output: `--json` emits a machine-readable decision object.

Stable exit-code semantics:
- 0=allow
- 1=refuse
- 2=usage or malformed dispatch fail-open

## Acceptance gates

- Cite `~/.claude/skills/canonical-cli-scoping/SKILL.md`.
- Skills consulted: canonical-cli-scoping.
EOF
}

run_file_case() {
  local label="$1" file="$2" expected_rc="$3" jq_filter="$4" out rc
  out="$TMP/${label// /_}.json"
  set +e
  DISPATCH_CANONICAL_CLI_LEDGER="$TMP/ledger.jsonl" "$SCRIPT" check --dispatch-file "$file" --json >"$out" 2>"$out.err"
  rc=$?
  set -e
  outputs+=("$out")
  if [[ "$rc" == "$expected_rc" ]] && jq -e "$jq_filter" "$out" >/dev/null && schema_validate "$out"; then
    pass "$label"
  else
    fail "$label"
    printf 'rc=%s expected=%s stderr=%s\n' "$rc" "$expected_rc" "$(cat "$out.err")" >&2
    jq . "$out" >&2 || cat "$out" >&2
  fi
}

command -v jq >/dev/null 2>&1 || { fail "missing jq"; exit 1; }
bash -n "$SCRIPT"
"$SCRIPT" --help | grep -q 'Exit codes:'
"$SCRIPT" --examples | grep -q -- '--dispatch-file'
"$SCRIPT" --info | jq -e '.name == "dispatch-canonical-cli-validator.sh" and .exit_codes."0" == "allow"' >/dev/null
pass "script meta surfaces"

complete="$TMP/complete.md"
write_complete_dispatch "$complete"
run_file_case "allow CLI complete" "$complete" 0 '.decision == "allow" and .introduces_cli == true and .missing_elements == []'

missing_info="$TMP/missing-info.md"
sed '/--info|--help|--examples/d' "$complete" >"$missing_info"
run_file_case "refuse missing info help examples" "$missing_info" 1 '.decision == "refuse" and (.missing_elements | index("info_help_examples"))'

missing_json="$TMP/missing-json.md"
sed '/JSON output/d; s/ \\[--json\\]//' "$complete" >"$missing_json"
run_file_case "refuse missing json" "$missing_json" 1 '.decision == "refuse" and (.missing_elements | index("json"))'

missing_exit="$TMP/missing-exit.md"
sed '/Stable exit-code semantics:/,/^$/d' "$complete" >"$missing_exit"
run_file_case "refuse missing exit codes" "$missing_exit" 1 '.decision == "refuse" and (.missing_elements | index("exit_codes"))'

missing_skill="$TMP/missing-skill.md"
sed '/canonical-cli-scoping/d' "$complete" >"$missing_skill"
run_file_case "refuse missing canonical skill" "$missing_skill" 1 '.decision == "refuse" and (.missing_elements | index("canonical_cli_skill"))'

not_cli="$TMP/not-cli.md"
cat >"$not_cli" <<'EOF'
# DISPATCH: fixture docs only

## Required artifacts

Path: `MISSION.md`
EOF
run_file_case "allow non CLI dispatch" "$not_cli" 0 '.decision == "allow" and .introduces_cli == false and .reason == "not_introducing_cli"'

malformed="$TMP/malformed.md"
printf 'short body\n' >"$malformed"
run_file_case "malformed fail open" "$malformed" 2 '.decision == "allow" and .reason == "malformed_dispatch_packet_fail_open"'

ledger_rows="$(wc -l <"$TMP/ledger.jsonl" | tr -d ' ')"
if [[ "$ledger_rows" == "7" ]]; then
  for output in "${outputs[@]}"; do schema_validate "$output"; done
  pass "ledger rows and JSON schema"
else
  fail "ledger rows and JSON schema"
  cat "$TMP/ledger.jsonl" >&2 || true
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$pass_count" == "9" && "$fail_count" == "0" ]]
