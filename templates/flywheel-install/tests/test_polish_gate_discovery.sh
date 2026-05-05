#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/polish-gate/discover-surfaces.py"
SHIM="$ROOT/polish-gate/discover-surfaces.sh"
SCHEMA="$ROOT/polish-gate/v1/discovery-output.schema.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/polish-gate-discovery.XXXXXX")"
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
    jq . "$file" >&2 || true
  fi
}

write_manifest() {
  local path="$1" scope="$2"
  mkdir -p "$(dirname "$path")"
  jq -n --arg scope "$scope" '{
    version:"1",
    mode:"audit_only",
    scope:$scope,
    legacy_bootstrap_policy:"warn_until_touched",
    blocking_when:["malformed_gate"],
    grade_storage:".flywheel/polish-gate/grades.jsonl",
    latest_summary:".flywheel/polish-gate/latest.json"
  }' >"$path"
}

repo="$TMP/alps-fixture"
manifest="$repo/.flywheel/polish-gate/manifest.json"
mkdir -p \
  "$repo/.flywheel/wire-or-explain-ledger" \
  "$repo/.flywheel/scripts" \
  "$repo/src/insurance-policies" \
  "$repo/scripts"
write_manifest "$manifest" repo_local_flywheel
printf '#!/usr/bin/env python3\nprint("ledger")\n' >"$repo/.flywheel/wire-or-explain-ledger/writer.py"
printf '#!/usr/bin/env bash\nexit 0\n' >"$repo/.flywheel/scripts/status-doctor.sh"
printf '# Flywheel docs\n' >"$repo/.flywheel/README.md"
printf 'class Policy: pass\n' >"$repo/src/insurance-policies/policy_model.py"
printf '#!/usr/bin/env python3\nprint("domain fetch")\n' >"$repo/scripts/fetch_run_log.py"
printf '# Root doctrine belongs to domain repo owner\n' >"$repo/AGENTS.md"
chmod +x "$repo/.flywheel/wire-or-explain-ledger/writer.py" "$repo/.flywheel/scripts/status-doctor.sh"

bash -n "$SHIM" && pass shim_syntax || fail shim_syntax
python3 -m py_compile "$SCRIPT" && pass python_syntax || fail python_syntax
python3 "$SCRIPT" --help | rg -q -- '--scope' && pass help_scope_flag || fail help_scope_flag

schema_out="$TMP/schema.json"
python3 "$SCRIPT" --schema >"$schema_out"
python3 -c '
import json
import sys
from jsonschema import Draft202012Validator
with open(sys.argv[1], encoding="utf-8") as handle:
    Draft202012Validator.check_schema(json.load(handle))
' "$schema_out"
pass schema_is_valid

out="$TMP/discovery.json"
python3 "$SCRIPT" --repo "$repo" --manifest "$manifest" --json >"$out"
python3 -c '
import json
import sys
from jsonschema import Draft202012Validator
with open(sys.argv[1], encoding="utf-8") as handle:
    schema = json.load(handle)
with open(sys.argv[2], encoding="utf-8") as handle:
    payload = json.load(handle)
Draft202012Validator(schema).validate(payload)
' "$SCHEMA" "$out"
pass json_validates_against_schema

assert_jq "$out" '.surfaces[] | select(.path == ".flywheel/wire-or-explain-ledger/writer.py" and .in_scope == true and .category == "cli-script")' "wave0_style_substrate_in_scope"
assert_jq "$out" '.scope_excluded[] | select(.path == "src/insurance-policies/policy_model.py")' "client_domain_code_excluded"
assert_jq "$out" 'all(.surfaces[]; (.path | startswith(".flywheel/")))' "alps_only_flywheel_in_scope"
assert_jq "$out" '.scope_excluded[] | select(.path == "scripts/fetch_run_log.py" and .reason == "root-domain-not-substrate")' "alps_root_domain_reason"

explain="$TMP/explain.txt"
python3 "$SCRIPT" --repo "$repo" --manifest "$manifest" --explain >"$explain"
if rg -q 'IN  \.flywheel/wire-or-explain-ledger/writer.py' "$explain" && rg -q 'OUT scripts/fetch_run_log.py reason=root-domain-not-substrate' "$explain"; then
  pass explain_surface_reasoning
else
  fail explain_surface_reasoning
  sed -n '1,120p' "$explain" >&2
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
