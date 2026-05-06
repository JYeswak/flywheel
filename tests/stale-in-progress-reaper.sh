#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/stale-in-progress-reaper.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/stale-in-progress-reaper.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

assert_jq_id() {
  local file="$1" id="$2" expr="$3" label="$4"
  if jq -e --arg id "$id" "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

status_of() {
  local repo="$1" id="$2"
  (cd "$repo" && br show "$id" --json | jq -r '.[0].status')
}

write_jsonl_append_lib() {
  cat >"$TMP/jsonl-append.sh" <<'SH'
fw_jsonl_append_validated() {
  local path="$1" row="$2"
  [[ -n "$row" ]] || return 1
  jq -e . >/dev/null <<<"$row" || return 1
  mkdir -p "$(dirname "$path")"
  printf '%s\n' "$row" >>"$path"
}
SH
}

create_bead() {
  local repo="$1" title="$2" assignee="${3:-}"
  if [[ -n "$assignee" ]]; then
    (cd "$repo" && br create "$title" --type task --priority P1 --status in_progress --assignee "$assignee" --description fixture --json | jq -r '.id // .issue.id // .[0].id')
  else
    (cd "$repo" && br create "$title" --type task --priority P1 --status in_progress --description fixture --json | jq -r '.id // .issue.id // .[0].id')
  fi
}

make_repo() {
  local repo="$TMP/repo"
  mkdir -p "$repo/.flywheel"
  git -C "$repo" init -q
  git -C "$repo" config user.email "fixture@example.test"
  git -C "$repo" config user.name "Fixture"
  (cd "$repo" && br init >/dev/null)

  stale_id="$(create_bead "$repo" "[stale] no signal")"
  assignee_id="$(create_bead "$repo" "[active] assigned" "WorkerOne")"
  recent_id="$(create_bead "$repo" "[recent] touched")"
  commit_id="$(create_bead "$repo" "[commit] recent commit")"
  callback_id="$(create_bead "$repo" "[callback] recent callback")"

  printf 'commit evidence\n' >"$repo/evidence.txt"
  git -C "$repo" add evidence.txt
  GIT_AUTHOR_DATE="2026-05-04T03:00:00Z" GIT_COMMITTER_DATE="2026-05-04T03:00:00Z" \
    git -C "$repo" commit -q -m "touch ${commit_id}"

  jq -nc --arg id "$callback_id" '{ts:"2026-05-04T03:00:00Z",event:"worker_callback",callback_text:("DONE " + $id)}' >"$repo/.flywheel/dispatch-log.jsonl"

  jq -n \
    --arg stale "$stale_id" \
    --arg assignee "$assignee_id" \
    --arg recent "$recent_id" \
    --arg commit "$commit_id" \
    --arg callback "$callback_id" \
    '[
      {id:$stale,title:"[stale] no signal",status:"in_progress",assignee:"unassigned",updated_at:"2026-04-01T00:00:00Z",priority:1},
      {id:$assignee,title:"[active] assigned",status:"in_progress",assignee:"WorkerOne",updated_at:"2026-04-01T00:00:00Z",priority:1},
      {id:$recent,title:"[recent] touched",status:"in_progress",assignee:"",updated_at:"2026-05-04T03:00:00Z",priority:1},
      {id:$commit,title:"[commit] recent commit",status:"in_progress",assignee:"",updated_at:"2026-04-01T00:00:00Z",priority:1},
      {id:$callback,title:"[callback] recent callback",status:"in_progress",assignee:"unassigned",updated_at:"2026-04-01T00:00:00Z",priority:1}
    ]' >"$TMP/in-progress-fixture.json"

  {
    printf 'stale_id=%s\n' "$stale_id"
    printf 'assignee_id=%s\n' "$assignee_id"
    printf 'recent_id=%s\n' "$recent_id"
    printf 'commit_id=%s\n' "$commit_id"
    printf 'callback_id=%s\n' "$callback_id"
  } >"$TMP/ids.env"

  printf '%s\n' "$repo"
}

if bash -n "$SCRIPT"; then
  pass "reaper syntax"
else
  fail "reaper syntax"
fi

write_jsonl_append_lib
repo="$(make_repo)"
source "$TMP/ids.env"
ledger="$TMP/stale-reaper-ledger.jsonl"

base_env=(
  "STALE_REAPER_NOW=2026-05-05T03:20:00Z"
  "STALE_REAPER_BR_LIST_FIXTURE=$TMP/in-progress-fixture.json"
  "STALE_REAPER_LEDGER=$ledger"
  "FLYWHEEL_JSONL_APPEND_LIB=$TMP/jsonl-append.sh"
)

env "${base_env[@]}" "$SCRIPT" --repo "$repo" --json >"$TMP/dry.json"
assert_jq "$TMP/dry.json" '.schema_version == "stale-in-progress-reaper.v1" and .total_in_progress == 5' "schema and fixture count"
assert_jq "$TMP/dry.json" '.stale_count == 1 and .active_count == 3 and .recently_touched_count == 1' "classification counts"
assert_jq_id "$TMP/dry.json" "$stale_id" 'any(.candidates[]; .bead_id == $id and .classification == "STALE" and .recommended_action == "close")' "stale candidate selected"
assert_jq_id "$TMP/dry.json" "$commit_id" 'any(.classified[]; .bead_id == $id and .classification == "ACTIVE" and .last_signal.kind == "commit")' "recent commit is active"
assert_jq_id "$TMP/dry.json" "$callback_id" 'any(.classified[]; .bead_id == $id and .classification == "ACTIVE" and .last_signal.kind == "callback")' "recent callback is active"
if [[ "$(status_of "$repo" "$stale_id")" == "in_progress" && ! -e "$ledger" ]]; then
  pass "dry-run does not mutate br state or ledger"
else
  fail "dry-run does not mutate br state or ledger"
fi

env "${base_env[@]}" "$SCRIPT" --repo "$repo" --apply --json >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '.status == "applied" and (.actual_actions | length == 1)' "apply reports one action"
if [[ "$(status_of "$repo" "$stale_id")" == "closed" && "$(status_of "$repo" "$assignee_id")" == "in_progress" && "$(status_of "$repo" "$recent_id")" == "in_progress" && "$(status_of "$repo" "$commit_id")" == "in_progress" && "$(status_of "$repo" "$callback_id")" == "in_progress" ]]; then
  pass "apply closes only stale bead"
else
  fail "apply closes only stale bead"
fi
if jq -e --arg id "$stale_id" '.event == "stale_reaper_apply" and .bead_id == $id and .reason == "stale-in-progress-reaped (last 7d zero signal)"' "$ledger" >/dev/null; then
  pass "apply writes stale reaper ledger"
else
  fail "apply writes stale reaper ledger"
fi

"$SCRIPT" --schema >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.mutation_requires == ["--apply"] and (.doctor_fields | index("stale_in_progress_count_24h"))' "schema documents apply gate and doctor field"
"$SCRIPT" --info --json >/dev/null && pass "info command"
"$SCRIPT" --examples >/dev/null && pass "examples command"
"$SCRIPT" quickstart >/dev/null && pass "quickstart command"
"$SCRIPT" completion >/dev/null && pass "completion command"
env "${base_env[@]}" "$SCRIPT" doctor --repo "$repo" --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.stale_in_progress_count_24h == 1 and (.stale_in_progress_top_classes | length == 1)' "doctor fields emitted"

if [[ "$fail_count" -ne 0 ]]; then
  printf 'SUMMARY pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'SUMMARY pass=%s fail=0\n' "$pass_count"
