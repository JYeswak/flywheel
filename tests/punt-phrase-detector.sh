#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/punt-phrase-detector.py"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/punt-phrase-detector.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail() { printf 'FAIL %s\n' "$1" >&2; exit 1; }
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then pass "$label"; else jq . "$file" >&2 || true; fail "$label"; fi
}

repo="$TMP/repo"
mkdir -p "$repo/.flywheel/handoffs"
cat >"$repo/.flywheel/dispatch-log.jsonl" <<'JSONL'
{"ts":"2026-05-09T00:00:00Z","session":"flywheel:1","message":"want me to dispatch flywheel-p0?"}
JSONL
cat >"$repo/.flywheel/handoffs/handoff.md" <<'MD'
# Handoff

Let me know if you want me to continue.
MD

python3 -m py_compile "$SCRIPT" && pass "python_compile"
"$SCRIPT" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.forbidden_phrase_catalog_count == 17 and .event_schema == "flywheel.l70_punt_event.v1"' "info_contract"
"$SCRIPT" doctor --repo "$repo" --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.status == "ok" and .subsystems.phrase_catalog.count == 17' "doctor_contract"
"$SCRIPT" scan --repo "$repo" --json >"$TMP/scan.json"
assert_jq "$TMP/scan.json" '.status == "dry_run" and .matches_found == 4 and .rows_written == 0' "scan_detects_punts"
"$SCRIPT" --ledger "$TMP/ledger.jsonl" scan --repo "$repo" --apply --json >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '.status == "applied" and .rows_written == 4' "scan_apply_writes"
test "$(wc -l <"$TMP/ledger.jsonl" | tr -d ' ')" = "4" || fail "ledger_row_count"
"$SCRIPT" --ledger "$TMP/ledger.jsonl" report --top-phrases --json >"$TMP/report.json"
assert_jq "$TMP/report.json" '.event_count == 4 and (.top_phrases | length) >= 3' "report_summarizes"

printf 'RESULT pass=%s\n' "$pass_count"
