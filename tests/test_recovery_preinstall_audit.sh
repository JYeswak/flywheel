#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/recovery-preinstall-audit.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/recovery-preinstall-audit.XXXXXX")"
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

make_fake_ntm() {
  local path="$1"
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'set -euo pipefail' \
    'case "$*" in' \
    '  "list --json") jq -nc '"'"'{sessions:[{name:"flywheel"},{name:"{capability-control-plane}"}]}'"'"' ;;' \
    '  *) printf "unsupported fake ntm: %s\n" "$*" >&2; exit 2 ;;' \
    'esac' >"$path"
  chmod +x "$path"
}

make_fake_agent_mail() {
  local path="$1"
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'set -euo pipefail' \
    "case \"\${1:-}\" in" \
    '  --version) printf "agent-mail 0.0-fixture\n" ;;' \
    '  --help) printf "agent-mail fixture help\n" ;;' \
    '  *) exit 2 ;;' \
    'esac' >"$path"
  chmod +x "$path"
}

write_identity() {
  local session="$1" pane="$2" identity="$3" status="$4"
  mkdir -p "$TMP/agent-mail/sessions" "$TMP/agent-mail/tokens"
  jq -nc \
    --arg session "$session" \
    --argjson pane "$pane" \
    --arg identity "$identity" \
    --arg status "$status" \
    '{schema_version:"agent-mail-identity-registry/v2",session:$session,pane:$pane,identity_name:$identity,status:$status,role:"worker"}' \
    >"$TMP/agent-mail/sessions/${session}:${pane}.json"
  printf 'fixture-token\n' >"$TMP/agent-mail/tokens/${identity}.token"
  chmod 600 "$TMP/agent-mail/tokens/${identity}.token"
}

mkdir -p "$TMP/repos/flywheel/.flywheel" "$TMP/repos/flywheel/.beads" "$TMP/repos/{capability-control-plane}/.flywheel" "$TMP/repos/lost"
git -C "$TMP/repos/flywheel" init -q
printf 'dirty\n' >"$TMP/repos/flywheel/dirty.txt"
if command -v sqlite3 >/dev/null 2>&1; then
  sqlite3 "$TMP/repos/flywheel/.beads/beads.db" 'create table beads(id text primary key);'
else
  printf 'not sqlite\n' >"$TMP/repos/flywheel/.beads/beads.db"
fi

ntm="$TMP/ntm"; make_fake_ntm "$ntm"
agent_mail="$TMP/agent-mail-cli"; make_fake_agent_mail "$agent_mail"
write_identity flywheel 2 AmberDog active

config="$TMP/ntm.toml"
cat >"$config" <<TOML
[session_paths]
flywheel = "$TMP/repos/flywheel"
{capability-control-plane} = "$TMP/repos/{capability-control-plane}"
lost = "$TMP/repos/lost"
TOML

topology="$TMP/topology.jsonl"
jq -nc --arg repo "$TMP/repos/flywheel" '{session:"flywheel",effective_at:"2026-05-07T20:00:00Z",repo_path:$repo}' >"$topology"
jq -nc --arg repo "$TMP/repos/{capability-control-plane}" '{session:"{capability-control-plane}",effective_at:"2026-05-07T20:00:00Z",repo_path:$repo}' >>"$topology"

roster="$TMP/roster.jsonl"
jq -nc --arg repo "$TMP/repos/flywheel" '{session:"flywheel",ts:"2026-05-07T20:00:00Z",repo_path:$repo,workers:[{pane:2,kind:"codex"}]}' >"$roster"
jq -nc --arg repo "$TMP/repos/{capability-control-plane}" '{session:"{capability-control-plane}",ts:"2026-05-07T20:00:00Z",repo_path:$repo,workers:[{pane:1,kind:"codex"}]}' >>"$roster"

loops="$TMP/loops"
mkdir -p "$loops"
jq -nc --arg repo "$TMP/repos/flywheel" '{session:"flywheel",repo_path:$repo,active:true}' >"$loops/flywheel.json"

jq -nc '{event:"dispatch_sent",task_id:"flywheel-uufu"}' >"$TMP/repos/flywheel/.flywheel/dispatch-log.jsonl"
jq -nc '{tick_complete:true}' >"$TMP/repos/flywheel/.flywheel/last_closeout_receipt.json"

chmod +x "$SCRIPT"
if bash -n "$SCRIPT"; then
  pass "01_script_syntax"
else
  fail "01_script_syntax"
fi

"$SCRIPT" \
  --ntm-bin "$ntm" \
  --ntm-config "$config" \
  --topology "$topology" \
  --team-roster "$roster" \
  --loops-dir "$loops" \
  --agent-mail-state-dir "$TMP/agent-mail" \
  --agent-mail-cli "$agent_mail" \
  --agent-mail-liveness-url "http://127.0.0.1:1/health/liveness" \
  --confidence-min 70 \
  --now "2026-05-07T20:30:00Z" \
  --pretty >"$TMP/report.json"

if jq empty "$TMP/report.json"; then
  pass "02_json_valid"
else
  fail "02_json_valid"
fi
assert_jq "$TMP/report.json" '.schema_version=="recovery-preinstall-audit/v1" and .source_plan==".flywheel/PLANS/recovery-system-2026-05-01/00-PLAN.md"' "03_schema_and_source_plan_present"
assert_jq "$TMP/report.json" '.sessions[] | select(.session=="flywheel" and .topology_match==true and .roster_match==true and .confidence>=90)' "04_high_confidence_session_emitted"
assert_jq "$TMP/report.json" '(.sessions[] | select(.session=="lost" and .low_confidence==true)) and (.low_confidence_sessions|index("lost")) and .apply_blocked==true' "05_low_confidence_session_blocks_apply"
assert_jq "$TMP/report.json" '.projects[] | select(.repo_path|endswith("/repos/flywheel")) | .beads_db.exists==true and .dirty_worktree.dirty_count>=1 and (.dirty_worktree.owner_map|length)>=1' "06_beads_dirty_owner_inventory"
assert_jq "$TMP/report.json" '.agent_mail.cli_without_database_url.ok==true and .agent_mail.ready_identity_count==1' "07_agent_mail_cli_and_identity_ready"
assert_jq "$TMP/report.json" '.loop_state.flywheel and (.tick_receipts|length)>=1 and (.dispatch_context[]|select(.repo_path|endswith("/repos/flywheel")).in_flight_count==1)' "08_loop_receipts_and_dispatch_context"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$pass_count" -eq 8 && "$fail_count" -eq 0 ]]
