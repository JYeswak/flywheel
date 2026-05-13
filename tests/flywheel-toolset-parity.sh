#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_TOOLSET_PARITY_BIN:-$HOME/.local/bin/flywheel-toolset-parity}"
CHECKER="${CANONICAL_CLI_CHECKER:-<skills-root>/canonical-cli-scoping/scripts/check-cli-scoping.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/toolset-parity.XXXXXX")"
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

make_tool() {
  local dir="$TMP/bin"
  mkdir -p "$dir"
  for tool in dcg br ntm cm jsm; do
    cat >"$dir/$tool" <<SH
#!/usr/bin/env bash
case "\${1:-}" in
  --version) printf '$tool 1.0.0\n' ;;
  version) printf '$tool 1.0.0\n' ;;
  --help|help) printf '$tool help\n' ;;
  *) printf '$tool smoke\n' ;;
esac
SH
    chmod +x "$dir/$tool"
  done
  printf '%s\n' "$dir"
}

tool_dir="$(make_tool)"
export PATH="$tool_dir:$PATH"

python3 -m py_compile "$BIN" && pass "syntax"
"$BIN" --help >"$TMP/help.txt"
grep -q 'flywheel-toolset-parity' "$TMP/help.txt" && pass "help" || fail "help"

"$BIN" --info --json --state-dir "$TMP/state" >"$TMP/info.json"
assert_jq "$TMP/info.json" '.name == "flywheel-toolset-parity" and .version == "toolset-parity.v1"' "info_json"

"$BIN" --examples --json --state-dir "$TMP/state" >"$TMP/examples.json"
assert_jq "$TMP/examples.json" '(.examples | length) >= 4' "examples_json"

"$BIN" schema check --json --state-dir "$TMP/state" >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.schema_version == "toolset-parity.v1" and .command == "check"' "schema_json"
assert_jq "$TMP/schema.json" 'all(.runtime_matrix[]; .proof_level == "schema_only" and .evidence_path and .probe_command and .owner_bead)' "schema_only_runtime_matrix"

"$BIN" --schema --json --state-dir "$TMP/state" >"$TMP/schema-flag.json"
assert_jq "$TMP/schema-flag.json" '.schema_version == "toolset-parity.v1" and .command == "check"' "schema_flag_json"

"$BIN" doctor --json --state-dir "$TMP/state" >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.command == "doctor" and (.paths.state_dir | test("toolset-parity"))' "doctor_json"
assert_jq "$TMP/doctor.json" '.runtime_proof_counts.claude.unavailable == 1 and .runtime_proof_counts.codex.unavailable == 1 and (.warnings[] | select(.code == "missing_runtime_evidence" and .runtime == "claude"))' "doctor_missing_runtime_evidence"

"$BIN" health --json --state-dir "$TMP/state" >"$TMP/health.json"
assert_jq "$TMP/health.json" '.command == "health" and .status == "pass"' "health_json"

"$BIN" repair --scope state --dry-run --json --state-dir "$TMP/state" >"$TMP/repair.json"
assert_jq "$TMP/repair.json" '.command == "repair" and .mode == "dry_run" and (.would_write | length) == 1' "repair_dry_run"

"$BIN" check --runtime=claude --json --state-dir "$TMP/state" >"$TMP/claude.json"
assert_jq "$TMP/claude.json" '.status == "uniform" and (.matrix | length) == 5 and all(.matrix[]; .found == true and .smoke_ok == true and .runtime == "claude") and (.output_path | test("toolset-parity-"))' "claude_matrix"
assert_jq "$TMP/claude.json" '.runtime_matrix[] | select(.runtime == "claude" and .proof_level == "runtime_verified" and .evidence_path and .probe_command and .owner_bead == "flywheel-8qix")' "claude_runtime_verified"

