#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/system-inventory.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/system-inventory-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

repo="$TMP/sample-repo"
mkdir -p "$repo/scripts" "$repo/tests" "$repo/.flywheel"

cat >"$repo/scripts/sample-cli.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  doctor) printf '{"status":"pass"}\n' ;;
  validate) printf '{"valid":true}\n' ;;
  *) printf 'usage\n' ;;
esac
SH
chmod +x "$repo/scripts/sample-cli.sh"

cat >"$repo/tests/sample-test.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf 'PASS fixture\n'
SH
chmod +x "$repo/tests/sample-test.sh"

jq -nc '{ts:"2026-05-19T00:00:00Z",task_id:"fixture",task_file:"scripts/sample-cli.sh"}' >"$repo/.flywheel/dispatch-log.jsonl"

"$SCRIPT" --json --repo sample="$repo" >"$TMP/first.jsonl"
"$SCRIPT" --json --repo sample="$repo" >"$TMP/second.jsonl"

if cmp -s "$TMP/first.jsonl" "$TMP/second.jsonl"; then
  pass "json_rerun_idempotent"
else
  fail "json_rerun_idempotent"
fi

row_count="$(wc -l <"$TMP/first.jsonl" | tr -d ' ')"
if [[ "$row_count" -ge 1 ]]; then
  pass "emits_surface_rows"
else
  fail "emits_surface_rows"
fi

jq -e 'select(.repo=="sample" and .path=="scripts/sample-cli.sh" and .exec_bit==true and (.class=="doctor" or .class=="CLI") and .language=="bash" and .lines > 0 and .tier)' "$TMP/first.jsonl" >/dev/null \
  && pass "sample_cli_row_shape" || { fail "sample_cli_row_shape"; cat "$TMP/first.jsonl" >&2; }

out_dir="$TMP/out"
"$SCRIPT" --write-report --output-dir "$out_dir" --repo sample="$repo" >/dev/null
[[ -s "$out_dir/inventory.jsonl" && -s "$out_dir/SYSTEM-INVENTORY.md" ]] \
  && pass "write_report_outputs" || fail "write_report_outputs"

grep -q 'Next action:' "$out_dir/SYSTEM-INVENTORY.md" \
  && pass "summary_prints_next_action" || fail "summary_prints_next_action"

printf 'SUMMARY pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$fail_count" == "0" ]]
