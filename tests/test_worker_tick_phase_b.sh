#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
WORKER_TICK_MD="${WORKER_TICK_MD:-$HOME/.claude/commands/flywheel/worker-tick.md}"
TMP="$(mktemp -d -t khr6.XXXXXX)"
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

assert_grep() {
  local pattern="$1" file="$2" label="$3"
  if rg -q "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

run_worker_tick() {
  local evidence="$1" out="$2"
  FLYWHEEL_FUCKUP_LOG="$TMP/fuckups.jsonl" \
    "$BIN" tick --worker-mode \
      --repo "$ROOT" \
      --session flywheel \
      --pane 3 \
      --harness codex \
      --task-id flywheel-khr6-fixture \
      --state-root "$TMP/state" \
      --evidence "$evidence" \
      --json >"$out"
}

bash -n "$BIN" && pass "flywheel-loop syntax" || fail "flywheel-loop syntax"
bash -n "$HOME/.claude/skills/.flywheel/lib/portable/core.sh" && pass "portable_core syntax" || fail "portable_core syntax"
bash -n "$HOME/.claude/skills/.flywheel/lib/portable/worker.sh" && pass "portable_worker syntax" || fail "portable_worker syntax"

assert_grep "worker_low_socraticode_K|worker_unreserved_edit|worker_skipped_skill_lookup|worker-mode|harness|cadence_seconds=1800" "$WORKER_TICK_MD" "worker_tick_doc_terms"

cat >"$TMP/no-socraticode.json" <<'JSON'
{
  "modified_files": [],
  "skills_consulted": ["beads-workflow"]
}
JSON
run_worker_tick "$TMP/no-socraticode.json" "$TMP/no-socraticode.out"
assert_jq "$TMP/no-socraticode.out" '.violations == ["worker_low_socraticode_K"]' "no_socraticode_emits_low_k"

cat >"$TMP/unreserved.json" <<'JSON'
{
  "socraticode_k_count": 10,
  "modified_files": ["lib/example.sh"],
  "skills_consulted": ["beads-workflow"],
  "agent_mail_reservations": []
}
JSON
run_worker_tick "$TMP/unreserved.json" "$TMP/unreserved.out"
assert_jq "$TMP/unreserved.out" '.violations == ["worker_unreserved_edit"]' "modified_without_reservation_emits"

cat >"$TMP/no-skill.json" <<'JSON'
{
  "socraticode_k_count": 10,
  "modified_files": [],
  "agent_mail_reservations": []
}
JSON
run_worker_tick "$TMP/no-skill.json" "$TMP/no-skill.out"
assert_jq "$TMP/no-skill.out" '.violations == ["worker_skipped_skill_lookup"]' "no_skill_emits"

cat >"$TMP/none-found-pass.json" <<'JSON'
{
  "socraticode_k_count": 10,
  "modified_files": ["lib/example.sh"],
  "agent_mail_reservations": ["lib/example.sh"],
  "skills_consulted": ["NONE_FOUND"],
  "skill_search_terms": ["worker tick", "phase b"]
}
JSON
run_worker_tick "$TMP/none-found-pass.json" "$TMP/none-found-pass.out"
assert_jq "$TMP/none-found-pass.out" '.status == "ok" and (.violations | length == 0)' "none_found_with_terms_passes"

receipt="$TMP/state/flywheel-worker-3/last_tick.json"
assert_jq "$receipt" '.schema_version == "flywheel-worker-tick/v1" and .harness == "codex" and .session == "flywheel" and .pane == 3 and .mode == "worker-mode" and .cadence == "30m" and .cadence_seconds == 1800 and (.checks_run | length == 3)' "receipt_shape"
assert_jq "$receipt" '.receipt_path == "'"$receipt"'"' "receipt_path_canonical"

jq -s 'map(select(.failure_class == "worker_low_socraticode_K" or .failure_class == "worker_unreserved_edit" or .failure_class == "worker_skipped_skill_lookup"))' "$TMP/fuckups.jsonl" >"$TMP/fuckups.filtered.json"
assert_jq "$TMP/fuckups.filtered.json" 'length >= 3 and all(.[]; .harness == "codex" and .session == "flywheel" and .pane == 3 and .task_id == "flywheel-khr6-fixture" and (.mode | type == "string") and (.failure_class | test("^worker_")))' "fuckup_log_fields_complete"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
