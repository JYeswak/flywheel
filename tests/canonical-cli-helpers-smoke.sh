#!/usr/bin/env bash
# tests/canonical-cli-helpers-smoke.sh
#
# AG4 for flywheel-tiugg: exercise every helper in
# .flywheel/lib/canonical-cli-helpers.sh and assert correct behavior.
#
# Asserts:
#   1. cli_iso_now returns ISO-8601 UTC timestamp
#   2. cli_sha_self returns sha256 of supplied script
#   3. cli_audit_append with empty extra_json produces single-row JSONL
#   4. cli_audit_append with valid extra_json merges keys
#   5. cli_audit_append with bad extra_json silently falls back to {}
#   6. cli_refuse_apply_without_idem_key exits 3 with refusal envelope
#   7. cli_dispatch_subcommand_help --help fires + exits 0
#   8. cli_dispatch_subcommand_help with no --help returns 0 (caller proceeds)
#   9. cli_emit_info envelope has all required fields
#  10. cli_emit_examples wraps newline-delimited JSON correctly
#  11. cli_emit_quickstart wraps steps + next_actions
#  12. cli_emit_completion_bash produces parsable bash
#  13. cli_emit_completion_zsh produces #compdef-headed zsh
#  14. cli_emit_topic_help with empty topic lists topics
#  15. cli_emit_topic_help with known topic prints body
#  16. cli_emit_topic_help with unknown topic falls back to topic list

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
LIB="$ROOT/.flywheel/lib/canonical-cli-helpers.sh"
[[ -r "$LIB" ]] || { echo "FAIL: lib missing: $LIB" >&2; exit 1; }

# shellcheck source=/dev/null
source "$LIB"

TMP="$(mktemp -d -t canonical-cli-helpers-smoke.XXXXXX)"
trap 'find "$TMP" -mindepth 1 -delete 2>/dev/null; rmdir "$TMP" 2>/dev/null || true' EXIT

fail=0
report_fail() { echo "FAIL[$1]: $2" >&2; fail=$((fail+1)); }
pass()        { echo "PASS[$1]: $2"; }

