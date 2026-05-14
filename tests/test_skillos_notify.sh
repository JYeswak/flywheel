#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/{capability-control-plane}-notify.py"
TMP="$(mktemp -d -t f2oy.XXXXXX)"
export TMP
trap 'python3 -c "import os, shutil; shutil.rmtree(os.environ[\"TMP\"], ignore_errors=True)"' EXIT

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

write_topology() {
  local path="$1"
  jq -nc '{session:"{capability-control-plane}",effective_at:"2026-05-08T00:00:00Z",orchestrator_pane:4,repo_path:"$HOME/Developer/{capability-control-plane}"}' >"$path"
}

write_fake_ntm() {
  local path="$1"
  cat >"$path" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_NTM_LOG:?}"
jq -nc '{status:"sent"}'
SH
  chmod +x "$path"
}

run_notify() {
  local name="$1"; shift
  local out="$TMP/$name.json"
  local rc=0
  "$SCRIPT" --now 2026-05-08T01:00:00Z "$@" >"$out" || rc=$?
  printf '%s\n' "$rc" >"$TMP/$name.rc"
  printf '%s\n' "$out"
}

python3 -m py_compile "$SCRIPT" && pass "script_compiles" || fail "script_compiles"

topology="$TMP/topology.jsonl"
threads="$TMP/threads.jsonl"
write_topology "$topology"

dry_out="$(run_notify dry --topology "$topology" --thread-state "$threads" --candidate-skill-name reusable-fixture-skill --discovery-id sd-001 --source-session flywheel --dry-run --json)"
assert_jq "$dry_out" '.status == "dry_run" and .target.session == "{capability-control-plane}" and .target.pane == 4 and .candidate_skill_name == "reusable-fixture-skill" and .discovery_id == "sd-001" and (.message | contains("sd-001")) and .mutations.ntm_sent == false' "dry_run_prints_target_candidate_message_without_send"
assert_jq "$dry_out" '.ntm_argv[0] == "$HOME/.local/bin/ntm" and .ntm_argv[1] == "send"' "planned_apply_uses_absolute_ntm"
assert_jq "$dry_out" '.agent_mail_thread.thread_key == "[skill-discovery] reusable-fixture-skill" and .agent_mail_thread.thread_id == "skill-discovery:reusable-fixture-skill"' "thread_key_deterministic"

fake_ntm="$TMP/ntm"
ntm_log="$TMP/ntm.log"
write_fake_ntm "$fake_ntm"

apply_one="$(FLYWHEEL_ALLOW_TEST_NTM=1 FAKE_NTM_LOG="$ntm_log" run_notify apply-one --topology "$topology" --thread-state "$threads" --ntm-bin "$fake_ntm" --candidate-skill-name reusable-fixture-skill --discovery-id sd-002 --source-session flywheel --message-note 'Authorization: Bearer abc.def-ghi registration_token=abcdefghijklmnopqrstuvwxyz123456' --apply --json)"
assert_jq "$apply_one" '.status == "sent" and .mutations.ntm_sent == true and .mutations.thread_state_appended == true and .agent_mail_thread.action == "create" and .token_safety.raw_token_patterns_found >= 2 and .token_safety.agent_mail_token_echo == false' "apply_sends_and_scrubs_tokens"
if grep -E 'abc\.def-ghi|abcdefghijklmnopqrstuvwxyz123456' "$apply_one" "$ntm_log" >/dev/null; then
  fail "token_safety_no_raw_secret_in_output_or_ntm"
else
  pass "token_safety_no_raw_secret_in_output_or_ntm"
fi

apply_two="$(FLYWHEEL_ALLOW_TEST_NTM=1 FAKE_NTM_LOG="$ntm_log" run_notify apply-two --topology "$topology" --thread-state "$threads" --ntm-bin "$fake_ntm" --candidate-skill-name reusable-fixture-skill --discovery-id sd-003 --source-session {session} --apply --json)"
assert_jq "$apply_two" '.status == "sent" and .agent_mail_thread.action == "reuse" and .agent_mail_thread.thread_key == "[skill-discovery] reusable-fixture-skill" and .mutations.thread_state_appended == false' "same_candidate_reuses_thread_key"
[[ "$(wc -l <"$threads" | tr -d ' ')" == "1" ]] && pass "idempotent_reuse_no_duplicate_thread_row" || fail "idempotent_reuse_no_duplicate_thread_row"

archive_age="$(run_notify archive-age --topology "$topology" --thread-state "$threads" --candidate-skill-name reusable-fixture-skill --discovery-id sd-004 --source-session flywheel --last-sighting-age-days 30 --dry-run --json)"
assert_jq "$archive_age" '.agent_mail_thread.action == "archive" and .agent_mail_thread.archived == true and .agent_mail_thread.archive_reason == "last_sighting_age_days_gte_30"' "auto_archive_by_age"

archive_shipped="$(run_notify archive-shipped --topology "$topology" --thread-state "$threads" --candidate-skill-name shipped-fixture-skill --discovery-id sd-005 --source-session flywheel --skill-shipped --dry-run --json)"
assert_jq "$archive_shipped" '.agent_mail_thread.action == "archive" and .agent_mail_thread.archived == true and .agent_mail_thread.archive_reason == "skill_shipped"' "auto_archive_by_skill_shipped"

missing_topology="$TMP/missing-topology.jsonl"
discovery_ledger="$TMP/skill-discoveries.jsonl"
jq -nc '{ts:"2026-05-08T00:00:00Z",discovery_id:"sd-006",candidate_skill_name:"missing-target-skill"}' >"$discovery_ledger"
missing_out="$(run_notify missing --topology "$missing_topology" --thread-state "$TMP/missing-threads.jsonl" --discovery-ledger "$discovery_ledger" --candidate-skill-name missing-target-skill --discovery-id sd-006 --source-session flywheel --dry-run --json)"
assert_jq "$missing_out" '.status == "{capability-control-plane}_target_unavailable" and .reason == "{capability-control-plane}_topology_missing" and .row_left_intact == true and .mutations.discoveries_mutated == false' "missing_topology_structured_unavailable"
jq -e '.discovery_id == "sd-006"' "$discovery_ledger" >/dev/null && pass "missing_topology_leaves_discovery_row_intact" || fail "missing_topology_leaves_discovery_row_intact"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
