#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/handoff-skill-to-{capability-control-plane}.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/handoff-skill-to-{capability-control-plane}.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

mkdir -p "$TMP/bin" "$TMP/home/.claude/skills/local-skill" "$TMP/{capability-control-plane}-state"
cat >"$TMP/home/.claude/skills/local-skill/SKILL.md" <<'EOF'
---
name: local-skill
version: 1.2.3
---
EOF

cat >"$TMP/bin/jsm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "show" && "${2:-}" == "vibing-with-ntm" ]]; then
  jq -nc '{skill:{name:"vibing-with-ntm",version:6,is_owner:false,is_jeffreys:true,distribution_policy:"forbidden"}}'
  exit 0
fi
jq -nc --arg skill "${2:-}" '{error:"Skill not found",skill:$skill}'
exit 1
SH
chmod +x "$TMP/bin/jsm"

cat >"$TMP/bin/curl" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
payload=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d) payload="${2:-}"; shift 2 ;;
    *) shift ;;
  esac
done
printf '%s\n' "$payload" >>"${CURL_PAYLOAD_LOG:?}"
jq -nc '{result:{content:[{text:"{\"deliveries\":[{\"payload\":{\"id\":123}}],\"count\":1}"}]}}'
SH
chmod +x "$TMP/bin/curl"

env_base=(
  "HOME=$TMP/home"
  "PATH=$TMP/bin:$PATH"
  "HANDOFF_SKILL_TO_SKILLOS_SKILL_ROOTS=$TMP/home/.claude/skills"
  "HANDOFF_SKILL_TO_SKILLOS_SKILLOS_STATE_DIR=$TMP/{capability-control-plane}-state"
  "HANDOFF_SKILL_TO_SKILLOS_DISPATCH_LOG=$TMP/dispatch-log.jsonl"
  "HANDOFF_SKILL_TO_SKILLOS_CURL=$TMP/bin/curl"
  "HANDOFF_SKILL_TO_SKILLOS_JSM=$TMP/bin/jsm"
  "HANDOFF_SKILL_TO_SKILLOS_SENDER_TOKEN=fleet-token"
  "AGENTMAIL_HTTP_BEARER_TOKEN=http-token"
  "CURL_PAYLOAD_LOG=$TMP/curl-payloads.jsonl"
)

if bash -n "$SCRIPT"; then pass "script syntax"; else fail "script syntax"; fi

env "${env_base[@]}" "$SCRIPT" --dry-run local-skill >"$TMP/dry.json"
assert_jq "$TMP/dry.json" '.action == "skipped" and .reason == "dry_run" and .message_id == null and .skill == "local-skill" and .version == "1.2.3" and (.subject | test("^\\[skill-handoff\\] local-skill v1\\.2\\.3")) and (.body_md | test("hardening_requests:"))' "dry-run previews message"
if [[ ! -e "$TMP/curl-payloads.jsonl" && ! -e "$TMP/dispatch-log.jsonl" ]]; then
  pass "dry-run sends nothing"
else
  fail "dry-run mutated send or dispatch log"
fi

touch "$TMP/{capability-control-plane}-state/local-skill-v1.2-20260505.json"
set +e
env "${env_base[@]}" "$SCRIPT" local-skill 1.2.3 >"$TMP/duplicate.json"
duplicate_rc=$?
set -e
if [[ "$duplicate_rc" == "4" ]]; then pass "duplicate exit code"; else fail "duplicate exit code rc=$duplicate_rc"; fi
assert_jq "$TMP/duplicate.json" '.action == "duplicate" and .message_id == null and .reason == "already_handed_off_this_version"' "duplicate json"

set +e
env "${env_base[@]}" "$SCRIPT" vibing-with-ntm 6.0.0 >"$TMP/forbidden.json"
forbidden_rc=$?
set -e
if [[ "$forbidden_rc" == "3" ]]; then pass "forbidden exit code"; else fail "forbidden exit code rc=$forbidden_rc"; fi
assert_jq "$TMP/forbidden.json" '.action == "forbidden" and .ownership == "upstream" and .reason == "ownership_forbidden"' "forbidden json"

rm -f "$TMP/{capability-control-plane}-state/local-skill-v1.2-20260505.json" "$TMP/dispatch-log.jsonl" "$TMP/curl-payloads.jsonl"
env "${env_base[@]}" "$SCRIPT" local-skill 1.2.3 >"$TMP/sent.json"
assert_jq "$TMP/sent.json" '.action == "sent" and .message_id == 123 and .ownership == "local"' "send json"
assert_jq "$TMP/dispatch-log.jsonl" '.event == "{capability-control-plane}_handoff_sent" and .skill == "local-skill" and .version == "1.2.3" and .message_id == 123 and .project_key == "$HOME/.local/state/flywheel/fleet-mail-project" and .{capability-control-plane}_handoff_skipped_reason == null' "dispatch log sent row"
assert_jq "$TMP/curl-payloads.jsonl" '.params.name == "send_message" and .params.arguments.sender_name == "LavenderGlen" and .params.arguments.to[0] == "FoggyBear" and (.params.arguments.subject | test("local-skill v1.2.3"))' "curl payload"

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$fail_count" == "0" ]]