# (1) cli_iso_now
ts="$(cli_iso_now)"
if [[ "$ts" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
  pass 1 "cli_iso_now=$ts"
else
  report_fail 1 "cli_iso_now bad format: $ts"
fi

# (2) cli_sha_self
sha="$(cli_sha_self "$LIB")"
if [[ "$sha" =~ ^[0-9a-f]{64}$ ]]; then
  pass 2 "cli_sha_self len=64"
else
  report_fail 2 "cli_sha_self returned: $sha"
fi

# (3) cli_audit_append with empty extra
log="$TMP/audit.jsonl"
cli_audit_append "$log" "smoke" "ok" ""
rows="$(wc -l < "$log" | tr -d ' ')"
[[ "$rows" -eq 1 ]] || report_fail 3 "expected 1 row got $rows"
jq -e '.action == "smoke" and .status == "ok"' "$log" >/dev/null \
  || report_fail 3 "row missing action/status"
pass 3 "cli_audit_append empty extra rows=$rows"

# (4) cli_audit_append merges valid extra_json
cli_audit_append "$log" "smoke2" "ok" '{"foo":"bar","n":3}'
last="$(tail -1 "$log")"
echo "$last" | jq -e '.foo == "bar" and .n == 3 and .action == "smoke2"' >/dev/null \
  || report_fail 4 "extra_json keys not merged: $last"
pass 4 "cli_audit_append merged extra_json"

# (5) cli_audit_append bad JSON falls back to {}
cli_audit_append "$log" "smoke3" "ok" '{not:json}'
last="$(tail -1 "$log")"
echo "$last" | jq -e '.action == "smoke3" and (has("not") | not)' >/dev/null \
  || report_fail 5 "bad JSON did not fall back to {}: $last"
pass 5 "cli_audit_append bad JSON fallback ok"

# (6) cli_refuse_apply_without_idem_key
set +e
out="$(bash -c "source '$LIB'; cli_refuse_apply_without_idem_key 'foo.repair/v1' repair state" 2>&1)"
rc=$?
set -e
[[ "$rc" -eq 3 ]] || report_fail 6 "expected exit 3 got $rc"
echo "$out" | jq -e '.status == "refused" and .mode == "apply" and .scope == "state" and .reason == "--apply requires --idempotency-key"' >/dev/null \
  || report_fail 6 "refusal envelope shape: $out"
pass 6 "cli_refuse_apply_without_idem_key rc=3 envelope ok"

# (7) cli_dispatch_subcommand_help fires --help
fired_marker="$TMP/fired"
fake_help() { touch "$fired_marker"; printf 'fake-help\n'; }
set +e
help_out="$(bash -c "source '$LIB'; fake_help() { touch '$fired_marker'; printf 'fake-help\n'; }; cli_dispatch_subcommand_help fake_help --help; printf 'after\n'")"
help_rc=$?
set -e
[[ "$help_rc" -eq 0 ]] || report_fail 7 "dispatch_subcommand_help --help rc=$help_rc"
[[ -f "$fired_marker" ]] || report_fail 7 "topic help function did not fire"
echo "$help_out" | grep -q "fake-help" || report_fail 7 "topic help not in output"
echo "$help_out" | grep -q "after" && report_fail 7 "dispatch did not exit 0; 'after' printed"
pass 7 "cli_dispatch_subcommand_help fired and exited"

# (8) cli_dispatch_subcommand_help returns 0 with no --help
no_help_marker="$TMP/no-help-fired"
set +e
nohelp_out="$(bash -c "source '$LIB'; fake_help() { touch '$no_help_marker'; }; cli_dispatch_subcommand_help fake_help --foo bar; printf 'after\n'")"
nohelp_rc=$?
set -e
[[ "$nohelp_rc" -eq 0 ]] || report_fail 8 "no-help path rc=$nohelp_rc"
[[ -f "$no_help_marker" ]] && report_fail 8 "topic fn fired when it should not have"
echo "$nohelp_out" | grep -q "after" || report_fail 8 "caller did not proceed past dispatch"
pass 8 "cli_dispatch_subcommand_help returned for non-help args"

# (9) cli_emit_info
info="$(cli_emit_info "smoke.sh" "0.1.0" "smoke.info/v1" "run,doctor,health" "FOO,BAR" '{"audit_log":"/tmp/x"}')"
echo "$info" | jq -e '
  .schema_version == "smoke.info/v1"
  and .name == "smoke.sh"
  and .version == "0.1.0"
  and (.subcommands | length == 3)
  and (.env_vars | length == 2)
  and (.paths.audit_log == "/tmp/x")
  and (.canonical_cli_surfaces | length == 12)
' >/dev/null || report_fail 9 "info envelope shape: $info"
pass 9 "cli_emit_info envelope ok"

# (10) cli_emit_examples
examples_in='{"name":"a","invocation":"x","purpose":"p"}
{"name":"b","invocation":"y","purpose":"q"}'
examples_out="$(cli_emit_examples "smoke.examples/v1" "$examples_in")"
echo "$examples_out" | jq -e '.schema_version == "smoke.examples/v1" and (.examples | length == 2) and .examples[0].name == "a"' >/dev/null \
  || report_fail 10 "examples envelope: $examples_out"
pass 10 "cli_emit_examples envelope ok"

# (11) cli_emit_quickstart
steps_in='{"step":1,"action":"probe","command":"smoke doctor"}
{"step":2,"action":"run","command":"smoke run"}'
qs_out="$(cli_emit_quickstart "smoke.quickstart/v1" "$steps_in" "first,second")"
echo "$qs_out" | jq -e '.steps | length == 2' >/dev/null \
  || report_fail 11 "quickstart steps: $qs_out"
echo "$qs_out" | jq -e '.next_actions | length == 2 and .[0] == "first"' >/dev/null \
  || report_fail 11 "quickstart next_actions: $qs_out"
pass 11 "cli_emit_quickstart envelope ok"

# (12) cli_emit_completion_bash
bash_completion="$(cli_emit_completion_bash "smoke" "run,doctor" "--json,--help")"
echo "$bash_completion" | bash -n - 2>/dev/null \
  || report_fail 12 "bash completion failed bash -n"
echo "$bash_completion" | grep -q "^complete -F _smoke_completion smoke" \
  || report_fail 12 "bash completion missing complete -F line"
pass 12 "cli_emit_completion_bash parses with bash -n"

# (13) cli_emit_completion_zsh
zsh_completion="$(cli_emit_completion_zsh "smoke" "run,doctor")"
echo "$zsh_completion" | head -1 | grep -q "^#compdef smoke" \
  || report_fail 13 "zsh completion missing #compdef header"
echo "$zsh_completion" | grep -q "compdef _smoke smoke" \
  || report_fail 13 "zsh compdef binding missing"
pass 13 "cli_emit_completion_zsh has #compdef + compdef binding"

# (14) cli_emit_topic_help with empty topic
topic_map="$TMP/topics.json"
cat > "$topic_map" <<'JSON'
{"run":"run topic body","doctor":"doctor topic body","help":"meta-help body"}
JSON
empty_out="$(cli_emit_topic_help "" "$topic_map")"
echo "$empty_out" | grep -q "Topics:" \
  || report_fail 14 "empty-topic output missing Topics: prefix"
pass 14 "cli_emit_topic_help empty-topic lists topics"

# (15) cli_emit_topic_help with known topic
known_out="$(cli_emit_topic_help "doctor" "$topic_map")"
[[ "$known_out" == "doctor topic body" ]] \
  || report_fail 15 "known topic body mismatch: $known_out"
pass 15 "cli_emit_topic_help known topic prints body"

# (16) cli_emit_topic_help with unknown topic falls back to topic list
unknown_out="$(cli_emit_topic_help "nope" "$topic_map")"
echo "$unknown_out" | grep -q "Unknown topic" \
  || report_fail 16 "unknown-topic output missing fallback prefix: $unknown_out"
pass 16 "cli_emit_topic_help unknown topic falls back"

# --- jloib.0d-followup helpers (b9dfv) ---

# (17) cli_emit_schema_dispatch known surface
schema_map="$TMP/schema-map.json"
cat > "$schema_map" <<'JSON'
{
  "run": {"schema_version":"smoke.run/v1","command":"run","required":["x"]},
  "doctor": {"schema_version":"smoke.doctor/v1","command":"doctor","required":["status"]}
}
JSON
out_run="$(cli_emit_schema_dispatch run "$schema_map")"
echo "$out_run" | jq -e '.schema_version == "smoke.run/v1" and .command == "run"' >/dev/null \
  || report_fail 17 "schema dispatch run: $out_run"
pass 17 "cli_emit_schema_dispatch run"

# (18) cli_emit_schema_dispatch default falls back to run
out_default="$(cli_emit_schema_dispatch default "$schema_map")"
echo "$out_default" | jq -e '.command == "run"' >/dev/null \
  || report_fail 18 "schema dispatch default fallback: $out_default"
pass 18 "cli_emit_schema_dispatch default→run fallback"

# (19) cli_emit_schema_dispatch unknown returns 64
set +e
err_out="$(cli_emit_schema_dispatch unknown_surface "$schema_map" 2>&1)"
err_rc=$?
set -e
[[ "$err_rc" -eq 64 ]] || report_fail 19 "expected rc=64 for unknown surface, got $err_rc"
pass 19 "cli_emit_schema_dispatch unknown rc=64"

# (20) cli_emit_schema_dispatch missing map returns 64
set +e
miss_out="$(cli_emit_schema_dispatch run "$TMP/no-such-file.json" 2>&1)"
miss_rc=$?
set -e
[[ "$miss_rc" -eq 64 ]] || report_fail 20 "expected rc=64 for missing map, got $miss_rc"
pass 20 "cli_emit_schema_dispatch missing-map rc=64"

# (21) cli_route_command_help fires on --help
fired_marker_b="$TMP/route-fired"
set +e
route_out="$(bash -c "source '$LIB'; topic_help() { touch '$fired_marker_b'; printf 'topic %s\n' \"\$1\"; }; cli_route_command_help doctor topic_help --help; printf 'after\n'")"
route_rc=$?
set -e
[[ "$route_rc" -eq 0 ]] || report_fail 21 "route_command_help --help rc=$route_rc"
[[ -f "$fired_marker_b" ]] || report_fail 21 "topic help did not fire"
echo "$route_out" | grep -q "topic doctor" || report_fail 21 "topic help did not get command name"
echo "$route_out" | grep -q "after" && report_fail 21 "route did not exit 0; 'after' printed"
pass 21 "cli_route_command_help fired with command name + exited"

# (22) cli_route_command_help no --help returns 0
no_marker="$TMP/no-route-fired"
set +e
nr_out="$(bash -c "source '$LIB'; topic_help() { touch '$no_marker'; }; cli_route_command_help doctor topic_help --json arg; printf 'after\n'")"
nr_rc=$?
set -e
[[ "$nr_rc" -eq 0 ]] || report_fail 22 "no-help path rc=$nr_rc"
[[ -f "$no_marker" ]] && report_fail 22 "topic fn fired when it should not have"
echo "$nr_out" | grep -q "after" || report_fail 22 "caller did not proceed"
pass 22 "cli_route_command_help non-help returns"

# (23) cli_emit_audit_tail with rows
audit_log_b="$TMP/audit-tail.jsonl"
for i in 1 2 3 4 5; do
  jq -nc --arg i "$i" '{ts:"2026-05-10T00:00:0\($i)Z",action:"x",status:"ok",sha256:"deadbeef"}' >> "$audit_log_b"
done
audit_out="$(cli_emit_audit_tail "$audit_log_b" "smoke.audit/v1" 3)"
echo "$audit_out" | jq -e '.status == "pass" and .row_count == 5 and (.recent | length == 3)' >/dev/null \
  || report_fail 23 "audit_tail with rows: $audit_out"
pass 23 "cli_emit_audit_tail returns last N rows + total count"

# (24) cli_emit_audit_tail empty file
audit_empty="$TMP/audit-empty.jsonl"
: > "$audit_empty"
empty_out="$(cli_emit_audit_tail "$audit_empty" "smoke.audit/v1" 5)"
echo "$empty_out" | jq -e '.status == "empty" and .row_count == 0 and (.recent | length == 0)' >/dev/null \
  || report_fail 24 "audit_tail empty file: $empty_out"
pass 24 "cli_emit_audit_tail empty file"

# (25) cli_emit_audit_tail missing file
missing_out="$(cli_emit_audit_tail "$TMP/no-such-audit.jsonl" "smoke.audit/v1" 5)"
echo "$missing_out" | jq -e '.status == "missing" and .row_count == 0' >/dev/null \
  || report_fail 25 "audit_tail missing file: $missing_out"
pass 25 "cli_emit_audit_tail missing file"

if [[ "$fail" -gt 0 ]]; then
  echo "FAIL: $fail assertion(s) failed" >&2
  exit 1
fi
echo "PASS canonical-cli-helpers-smoke (25 assertions)"
exit 0