jq -nc \
  --arg dcg "$tool_dir/dcg" \
  --arg br "$tool_dir/br" \
  --arg ntm "$tool_dir/ntm" \
  --arg cm "$tool_dir/cm" \
  --arg jsm "$tool_dir/jsm" \
  '{runtime:"codex",status:"responsive",cells:[
    {tool:"dcg",found:true,abs_path:$dcg,version:"dcg 1.0.0",smoke_ok:true},
    {tool:"br",found:true,abs_path:$br,version:"br 1.0.0",smoke_ok:true},
    {tool:"ntm",found:true,abs_path:$ntm,version:"ntm 1.0.0",smoke_ok:true},
    {tool:"cm",found:true,abs_path:$cm,version:"cm 1.0.0",smoke_ok:true},
    {tool:"jsm",found:true,abs_path:$jsm,version:"jsm 1.0.0",smoke_ok:true}
  ]}' | sed 's/^/TOOLSET_PARITY_RESULT /' >"$TMP/codex-callback.json"

"$BIN" check --runtime=codex --codex-callback-ref "$TMP/codex-callback.json" --json --state-dir "$TMP/state" >"$TMP/codex.json"
assert_jq "$TMP/codex.json" '.status == "uniform" and (.matrix | length) == 5 and all(.matrix[]; .runtime == "codex" and .smoke_ok == true)' "codex_callback_matrix"
assert_jq "$TMP/codex.json" '.runtime_matrix[] | select(.runtime == "codex" and .proof_level == "fixture_verified" and .evidence_path and .probe_command and .owner_bead == "flywheel-8qix")' "codex_fixture_verified"

cat >"$TMP/fake-ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  send) exit 0 ;;
  logs) printf 'no callback yet\n'; exit 0 ;;
  *) printf '{}\n' ;;
esac
SH
chmod +x "$TMP/fake-ntm"
set +e
"$BIN" check --runtime=codex --ntm "$TMP/fake-ntm" --timeout 1 --json --state-dir "$TMP/state" >"$TMP/unresponsive.json"
unresponsive_rc=$?
set -e
if [[ "$unresponsive_rc" -eq 3 ]]; then pass "unresponsive_exit_3"; else fail "unresponsive_exit_3"; fi
assert_jq "$TMP/unresponsive.json" '.status == "unreachable_runtime" and (.failure_classes | index("runtime_unresponsive")) and all(.matrix[]; .status == "runtime_unresponsive")' "unresponsive_matrix"
assert_jq "$TMP/unresponsive.json" '.runtime_matrix[] | select(.runtime == "codex" and .proof_level == "unavailable")' "codex_unavailable_proof"

cat >"$TMP/runtime-claims.json" <<'JSON'
[
  {
    "runtime": "claude",
    "proof_level": "schema_only",
    "active_runtime": true,
    "generated_at": "2026-05-01T00:00:00Z",
    "evidence_path": "/tmp/schema-only.json",
    "probe_command": "schema check --json",
    "owner_bead": "fixture-schema"
  },
  {
    "runtime": "gemini",
    "proof_level": "unsupported",
    "active_runtime": false,
    "generated_at": "2026-05-08T00:00:00Z",
    "evidence_path": "/tmp/gemini.json",
    "probe_command": "unsupported runtime fixture",
    "owner_bead": "fixture-unsupported"
  }
]
JSON
"$BIN" doctor --json --state-dir "$TMP/claims-state" --claims-file "$TMP/runtime-claims.json" --now "2026-05-08T12:00:00Z" --stale-hours 24 >"$TMP/claims-doctor.json"
assert_jq "$TMP/claims-doctor.json" '.runtime_proof_counts.claude.schema_only == 1 and .runtime_proof_counts.gemini.unsupported == 1' "doctor_counts_by_runtime_and_proof"
assert_jq "$TMP/claims-doctor.json" '.runtime_matrix[] | select(.runtime == "gemini" and .proof_level == "unsupported" and .evidence_path and .probe_command and .owner_bead == "fixture-unsupported")' "unsupported_runtime_row"
assert_jq "$TMP/claims-doctor.json" '.warnings[] | select(.code == "active_runtime_below_runtime_verified_stale" and .runtime == "claude" and .proof_level == "schema_only")' "stale_schema_only_warning"

"$BIN" completion bash >"$TMP/completion.bash"
grep -q 'complete -W' "$TMP/completion.bash" && pass "completion_bash" || fail "completion_bash"

bash "$CHECKER" "$BIN" >"$TMP/checker.txt"
grep -q 'Summary: 4 pass, 0 fail' "$TMP/checker.txt" && pass "canonical_checker" || fail "canonical_checker"

printf 'SUMMARY pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
