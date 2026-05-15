#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/skillos-discovery-coordinator.py"
BR_BIN="${BR_BIN:-$HOME/.cargo/bin/br}"
TMP="$(mktemp -d -t s08u.XXXXXX)"
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

assert_rc() {
  local actual="$1" expected="$2" label="$3"
  if [[ "$actual" == "$expected" ]]; then
    pass "$label"
  else
    fail "$label expected=$expected actual=$actual"
  fi
}

make_repo() {
  local name="$1"
  local repo="$TMP/$name"
  mkdir -p "$repo"
  git -C "$repo" init -q
  br --no-auto-import -q --db "$repo/.beads/beads.db" init >/dev/null 2>&1 || (cd "$repo" && br init >/dev/null)
  printf '%s\n' "$repo"
}

write_fixture() {
  local path="$1"
  local candidate="$2"
  local count="$3"
  python3 - "$path" "$candidate" "$count" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
candidate = sys.argv[2]
count = int(sys.argv[3])
path.parent.mkdir(parents=True, exist_ok=True)
with path.open("w", encoding="utf-8") as handle:
    for idx in range(1, count + 1):
        row = {
            "ts": f"2026-05-08T00:{idx:02d}:00Z",
            "discovery_id": f"sd-fixture-{idx:03d}",
            "session": f"session-{idx}",
            "worker_pane": idx,
            "worker_kind": "codex",
            "task_context": f"fixture context {idx}",
            "discovery_kind": "pattern-recurrence" if idx > 1 else "pattern-emerged",
            "candidate_skill_name": candidate,
            "evidence": {"source": "fixture", "idx": idx},
            "promotion_signal": f"sighting_{idx}",
            "should_become": "skill-builder candidate",
            "blocking_current_work": False,
        }
        handle.write(json.dumps(row, sort_keys=True) + "\n")
PY
}

run_coordinator() {
  local name="$1"; shift
  local out="$TMP/$name.json"
  local rc=0
  "$SCRIPT" \
    --now 2026-05-08T01:00:00Z \
    --br-bin "$BR_BIN" \
    "$@" >"$out" || rc=$?
  printf '%s\n' "$rc" >"$TMP/$name.rc"
  printf '%s\n' "$out"
}

python3 -m py_compile "$SCRIPT" && pass "script_compiles" || fail "script_compiles"

repo_one="$(make_repo repo-one)"
write_fixture "$TMP/one.jsonl" reusable-fixture-skill 1
one_out="$(run_coordinator one --discoveries "$TMP/one.jsonl" --pulse "$TMP/one-pulse.jsonl" --repo "$repo_one" --dry-run --json)"
assert_jq "$one_out" '.dry_run == true and .mutations.agent_mail_mutated == false and (.mutations.beads_created | length) == 0 and .candidate_count == 1' "dry_run_groups_without_external_mutation"
assert_jq "$one_out" '.candidates[0].action == "log_only" and .candidates[0].sighting_count == 1' "one_sighting_log_only"

repo_two="$(make_repo repo-two)"
write_fixture "$TMP/two.jsonl" reusable-fixture-skill 2
two_out="$(run_coordinator two --discoveries "$TMP/two.jsonl" --pulse "$TMP/two-pulse.jsonl" --repo "$repo_two" --dry-run --json)"
assert_jq "$two_out" '.candidates[0].action == "agent_mail_thread_needed" and .candidates[0].planned_agent_mail_thread == "[skill-discovery] reusable-fixture-skill"' "two_sightings_agent_mail_thread_needed"

repo_three="$(make_repo repo-three)"
write_fixture "$TMP/three.jsonl" reusable-fixture-skill 3
three_out="$(run_coordinator three --discoveries "$TMP/three.jsonl" --pulse "$TMP/three-pulse.jsonl" --repo "$repo_three" --dry-run --json)"
assert_jq "$three_out" '.candidates[0].action == "skill_builder_bead_needed" and (.candidates[0].planned_bead.br_argv | index("--dry-run")) and (.candidates[0].consolidated_evidence | length == 3)' "three_sightings_plans_dry_run_bead"

apply_no_key_out="$(run_coordinator apply-no-key --discoveries "$TMP/three.jsonl" --pulse "$TMP/apply-no-key-pulse.jsonl" --repo "$repo_three" --apply --json)"
assert_rc "$(cat "$TMP/apply-no-key.rc")" "1" "apply_without_idempotency_key_fails"
assert_jq "$apply_no_key_out" '.error == "--apply requires --idempotency-key" and .reason == "idempotency_key_required"' "apply_requires_idempotency_key_json"

apply_out="$(run_coordinator apply --discoveries "$TMP/three.jsonl" --pulse "$TMP/apply-pulse.jsonl" --repo "$repo_three" --apply --idempotency-key s08u-test --json)"
assert_jq "$apply_out" '.status == "applied" and (.mutations.beads_created | length == 1) and .candidates[0].action == "skill_builder_bead_exists" and .candidates[0].target_bead_id' "apply_creates_one_skill_builder_bead"
duplicate_out="$(run_coordinator duplicate --discoveries "$TMP/three.jsonl" --pulse "$TMP/duplicate-pulse.jsonl" --repo "$repo_three" --apply --idempotency-key s08u-test --json)"
assert_jq "$duplicate_out" '.status == "applied" and (.mutations.beads_created | length == 0) and .candidates[0].action == "skill_builder_bead_exists" and .candidates[0].target_bead_id' "repeat_apply_reuses_existing_bead"
bead_count="$(cd "$repo_three" && "$BR_BIN" list --json | jq '[.issues[] | select(.title | contains("[skill-builder:reusable-fixture-skill]"))] | length')"
[[ "$bead_count" == "1" ]] && pass "at_most_one_bead_per_candidate" || fail "at_most_one_bead_per_candidate count=$bead_count"

repo_five="$(make_repo repo-five)"
existing_id="$(cd "$repo_five" && "$BR_BIN" create "[skill-builder:reusable-fixture-skill] reusable-fixture-skill" --type task --priority P1 --description "fixture existing skill-builder bead" --json | jq -r '.id')"
write_fixture "$TMP/five.jsonl" reusable-fixture-skill 5
five_out="$(run_coordinator five --discoveries "$TMP/five.jsonl" --pulse "$TMP/five-pulse.jsonl" --repo "$repo_five" --dry-run --json)"
if jq -e --arg id "$existing_id" '.candidates[0].action == "dispatch_worker_needed" and .candidates[0].target_bead_id == $id' "$five_out" >/dev/null; then
  pass "five_sightings_dispatch_worker_with_target_bead"
else
  fail "five_sightings_dispatch_worker_with_target_bead"
  jq . "$five_out" >&2 || true
fi

assert_jq "$TMP/five-pulse.jsonl" '.schema_version == "fleet-skill-pulse/v1" and .event == "fleet_skill_pulse" and .candidate_count == 1 and .discovery_count == 5 and .pending_action_count == 1' "fleet_skill_pulse_row_valid"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
