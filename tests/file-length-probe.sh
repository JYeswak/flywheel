#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/file-length-probe.sh"
PROMOTE="$ROOT/.flywheel/scripts/doctor-signal-bead-promotion.sh"
BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/file-length-probe-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

make_lines() {
  local count="$1" text="$2"
  awk -v n="$count" -v text="$text" 'BEGIN { for (i = 0; i < n; i++) print text }'
}

repo="$TMP/repo"
mkdir -p "$repo/scripts" "$repo/src" "$repo/docs" "$repo/.flywheel/scripts"
git -C "$repo" init -q >/dev/null 2>&1
printf '# Mission\n\nstatus: ready\n' >"$repo/.flywheel/MISSION.md"
printf '# Goal\n\nstatus: ready\n' >"$repo/.flywheel/GOAL.md"
printf '# State\n\nstatus: ready\n' >"$repo/.flywheel/STATE.md"
cp "$PROBE" "$repo/.flywheel/scripts/file-length-probe.sh"
chmod +x "$repo/.flywheel/scripts/file-length-probe.sh"

{
  printf '#!/usr/bin/env bash\n'
  make_lines 500 'printf "%s\n" ok'
} >"$repo/scripts/bash-over.sh"

{
  printf 'from __future__ import annotations\n'
  make_lines 400 'print("ok")'
} >"$repo/src/python_over.py"

{
  printf 'fn main() {}\n'
  make_lines 500 '// rust fixture'
} >"$repo/src/rust_over.rs"

{
  printf '# canonical-cli-scoping-allow-large: generated shell fixture\n'
  make_lines 700 'echo allowed'
} >"$repo/scripts/allowed-override.sh"

{
  printf '<!-- canonical-cli-scoping-allow-large: doctrine archive fixture -->\n'
  make_lines 1600 'doctrine line'
} >"$repo/docs/doctrine-markdown-allowed.md"

bash -n "$PROBE" && pass "probe_syntax" || fail "probe_syntax"
"$PROBE" --repo "$repo" --json >"$TMP/probe.json"

assert_jq "$TMP/probe.json" '.schema_version == "file-length-probe/v1"' "schema_version"
assert_jq "$TMP/probe.json" '.oversized_files_count == 3' "oversized_count_excludes_allowed"
assert_jq "$TMP/probe.json" '[.oversized_files[].path] | sort == ["scripts/bash-over.sh","src/python_over.py","src/rust_over.rs"]' "language_threshold_fixtures"
assert_jq "$TMP/probe.json" '.allowed_oversized_files_count == 2' "allowed_override_count"
assert_jq "$TMP/probe.json" 'any(.allowed_oversized_files[]; .path == "docs/doctrine-markdown-allowed.md" and .language == "markdown")' "doctrine_markdown_allowed"
assert_jq "$TMP/probe.json" '.thresholds == {bash:500,python:400,rust:500,markdown:1500}' "threshold_contract"

FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 FLYWHEEL_FILE_LENGTH_INCLUDE_LOOP_BIN=0 "$BIN" doctor --repo "$repo" --json >"$TMP/doctor.json" 2>"$TMP/doctor.err" || true
assert_jq "$TMP/doctor.json" '.oversized_files_count == 3 and (.oversized_files | length) == 3 and (.file_length.allowed_oversized_files_count == 2)' "flywheel_loop_doctor_file_length_fields"

fake_br="$TMP/br"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'case "$1" in' \
  '  list) printf "{\"issues\":[]}\\n" ;;' \
  '  show) printf "[]\\n" ;;' \
  '  create) printf "{\"id\":\"flywheel-monolith-fixture\"}\\n" ;;' \
  '  update) printf "{\"id\":\"updated\"}\\n" ;;' \
  '  *) printf "{}\\n" ;;' \
  'esac' >"$fake_br"
chmod +x "$fake_br"

doctor_json="$(jq -nc --slurpfile file_length "$TMP/probe.json" '{status:"warn",oversized_files_count:4,file_length:$file_length[0]}')"
BR_BIN="$fake_br" DOCTOR_SIGNAL_DOCTOR_JSON="$doctor_json" "$PROMOTE" "$repo" >"$TMP/promote.out"
assert_jq "$TMP/promote.out" '.actions[]? | test("monolithic_file_debt")' "doctor_promotion_monolithic_file_debt"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
