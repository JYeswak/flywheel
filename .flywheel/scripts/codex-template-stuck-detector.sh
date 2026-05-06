#!/usr/bin/env bash
# canonical-cli-scoping-allow-large: mk303 needs one portable detector CLI with live ntm sampling, fixture tests, doctor/repair, and recovery gates.
set -euo pipefail

VERSION="codex-stuck-detector.v1.2.0"
SCHEMA_VERSION="codex-stuck-detector.v1"
CONTRACT_SCHEMA_VERSION="substrate-loop-contract.v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO_ROOT="${CODEX_STUCK_DETECTOR_REPO:-$REPO_ROOT_DEFAULT}"
LEDGER="${CODEX_STUCK_DETECTOR_LEDGER:-$HOME/.local/state/flywheel/codex-stuck-detector.jsonl}"
CONTRACT_LEDGER="${CODEX_STUCK_DETECTOR_CONTRACT_LEDGER:-$HOME/.local/state/flywheel/substrate-loop-contract.jsonl}"
FUCKUP_LOG="${CODEX_STUCK_DETECTOR_FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
TOPOLOGY_LEDGER="${CODEX_STUCK_DETECTOR_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
JSONL_APPEND_LIB="${CODEX_STUCK_DETECTOR_JSONL_APPEND_LIB:-${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}}"
NTM_BIN="${CODEX_STUCK_DETECTOR_NTM_BIN:-$HOME/.local/bin/ntm}"
CAPACITY_AUTO_CONTINUE="${CODEX_STUCK_DETECTOR_CAPACITY_AUTO_CONTINUE:-$REPO_ROOT/.flywheel/scripts/capacity-halt-auto-continue-primitive.sh}"
QUEUED_BARE_ENTER="${CODEX_STUCK_DETECTOR_QUEUED_BARE_ENTER:-$REPO_ROOT/.flywheel/scripts/codex-queued-not-submitted-bare-enter-primitive.sh}"
OOM_KILLED_RESPAWN="${CODEX_STUCK_DETECTOR_OOM_KILLED_RESPAWN:-$NTM_BIN}"

MODE="detect"
JSON_OUT=0
APPLY=0
DRY_RUN=1
AUTO_RECOVER=0
WATCH=0
WATCH_INTERVAL=300
SESSION_NAME="${SESSION:-}"
PANE=""
FIXTURE=""
FIXTURE_DIR=""
WINDOW_SEC="${CODEX_STUCK_DETECTOR_WINDOW_SEC:-6}"
LINES="${CODEX_STUCK_DETECTOR_LINES:-200}"
WORKER_PANES_FROM_TOPOLOGY=0
REPAIR_SCOPE="substrate-contract"
VALIDATE_TARGET="ledger"
WHY_ID=""
SCHEMA_TOPIC="detect"
COMPLETION_SHELL=""

usage() {
  cat <<'EOF'
usage:
  codex-template-stuck-detector.sh --session NAME --pane N [--dry-run|--apply] [--auto-recover] [--json]
  codex-template-stuck-detector.sh --session all --worker-panes-from-topology [--apply] [--json]
  codex-template-stuck-detector.sh --fixture PATH [--dry-run|--apply] [--auto-recover] [--json]
  codex-template-stuck-detector.sh --doctor [--json]
  codex-template-stuck-detector.sh health [--watch] [--interval N] [--json]
  codex-template-stuck-detector.sh repair --scope ledger|substrate-contract|all [--dry-run|--apply] [--json]
  codex-template-stuck-detector.sh validate ledger|fixture [--fixture PATH] [--json]
  codex-template-stuck-detector.sh audit [--json]
  codex-template-stuck-detector.sh why ID [--json]
  codex-template-stuck-detector.sh schema detect|doctor|ledger|contract|fixture [--json]
  codex-template-stuck-detector.sh --info|--examples|quickstart|help TOPIC|completion bash|zsh
EOF
}

json_bool() {
  if [[ "$1" == "1" ]]; then printf true; else printf false; fi
}

now_iso() {
  printf '%s\n' "${CODEX_STUCK_DETECTOR_NOW:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
}

emit() {
  local payload="$1" text="$2" rc="${3:-0}"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    printf '%s\n' "$text"
  fi
  return "$rc"
}

emit_error() {
  local rc="$1" code="$2" reason="$3" payload
  payload="$(jq -nc --arg schema "codex-stuck-detector.error.v1" --arg version "$VERSION" --arg code "$code" --arg reason "$reason" '{schema_version:$schema,version:$version,status:"fail",success:false,code:$code,reason:$reason}')"
  emit "$payload" "ERR: $reason" "$rc"
}

append_validated() {
  local path="$1" row="$2"
  if [[ ! -r "$JSONL_APPEND_LIB" ]]; then
    echo "ERR: JSONL append primitive missing: $JSONL_APPEND_LIB" >&2
    return 3
  fi
  # shellcheck source=/dev/null
  source "$JSONL_APPEND_LIB"
  fw_jsonl_append_validated "$path" "$row"
}

contract_rows_json() {
  if [[ -s "$CONTRACT_LEDGER" ]]; then
    jq -s -c 'map(select(type == "object"))' "$CONTRACT_LEDGER" 2>/dev/null || printf '[]\n'
  else
    printf '[]\n'
  fi
}

contract_self_row_json() {
  jq -nc \
    --arg ts "$(now_iso)" \
    --arg schema_version "$CONTRACT_SCHEMA_VERSION" \
    '{primitive_name:"codex-stuck-detector",declares_loop:"yes",self_repair_action:"codex-template-stuck-detector.sh repair --scope all --apply",measurement_field:"codex_template_stuck_count_24h",escalation_path:"/flywheel:respawn for input_deaf or post_completion; fuckup-log:class=codex-template-buffer-stuck after failed enter retry",schema_version:$schema_version,bootstrap_seed_v1:"mk303 codex template stuck detector self-row",ts:$ts}'
}

valid_contract_self_row_present() {
  contract_rows_json | jq -e --arg schema "$CONTRACT_SCHEMA_VERSION" '
    [ .[] | select(.primitive_name == "codex-stuck-detector") ]
    | last
    | type == "object"
      and .declares_loop == "yes"
      and (.self_repair_action // "") != ""
      and (.measurement_field // "") == "codex_template_stuck_count_24h"
      and (.escalation_path // "") != ""
      and .schema_version == $schema
      and (.bootstrap_seed_v1 // "") != ""
  ' >/dev/null
}

ensure_contract_self_row() {
  if valid_contract_self_row_present; then
    printf 'present\n'
    return 0
  fi
  append_validated "$CONTRACT_LEDGER" "$(contract_self_row_json)"
  printf 'appended\n'
}

info_json() {
  jq -nc \
    --arg name "codex-template-stuck-detector.sh" \
    --arg version "$VERSION" \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg repo "$REPO_ROOT" \
    --arg ledger "$LEDGER" \
    --arg contract_ledger "$CONTRACT_LEDGER" \
    --arg fuckup_log "$FUCKUP_LOG" \
    --arg topology "$TOPOLOGY_LEDGER" \
    --arg ntm "$NTM_BIN" \
    --argjson window "$WINDOW_SEC" \
    --argjson lines "$LINES" \
    '{name:$name,version:$version,schema_version:$schema_version,repo:$repo,ledger:$ledger,substrate_loop_contract_ledger:$contract_ledger,fuckup_log:$fuckup_log,topology_ledger:$topology,ntm_bin:$ntm,defaults:{dry_run:true,window_sec:$window,lines:$lines,auto_recover_requires_apply:true},subclasses:["alive","buffer_stuck","post_completion","input_deaf","post_callback_reminder_template_with_stale_spinner","model_at_capacity_halt","codex_queued_not_submitted","oom_killed_pane","unknown_stable"],safe_recovery_policy:{buffer_stuck:"enter_newline_only",input_deaf:"respawn_escalation_only",post_completion:"respawn_escalation_only",post_callback_reminder_template_with_stale_spinner:"escape_then_reprompt_or_respawn",model_at_capacity_halt:"auto_continue",codex_queued_not_submitted:"bare_enter",oom_killed_pane:"respawn",auto_respawn:"subclass-gated"},exit_codes:{"0":"ok or alive/no stuck panes","1":"stuck class detected or doctor threshold failed","2":"usage error","3":"append primitive unavailable or append failed"}}'
}

examples_text() {
  cat <<'EOF'
codex-template-stuck-detector.sh --session flywheel --pane 2 --json
codex-template-stuck-detector.sh --session all --worker-panes-from-topology --apply --json
codex-template-stuck-detector.sh --fixture /tmp/buffer-stuck.json --auto-recover --apply --json
codex-template-stuck-detector.sh --doctor --json | jq '.codex_template_stuck_count_24h'
codex-template-stuck-detector.sh repair --scope all --apply --json
EOF
}

quickstart_text() {
  cat <<'EOF'
1. Run with --session and --pane to take two ntm copies separated by the window.
2. Stable hash gates generic template/Working classes; post-callback reminder + stale spinner can classify through cosmetic hash drift.
3. Add --apply to write the audit ledger.
4. Add --auto-recover --apply for buffer_stuck Enter retry, model_at_capacity_halt auto_continue, or codex_queued_not_submitted bare_enter.
5. input_deaf and post_completion never auto-respawn; route them to /flywheel:respawn.
EOF
}

schema_json() {
  case "$SCHEMA_TOPIC" in
    detect)
      jq -nc '{schema_version:"codex-stuck-detector.detect.v1",required:["session","pane","subclass","hash_t0","hash_t1","hash_stable","recommended_recovery"]}' ;;
    doctor)
      jq -nc '{schema_version:"codex-stuck-detector.doctor.v1",required:["codex_stuck_detector_last_fired_ts","codex_template_stuck_count_24h","codex_stuck_subclass_top","codex_stuck_top_session","codex_stuck_recovery_success_pct"]}' ;;
    ledger)
      jq -nc '{schema_version:"codex-stuck-detector.ledger.v1",required:["ts","session","pane","subclass","hash_t0","hash_t1","window_sec","buffer_signal","recovery_attempted","recovery_succeeded"]}' ;;
    contract)
      jq -nc --arg schema_version "$CONTRACT_SCHEMA_VERSION" '{schema_version:$schema_version,required:["primitive_name","declares_loop","self_repair_action","measurement_field","escalation_path","schema_version","bootstrap_seed_v1"]}' ;;
    fixture)
      jq -nc '{schema_version:"codex-stuck-detector.fixture.v1",required:["session","pane","t0","t1"],optional:["after_retry","send_ack","subclass_hint"]}' ;;
    *)
      echo "ERR: unknown schema topic: $SCHEMA_TOPIC" >&2
      return 2 ;;
  esac
}

completion() {
  case "$COMPLETION_SHELL" in
    bash)
      cat <<'EOF'
_codex_template_stuck_detector_completion() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "--session --pane --worker-panes-from-topology --fixture --fixture-dir --window-sec --lines --doctor health repair validate audit why schema --dry-run --apply --auto-recover --json --info --examples quickstart help completion --scope --watch --interval" -- "$cur") )
}
complete -F _codex_template_stuck_detector_completion codex-template-stuck-detector.sh
EOF
      ;;
    zsh)
      printf 'compadd -- --session --pane --worker-panes-from-topology --fixture --fixture-dir --window-sec --lines --doctor health repair validate audit why schema --dry-run --apply --auto-recover --json --info --examples quickstart help completion --scope --watch --interval\n'
      ;;
    *)
      echo "ERR: completion shell must be bash or zsh" >&2
      return 2 ;;
  esac
}

detector_py() {
  local py_mode="$1" contract_action="${2:-not_requested}"
  python3 - "$py_mode" "$REPO_ROOT" "$LEDGER" "$CONTRACT_LEDGER" "$FUCKUP_LOG" "$TOPOLOGY_LEDGER" "$NTM_BIN" "$CAPACITY_AUTO_CONTINUE" "$QUEUED_BARE_ENTER" "$SESSION_NAME" "$PANE" "$FIXTURE" "$FIXTURE_DIR" "$WINDOW_SEC" "$LINES" "$APPLY" "$DRY_RUN" "$AUTO_RECOVER" "$WORKER_PANES_FROM_TOPOLOGY" "$VERSION" "$SCHEMA_VERSION" "$contract_action" "$VALIDATE_TARGET" "$WHY_ID" "$OOM_KILLED_RESPAWN" <<'PY'
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
import time
from collections import Counter, defaultdict
from datetime import datetime, timezone, timedelta
from pathlib import Path

(
    mode,
    repo_raw,
    ledger_raw,
    contract_ledger_raw,
    fuckup_log_raw,
    topology_raw,
    ntm_bin,
    capacity_auto_continue_raw,
    queued_bare_enter_raw,
    session_name,
    pane_raw,
    fixture_raw,
    fixture_dir_raw,
    window_raw,
    lines_raw,
    apply_raw,
    dry_raw,
    auto_recover_raw,
    worker_panes_raw,
    version,
    schema_version,
    contract_action,
    validate_target,
    why_id,
    oom_killed_respawn_raw,
) = sys.argv[1:]

repo = Path(repo_raw)
ledger = Path(ledger_raw)
contract_ledger = Path(contract_ledger_raw)
fuckup_log = Path(fuckup_log_raw)
topology = Path(topology_raw)
capacity_auto_continue = Path(capacity_auto_continue_raw)
queued_bare_enter = Path(queued_bare_enter_raw)
oom_killed_respawn = Path(oom_killed_respawn_raw) if oom_killed_respawn_raw else None
fixture = Path(fixture_raw) if fixture_raw else None
fixture_dir = Path(fixture_dir_raw) if fixture_dir_raw else None
window_sec = int(float(window_raw))
lines = int(float(lines_raw))
apply = apply_raw == "1"
dry_run = dry_raw == "1"
auto_recover = auto_recover_raw == "1"
worker_panes_from_topology = worker_panes_raw == "1"
now = os.environ.get("CODEX_STUCK_DETECTOR_NOW") or datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

PLACEHOLDER_RE = re.compile(r"(?:^|\s)(?:›\s*)?(Implement \{feature\}|Run /review|Use /skills)(?:\s|$)")
CAPACITY_HALT_RE = re.compile(r"(selected model is at capacity|please try a different model)", re.I)
CHEVRON_PROMPT_RE = re.compile(r"^\s*›(?:\s|$)", re.M)
QUEUED_PROMPT_RE = re.compile(r"^\s*›[ \t]+(.{1,200})\s*$", re.M)
BACKGROUND_SPINNER_RE = re.compile(
    r"(?:Waiting for background terminal|Working)\s*\((?:(\d+)h\s*)?(?:(\d+)m\s*)?(\d+)s\s*[·•]\s*esc(?:\s+to\s+interrupt|…|\.\.\.)?",
    re.I,
)
REMINDER_PROMPT_RE = re.compile(
    r"^›\s*(Implement \{feature\}|Explain this codebase|Summarize recent commits|Find and fix a bug in @filename|Write tests for @filename|Use /skills to list available skills|Use /init to create an AGENTS\.md file|Run /review on my (?:current )?changes)\s*$",
    re.M,
)
POST_CALLBACK_DONE_RE = re.compile(r"(^•\s*Done\.|Done\..*implemented and closed|^Changed:)", re.M)
WORKING_RE = re.compile(r"Working \((?:(\d+)h)?\s*(?:(\d+)m)?\s*(?:(\d+)s)?", re.I)
POST_CALLBACK_SUBCLASS = "post_callback_reminder_template_with_stale_spinner"
CAPACITY_HALT_SUBCLASS = "model_at_capacity_halt"
QUEUED_NOT_SUBMITTED_SUBCLASS = "codex_queued_not_submitted"
OOM_KILLED_SUBCLASS = "oom_killed_pane"
# OOM/cgroup-killed signature: kernel/process death markers that show in tmux pane after codex CLI is OOM-killed.
# Matches: "Killed", "killed: 9", "out of memory", "Out of memory: Killed process", "oom-kill",
# bash exit message "[Process completed]", or "[exited]" markers.
OOM_KILLED_RE = re.compile(
    r"(\bKilled\b|killed:\s*9|[Oo]ut of memory|oom[-_]kill|cgroup.*oom|\[Process completed\]|\[exited\]|process\s+killed)",
)
POST_CALLBACK_SIGNAL = "stale_background_spinner_with_reminder_template"
STATIC_REMINDER_PROMPTS = {"Implement {feature}", "Explain this codebase", "Summarize recent commits", "Find and fix a bug in @filename", "Write tests for @filename", "Use /skills to list available skills", "Use /init to create an AGENTS.md file"}

def sha(text):
    return hashlib.sha256(text.encode("utf-8", errors="replace")).hexdigest()

def parse_ts(value):
    if not isinstance(value, str) or not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None

class ProbeFailure(RuntimeError):
    pass

def read_json(path):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except Exception as exc:
        return {"error": f"{type(exc).__name__}: {exc}"}

def read_fixture(path):
    path = Path(path)
    if path.is_dir():
        t0_path = path / "t0.txt"
        t1_path = path / "t1.txt"
        payload = {
            "schema_version": "codex-stuck-detector.fixture.v1",
            "session": session_name or "fixture",
            "pane": int(pane_raw) if str(pane_raw).isdigit() else (pane_raw or 1),
            "t0": t0_path.read_text(encoding="utf-8", errors="replace") if t0_path.exists() else "",
            "t1": t1_path.read_text(encoding="utf-8", errors="replace") if t1_path.exists() else "",
        }
        after_retry = path / "after_retry.txt"
        if after_retry.exists():
            payload["after_retry"] = after_retry.read_text(encoding="utf-8", errors="replace")
        return payload
    return read_json(path)

def fixture_text_for_pane(payload, pane_hint):
    if not isinstance(payload, dict):
        return ""
    if "t1" in payload or "t0" in payload:
        return str(payload.get("t1") or payload.get("t0") or "")
    panes = payload.get("panes")
    if not isinstance(panes, dict):
        return ""
    pane_key = str(pane_hint or payload.get("pane") or "")
    pane_payload = panes.get(pane_key)
    if pane_payload is None and len(panes) == 1:
        pane_key, pane_payload = next(iter(panes.items()))
        payload["pane"] = int(pane_key) if pane_key.isdigit() else pane_key
    if isinstance(pane_payload, dict):
        lines = pane_payload.get("lines")
        if isinstance(lines, list):
            return "\n".join(str(line) for line in lines)
        text = pane_payload.get("text")
        if isinstance(text, str):
            return text
    if isinstance(pane_payload, list):
        return "\n".join(str(line) for line in pane_payload)
    if isinstance(pane_payload, str):
        return pane_payload
    return ""

def read_jsonl(path):
    rows = []
    try:
        for line in Path(path).read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(row, dict):
                rows.append(row)
    except FileNotFoundError:
        pass
    return rows

def latest_topology_rows():
    latest = {}
    for row in read_jsonl(topology):
        session = row.get("session")
        if not session:
            continue
        prev = latest.get(session)
        if prev is None or str(row.get("effective_at") or "") >= str(prev.get("effective_at") or ""):
            latest[session] = row
    return latest

def topology_targets():
    targets = []
    if fixture:
        fx = read_fixture(fixture)
        pane_hint = fx.get("pane") or pane_raw
        if not pane_hint and isinstance(fx.get("panes"), dict) and len(fx["panes"]) == 1:
            pane_hint = next(iter(fx["panes"].keys()))
        return [(str(fx.get("session") or session_name or "fixture"), str(pane_hint or "1"), fx)]
    if fixture_dir and fixture_dir.exists():
        for path in sorted(fixture_dir.glob("*.json")):
            fx = read_json(path)
            pane_hint = fx.get("pane")
            if not pane_hint and isinstance(fx.get("panes"), dict) and len(fx["panes"]) == 1:
                pane_hint = next(iter(fx["panes"].keys()))
            targets.append((str(fx.get("session") or path.stem), str(pane_hint or "1"), fx))
        return targets
    if worker_panes_from_topology or session_name == "all":
        for session, row in latest_topology_rows().items():
            if row.get("session_status") and "not_live" in str(row.get("session_status")):
                continue
            orch = row.get("orchestrator_pane")
            callback = row.get("callback_pane")
            human = row.get("human_pane")
            worker_kinds = row.get("worker_kinds") if isinstance(row.get("worker_kinds"), dict) else {}
            for pane in row.get("worker_panes") or []:
                pane_s = str(pane)
                if pane == orch or pane == callback or pane == human:
                    continue
                if str(worker_kinds.get(pane_s) or worker_kinds.get(pane) or "codex").lower() != "codex":
                    continue
                targets.append((session, pane_s, None))
        return targets
    if not session_name or not pane_raw:
        return []
    return [(session_name, str(pane_raw), None)]

def ntm_copy(session, pane):
    safe_session = re.sub(r"[^A-Za-z0-9_.-]+", "-", str(session))
    safe_pane = re.sub(r"[^A-Za-z0-9_.-]+", "-", str(pane))
    copy_path = Path(tempfile.gettempdir()) / f"codex-stuck-detector-copy-{os.getpid()}-{safe_session}-{safe_pane}.txt"
    try:
        proc = subprocess.run(
            [ntm_bin, "copy", f"{session}:{pane}", "-l", str(lines), "--output", str(copy_path), "--quiet"],
            text=True,
            capture_output=True,
        )
        if proc.returncode == 0 and copy_path.exists():
            text = copy_path.read_text(encoding="utf-8", errors="replace")
            if text.strip():
                return text
        fallback = subprocess.run([ntm_bin, f"--robot-tail={session}", f"--panes={pane}", f"--lines={lines}"], text=True, capture_output=True)
        if fallback.returncode == 0 and fallback.stdout:
            try:
                payload = json.loads(fallback.stdout)
                text = "\n".join(payload.get("panes", {}).get(str(pane), {}).get("lines", []))
                if text.strip():
                    return text
            except Exception:
                if fallback.stdout.strip():
                    return fallback.stdout
        detail = (proc.stderr or proc.stdout or "").strip() or (fallback.stderr or fallback.stdout or "").strip()
        raise ProbeFailure(f"ntm copy failed for {session}:{pane}: {detail[-500:]}")
    finally:
        try:
            copy_path.unlink()
        except FileNotFoundError:
            pass

def capture_pair(session, pane, fixture_payload=None):
    if fixture_payload is not None:
        text = fixture_text_for_pane(fixture_payload, pane)
        t0 = str(fixture_payload.get("t0") or text)
        t1 = str(fixture_payload.get("t1") or text)
        after = str(fixture_payload.get("after_retry") or t1)
        return t0, t1, after, fixture_payload
    t0 = ntm_copy(session, pane)
    time.sleep(window_sec)
    t1 = ntm_copy(session, pane)
    return t0, t1, "", None

def working_seconds(text):
    best = 0
    for match in WORKING_RE.finditer(text):
        h = int(match.group(1) or 0)
        m = int(match.group(2) or 0)
        s = int(match.group(3) or 0)
        best = max(best, h * 3600 + m * 60 + s)
    return best

def stale_background_spinner_seconds(text):
    lines = text.splitlines()
    best = 0
    for line in lines[-30:]:
        for match in BACKGROUND_SPINNER_RE.finditer(line):
            h = int(match.group(1) or 0)
            m = int(match.group(2) or 0)
            s = int(match.group(3) or 0)
            best = max(best, h * 3600 + m * 60 + s)
    return best

def has_reminder_prompt(text):
    return REMINDER_PROMPT_RE.search("\n".join(text.splitlines()[-10:])) is not None

def has_stale_spinner_reminder(text):
    tail30 = "\n".join(text.splitlines()[-30:])
    return has_reminder_prompt(text) and (
        stale_background_spinner_seconds(text) > 90 or POST_CALLBACK_DONE_RE.search(tail30) is not None
    )

def queued_prompt_text(text):
    matches = [match.group(1).strip() for match in QUEUED_PROMPT_RE.finditer(text)]
    if not matches:
        return ""
    candidate = matches[-1]
    return "" if candidate in STATIC_REMINDER_PROMPTS or CAPACITY_HALT_RE.search(candidate) else candidate

def has_queued_not_submitted_prompt(text):
    tail40 = "\n".join(text.splitlines()[-40:])
    return not (POST_CALLBACK_DONE_RE.search(tail40) or has_capacity_halt_prompt(text)) and bool(queued_prompt_text(text)) and (working_seconds(text) >= 60 or BACKGROUND_SPINNER_RE.search(text) is not None)

def evidence_signal_lines(text):
    return [
        line
        for line in text.splitlines()
        if PLACEHOLDER_RE.search(line) or CAPACITY_HALT_RE.search(line) or QUEUED_PROMPT_RE.search(line) or REMINDER_PROMPT_RE.search(line) or BACKGROUND_SPINNER_RE.search(line) or "Working (" in line
    ]

def buffer_signal(text):
    if has_stale_spinner_reminder(text):
        return POST_CALLBACK_SIGNAL
    if PLACEHOLDER_RE.search(text):
        return PLACEHOLDER_RE.search(text).group(1)
    secs = working_seconds(text)
    if secs >= 600:
        return f"Working>{secs}s"
    return "none"

def has_oom_killed_signature(text):
    # No chevron prompt + no capacity halt + OOM/dead-process marker in tail.
    if CHEVRON_PROMPT_RE.search(text):
        return False
    if CAPACITY_HALT_RE.search(text):
        return False
    tail = "\n".join(text.splitlines()[-50:])
    return OOM_KILLED_RE.search(tail) is not None

def has_capacity_halt_prompt(text):
    tail = "\n".join(text.splitlines()[-50:] + evidence_signal_lines(text)[-8:])
    return CAPACITY_HALT_RE.search(tail) is not None and CHEVRON_PROMPT_RE.search(tail) is not None

def classify_text(session, pane, t0, t1, fixture_payload):
    fixture_payload = fixture_payload or {}
    stable = sha(t0) == sha(t1)
    signal = buffer_signal(t1)
    hint = str(fixture_payload.get("subclass_hint") or "")
    if hint in {"input_deaf", "post_completion", "buffer_stuck", POST_CALLBACK_SUBCLASS, CAPACITY_HALT_SUBCLASS, QUEUED_NOT_SUBMITTED_SUBCLASS, OOM_KILLED_SUBCLASS}:
        subclass = hint
    elif has_oom_killed_signature(t1):
        subclass = OOM_KILLED_SUBCLASS
    elif has_capacity_halt_prompt(t1):
        subclass = CAPACITY_HALT_SUBCLASS
    elif has_queued_not_submitted_prompt(t1):
        subclass = QUEUED_NOT_SUBMITTED_SUBCLASS
    elif signal == POST_CALLBACK_SIGNAL:
        subclass = POST_CALLBACK_SUBCLASS
    elif not stable:
        return "alive", stable, signal, "none", False
    elif working_seconds(t1) >= 600:
        subclass = "post_completion"
    elif PLACEHOLDER_RE.search(t1):
        subclass = "buffer_stuck"
    elif CHEVRON_PROMPT_RE.search(t1) and not queued_prompt_text(t1) and signal == "none":
        return "alive", stable, signal, "none", False
    else:
        subclass = "unknown_stable"
    stuck = subclass in {"buffer_stuck", "post_completion", "input_deaf", POST_CALLBACK_SUBCLASS, CAPACITY_HALT_SUBCLASS, QUEUED_NOT_SUBMITTED_SUBCLASS, OOM_KILLED_SUBCLASS}
    recovery = {
        "buffer_stuck": "enter_newline_then_respawn_if_still_stuck",
        "input_deaf": "/flywheel:respawn_after_peer_orch_recovery_gate",
        "post_completion": "/flywheel:respawn_after_snapshot",
        POST_CALLBACK_SUBCLASS: "escape_then_reprompt_or_respawn",
        CAPACITY_HALT_SUBCLASS: "auto_continue",
        QUEUED_NOT_SUBMITTED_SUBCLASS: "bare_enter",
        OOM_KILLED_SUBCLASS: "respawn",
        "unknown_stable": "recapture_then_manual_review",
        "alive": "none",
    }.get(subclass, "manual_review")
    return subclass, stable, signal, recovery, stuck

def send_enter_retry(session, pane, fixture_payload):
    if fixture_payload:
        return bool(fixture_payload.get("send_ack", True)), "fixture"
    if not apply or dry_run:
        return False, "preview"
    proc = subprocess.run([ntm_bin, "send", session, f"--pane={pane}", "--no-cass-check", "\n"], text=True, capture_output=True)
    return proc.returncode == 0 and "Sent" in (proc.stdout + proc.stderr), (proc.stdout + proc.stderr)[-200:]

def write_unknown_snapshot(session, pane, t0, t1):
    snapshot_dir = Path(os.environ.get("CODEX_STUCK_DETECTOR_SNAPSHOT_DIR") or "/tmp")
    snapshot_dir.mkdir(parents=True, exist_ok=True)
    safe_session = re.sub(r"[^A-Za-z0-9_.-]+", "-", str(session))
    safe_pane = re.sub(r"[^A-Za-z0-9_.-]+", "-", str(pane))
    digest = sha(t1)[:12]
    path = snapshot_dir / f"codex-stuck-unknown-stable-{safe_session}-{safe_pane}-{digest}.json"
    payload = {
        "schema_version": "codex-stuck-detector.unknown-stable-snapshot.v1",
        "ts": now,
        "session": session,
        "pane": int(pane) if str(pane).isdigit() else pane,
        "hash_t0": sha(t0),
        "hash_t1": sha(t1),
        "t0": t0,
        "t1": t1,
    }
    tmp = path.with_suffix(path.suffix + f".{os.getpid()}.tmp")
    tmp.write_text(json.dumps(payload, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    tmp.replace(path)
    return str(path)

def run_recovery_primitive(session, pane):
    recovery_script = repo / ".flywheel/scripts/recovery-escape-then-reprompt.sh"
    if not recovery_script.exists():
        return {"recovery_succeeded": False, "stage_succeeded": "none", "error": "recovery_script_missing"}
    proc = subprocess.run(
        [str(recovery_script), "--session", str(session), "--pane", str(pane), "--apply", "--json"],
        text=True,
        capture_output=True,
    )
    try:
        payload = json.loads(proc.stdout)
    except json.JSONDecodeError:
        payload = {
            "recovery_succeeded": False,
            "stage_succeeded": "none",
            "error": (proc.stderr or proc.stdout)[-500:],
        }
    payload["returncode"] = proc.returncode
    return payload

def run_capacity_auto_continue(session, pane, digest):
    if not capacity_auto_continue.exists():
        return {"recovered": False, "sent": False, "returncode": 3, "error": "capacity_auto_continue_primitive_missing"}
    env = os.environ.copy()
    env["CAPACITY_HALT_AUTO_CONTINUE_NTM_BIN"] = str(ntm_bin)
    proc = subprocess.run(
        [str(capacity_auto_continue), "--session", str(session), "--pane", str(pane), "--digest", digest, "--apply", "--json"],
        text=True,
        capture_output=True,
        env=env,
    )
    try:
        payload = json.loads(proc.stdout)
    except json.JSONDecodeError:
        payload = {"recovered": False, "sent": False, "error": (proc.stderr or proc.stdout)[-500:]}
    payload["returncode"] = proc.returncode
    return payload

def run_queued_bare_enter(session, pane, digest):
    if not queued_bare_enter.exists():
        return {"recovered": False, "sent": False, "returncode": 3, "error": "queued_bare_enter_primitive_missing"}
    env = os.environ.copy(); env["CODEX_QUEUED_BARE_ENTER_NTM_BIN"] = str(ntm_bin)
    proc = subprocess.run([str(queued_bare_enter), "--session", str(session), "--pane", str(pane), "--digest", digest, "--apply", "--json"], text=True, capture_output=True, env=env)
    try:
        payload = json.loads(proc.stdout)
    except json.JSONDecodeError:
        payload = {"recovered": False, "sent": False, "error": (proc.stderr or proc.stdout)[-500:]}
    payload["returncode"] = proc.returncode; return payload

def run_oom_killed_respawn(session, pane, digest):
    # Recovery for oom_killed_pane: codex process is gone, respawn the pane.
    # Mock-friendly: in fixture/dry-run mode, we never invoke ntm.
    # Live: ntm respawn <session> --panes=<N> --force
    if oom_killed_respawn is None or not oom_killed_respawn.exists():
        return {"recovered": False, "sent": False, "returncode": 3, "error": "oom_killed_respawn_primitive_missing"}
    env = os.environ.copy()
    env["CODEX_OOM_KILLED_RESPAWN_NTM_BIN"] = str(ntm_bin)
    proc = subprocess.run(
        [str(oom_killed_respawn), "respawn", str(session), f"--panes={pane}", "--force"],
        text=True,
        capture_output=True,
        env=env,
    )
    payload = {
        "recovered": proc.returncode == 0,
        "sent": proc.returncode == 0,
        "returncode": proc.returncode,
        "digest": digest,
        "stdout_tail": (proc.stdout or "")[-300:],
        "stderr_tail": (proc.stderr or "")[-300:],
    }
    return payload

def detect_one(session, pane, fixture_payload=None):
    t0, t1, after_retry, fixture_payload = capture_pair(session, pane, fixture_payload)
    subclass, stable, signal, recommended, stuck = classify_text(session, pane, t0, t1, fixture_payload)
    hash_t0 = sha(t0)
    hash_t1 = sha(t1)
    evidence_lines = evidence_signal_lines(t1)[-8:]
    recovery_attempted = "none"
    recovery_succeeded = None
    send_ack = None
    post_retry_hash = None
    recovery_payload = None
    if auto_recover and subclass == "buffer_stuck":
        recovery_attempted = "enter_newline"
        if apply and not dry_run:
            send_ack, send_detail = send_enter_retry(session, pane, fixture_payload)
            if fixture_payload:
                post_text = after_retry
            else:
                time.sleep(1)
                post_text = ntm_copy(session, pane)
            post_retry_hash = sha(post_text)
            recovery_succeeded = post_retry_hash != hash_t1
            if send_ack and not recovery_succeeded:
                subclass = "input_deaf"
                recommended = "/flywheel:respawn_after_peer_orch_recovery_gate"
                signal = signal if signal != "none" else "input_deaf_after_enter_retry"
        else:
            recovery_succeeded = False
    elif subclass == POST_CALLBACK_SUBCLASS:
        recovery_attempted = "escape_then_reprompt_or_respawn"
        if apply and not dry_run and fixture_payload is None:
            recovery_payload = run_recovery_primitive(session, pane)
            recovery_succeeded = bool(recovery_payload.get("recovery_succeeded"))
        else:
            recovery_succeeded = False
    elif auto_recover and subclass == CAPACITY_HALT_SUBCLASS:
        recovery_attempted = "capacity_halt_auto_continue"
        if apply and not dry_run:
            recovery_payload = run_capacity_auto_continue(session, pane, hash_t1)
            recovery_succeeded = bool(recovery_payload.get("recovered")) or recovery_payload.get("returncode") == 0
        else:
            recovery_succeeded = False
    elif auto_recover and subclass == QUEUED_NOT_SUBMITTED_SUBCLASS:
        recovery_attempted = "bare_enter"
        if apply and not dry_run:
            recovery_payload = run_queued_bare_enter(session, pane, hash_t1)
            recovery_succeeded = bool(recovery_payload.get("recovered")) or recovery_payload.get("returncode") == 0
        else:
            recovery_succeeded = False
    elif auto_recover and subclass == OOM_KILLED_SUBCLASS:
        recovery_attempted = "ntm_respawn"
        if apply and not dry_run and fixture_payload is None:
            recovery_payload = run_oom_killed_respawn(session, pane, hash_t1)
            recovery_succeeded = bool(recovery_payload.get("recovered")) or recovery_payload.get("returncode") == 0
        else:
            # Fixture/dry-run: do NOT invoke ntm. Mock-only success contract for tests.
            recovery_payload = {"recovered": False, "sent": False, "returncode": None, "mocked": True, "digest": hash_t1}
            recovery_succeeded = False
    auto_recover_eligible = auto_recover or subclass in {POST_CALLBACK_SUBCLASS, CAPACITY_HALT_SUBCLASS, QUEUED_NOT_SUBMITTED_SUBCLASS, OOM_KILLED_SUBCLASS}
    ledger_row = {
        "schema_version": "codex-stuck-detector.ledger.v1",
        "version": version,
        "ts": now,
        "session": session,
        "pane": int(pane) if str(pane).isdigit() else pane,
        "subclass": subclass,
        "hash_t0": hash_t0,
        "hash_t1": hash_t1,
        "window_sec": window_sec,
        "buffer_signal": signal,
        "recovery_attempted": recovery_attempted,
        "recovery_succeeded": recovery_succeeded,
        "recommended_recovery": recommended,
        "hash_stable": stable,
        "auto_recover": auto_recover_eligible,
    }
    fuckup_row = None
    if apply and subclass == "unknown_stable" and stable:
        pane_capture_path = write_unknown_snapshot(session, pane, t0, t1)
        fuckup_row = {
            "schema_version": "flywheel-fuckup-log.v1",
            "ts": now,
            "class": "detector_silent_exit2",
            "severity": "high",
            "what_happened": f"codex stuck detector classified {session}:{pane} as unknown_stable; detector emitted JSON and rc=2 instead of silently passing",
            "session": session,
            "pane": int(pane) if str(pane).isdigit() else pane,
            "bead": "flywheel-detector-silent-exit2-166f",
            "parent_bead": "flywheel-2h3vs",
            "legacy_class": "detector-pattern-bank-gap",
            "pane_capture_path": pane_capture_path,
            "recommended_recovery": "fix_live_capture_or_add_pattern_bank_fixture",
            "evidence_lines": evidence_lines,
        }
    if apply and auto_recover and subclass in {"input_deaf", "post_completion"} and stuck:
        fuckup_row = {
            "schema_version": "flywheel-fuckup-log.v1",
            "ts": now,
            "class": f"codex-{subclass.replace('_', '-')}",
            "severity": "high",
            "what_happened": f"codex stuck detector classified {session}:{pane} as {subclass}",
            "session": session,
            "pane": int(pane) if str(pane).isdigit() else pane,
            "bead": "flywheel-mk303",
            "recommended_recovery": recommended,
            "evidence_lines": evidence_lines,
        }
    return {
        "schema_version": "codex-stuck-detector.detect.v1",
        "version": version,
        "status": "stuck" if stuck else "ok",
        "session": session,
        "pane": int(pane) if str(pane).isdigit() else pane,
        "subclass": subclass,
        "hash_t0": hash_t0,
        "hash_t1": hash_t1,
        "hash_stable": stable,
        "window_sec": window_sec,
        "buffer_signal": signal,
        "evidence_lines": evidence_lines,
        "recommended_recovery": recommended,
        "recovery_attempted": recovery_attempted,
        "recovery_succeeded": recovery_succeeded,
        "recovery_payload": recovery_payload,
        "post_retry_hash": post_retry_hash,
        "auto_recover": auto_recover_eligible,
        "apply": apply,
        "dry_run": not apply or dry_run,
        "ledger_row": ledger_row,
        "fuckup_row": fuckup_row,
    }

def detect_payload():
    targets = topology_targets()
    rows = []
    ledger_rows = []
    fuckup_rows = []
    for session, pane, fx in targets:
        try:
            row = detect_one(session, pane, fx)
        except ProbeFailure as exc:
            row = {
                "schema_version": "codex-stuck-detector.detect.v1",
                "version": version,
                "status": "probe_failure",
                "session": session,
                "pane": int(pane) if str(pane).isdigit() else pane,
                "subclass": "probe_failure",
                "hash_t0": "",
                "hash_t1": "",
                "hash_stable": False,
                "window_sec": window_sec,
                "buffer_signal": "probe_failure",
                "evidence_lines": [],
                "recommended_recovery": "retry_probe_or_check_ntm_copy",
                "recovery_attempted": "none",
                "recovery_succeeded": None,
                "recovery_payload": None,
                "post_retry_hash": None,
                "auto_recover": False,
                "apply": apply,
                "dry_run": not apply or dry_run,
                "error": str(exc),
            }
        rows.append(row)
        if apply:
            ledger_row = row.get("ledger_row")
            if ledger_row:
                ledger_rows.append(ledger_row)
        if row.get("fuckup_row"):
            fuckup_rows.append(row["fuckup_row"])
    stuck_rows = [r for r in rows if r.get("status") == "stuck"]
    unknown_rows = [r for r in rows if r.get("subclass") == "unknown_stable"]
    probe_failures = [r for r in rows if r.get("status") == "probe_failure"]
    status = "ok"
    if probe_failures:
        status = "probe_failure"
    elif stuck_rows:
        status = "stuck"
    elif unknown_rows:
        status = "unknown_stable"
    payload = {
        "schema_version": "codex-stuck-detector.detect.v1",
        "version": version,
        "status": status,
        "success": not probe_failures,
        "ts": now,
        "mode": "detect",
        "apply": apply,
        "dry_run": not apply or dry_run,
        "auto_recover": auto_recover,
        "targets_checked": len(targets),
        "stuck_count": len(stuck_rows),
        "unknown_stable_count": len(unknown_rows),
        "probe_failure_count": len(probe_failures),
        "panes": rows,
        "ledger_path": str(ledger),
        "fuckup_log": str(fuckup_log),
        "ledger_rows": ledger_rows,
        "fuckup_rows": fuckup_rows,
    }
    if len(rows) == 1:
        row = rows[0]
        for key in ("session", "pane", "subclass", "buffer_signal", "recommended_recovery", "recovery_attempted", "recovery_succeeded"):
            payload[key] = row.get(key)
    return payload

def doctor_payload():
    rows = read_jsonl(ledger)
    doctor_now = parse_ts(now) or datetime.now(timezone.utc)
    cutoff = doctor_now - timedelta(hours=24)
    last_fired_ts = None
    ts_values = [row.get("ts") for row in rows if parse_ts(row.get("ts"))]
    if ts_values:
        last_fired_ts = max(ts_values)
    recent = []
    for row in rows:
        dt = parse_ts(row.get("ts"))
        if dt and dt >= cutoff and row.get("subclass") in {"buffer_stuck", "input_deaf", "post_completion", POST_CALLBACK_SUBCLASS, CAPACITY_HALT_SUBCLASS, QUEUED_NOT_SUBMITTED_SUBCLASS, OOM_KILLED_SUBCLASS}:
            recent.append(row)
    count = len(recent)
    subclass_top = None
    top_session = None
    if recent:
        subclass_top = Counter(str(r.get("subclass")) for r in recent).most_common(1)[0][0]
        top_session = Counter(str(r.get("session")) for r in recent).most_common(1)[0][0]
    recoveries = [r for r in recent if r.get("recovery_attempted") and r.get("recovery_attempted") != "none"]
    success_pct = None
    if recoveries:
        success_pct = round(100 * sum(1 for r in recoveries if r.get("recovery_succeeded") is True) / len(recoveries), 2)
    status = "ok"
    warnings = []
    errors = []
    if count > 25:
        status = "fail"
        errors.append({"code": "codex_stuck_count_24h_error", "count": count, "threshold": 25})
    elif count > 10:
        status = "warn"
        warnings.append({"code": "codex_stuck_count_24h_warn", "count": count, "threshold": 10})
    if last_fired_ts is None and status == "ok":
        status = "warn"
        warnings.append({"code": "codex_stuck_detector_last_fired_missing", "threshold_hours": 24})
    return {
        "schema_version": "codex-stuck-detector.doctor.v1",
        "version": version,
        "status": status,
        "ts": now,
        "ledger_path": str(ledger),
        "codex_stuck_detector_last_fired_ts": last_fired_ts,
        "codex_template_stuck_count_24h": count,
        "codex_stuck_subclass_top": subclass_top,
        "codex_stuck_top_session": top_session,
        "codex_stuck_recovery_success_pct": success_pct,
        "thresholds": {"warn_count_24h": 10, "error_count_24h": 25},
        "substrate_loop_contract_self_row_action": contract_action,
        "warnings": warnings,
        "errors": errors,
    }

def validate_payload():
    if validate_target == "fixture":
        fx = read_fixture(fixture) if fixture else {}
        missing = [k for k in ("session", "pane", "t0", "t1") if k not in fx]
        return {"schema_version": "codex-stuck-detector.validate.v1", "status": "ok" if not missing else "fail", "target": "fixture", "missing": missing}
    invalid = 0
    total = 0
    for line in Path(ledger).read_text(encoding="utf-8").splitlines() if ledger.exists() else []:
        if not line.strip():
            continue
        total += 1
        try:
            row = json.loads(line)
            if not isinstance(row, dict):
                invalid += 1
        except json.JSONDecodeError:
            invalid += 1
    return {"schema_version": "codex-stuck-detector.validate.v1", "status": "ok" if invalid == 0 else "fail", "target": "ledger", "row_count": total, "invalid_rows": invalid}

def repair_payload():
    actions = []
    actual = []
    if validate_target in {"ledger", "all"}:
        actions.append("ensure-ledger-directory")
        if apply:
            ledger.parent.mkdir(parents=True, exist_ok=True)
            actual.append("ensured-ledger-directory")
    if validate_target in {"substrate-contract", "self-row", "all"}:
        actions.append("ensure-substrate-loop-contract-self-row")
        if contract_action in {"present", "appended"}:
            actual.append(f"substrate-loop-contract-self-row-{contract_action}")
    return {"schema_version": "codex-stuck-detector.repair.v1", "status": "ok", "scope": validate_target, "dry_run": not apply, "apply": apply, "planned_actions": actions, "actual_actions": actual}

def why_payload():
    reasons = {
        "buffer_stuck": "Stable two-frame hash plus Codex template placeholder. Safe recovery is one Enter newline retry only.",
        "post_completion": "Stable two-frame hash plus Working timer >=10m. Detector snapshots and routes to /flywheel:respawn; no auto-respawn.",
        "input_deaf": "Placeholder remains stable after ntm send reports success. Redispatch cannot fix it; route to /flywheel:respawn.",
        POST_CALLBACK_SUBCLASS: "Stable hash plus stale background terminal spinner and Codex reminder template at chevron. Recovery is Escape, reprompt, then bounded respawn escalation.",
        CAPACITY_HALT_SUBCLASS: "Stable two-frame hash plus chevron prompt and model-capacity text. Recovery is bounded capacity-halt-auto-continue-primitive.sh, not respawn.",
        QUEUED_NOT_SUBMITTED_SUBCLASS: "Working/background state plus a queued chevron prompt with user text. Recovery is bare Enter through codex-queued-not-submitted-bare-enter-primitive.sh.",
        OOM_KILLED_SUBCLASS: "Stable two-frame hash plus no chevron prompt and OS-killed marker (Killed / out of memory / [Process completed]). Codex CLI was OOM/cgroup-killed; process is gone. Recovery is ntm respawn (not Enter, not auto_continue) — the codex process must be restarted.",
        "auto_recover": "--auto-recover sends Enter for buffer_stuck, calls capacity-halt-auto-continue-primitive.sh for model_at_capacity_halt, sends bare Enter for codex_queued_not_submitted, and invokes ntm respawn for oom_killed_pane; post-callback reminder templates are subclass-gated to escape_then_reprompt_or_respawn.",
    }
    return {"schema_version": "codex-stuck-detector.why.v1", "id": why_id, "reason": reasons.get(why_id, "unknown id"), "known_ids": sorted(reasons)}

def audit_payload():
    payload = doctor_payload()
    payload["schema_version"] = "codex-stuck-detector.audit.v1"
    payload["latest_rows"] = read_jsonl(ledger)[-10:]
    return payload

if mode == "detect":
    print(json.dumps(detect_payload(), sort_keys=True, separators=(",", ":")))
elif mode == "doctor":
    print(json.dumps(doctor_payload(), sort_keys=True, separators=(",", ":")))
elif mode == "validate":
    print(json.dumps(validate_payload(), sort_keys=True, separators=(",", ":")))
elif mode == "repair":
    print(json.dumps(repair_payload(), sort_keys=True, separators=(",", ":")))
elif mode == "audit":
    print(json.dumps(audit_payload(), sort_keys=True, separators=(",", ":")))
elif mode == "why":
    print(json.dumps(why_payload(), sort_keys=True, separators=(",", ":")))
else:
    print(json.dumps({"schema_version": "codex-stuck-detector.error.v1", "status": "fail", "reason": "unknown mode"}))
    sys.exit(2)
PY
}

append_rows_from_payload() {
  local payload="$1" row
  while IFS= read -r row; do
    [[ -n "$row" ]] || continue
    append_validated "$LEDGER" "$row"
  done < <(jq -c '.ledger_rows[]?' <<<"$payload")
  while IFS= read -r row; do
    [[ -n "$row" ]] || continue
    append_validated "$FUCKUP_LOG" "$row"
  done < <(jq -c '.fuckup_rows[]?' <<<"$payload")
}

detect_command() {
  local payload stripped rc=0 py_err append_err
  py_err="$(mktemp "${TMPDIR:-/tmp}/codex-stuck-detector-py.XXXXXX")"
  if ! payload="$(detector_py detect 2>"$py_err")"; then
    local reason
    reason="$(cat "$py_err" 2>/dev/null || true)"
    rm -f "$py_err"
    emit_error 3 "probe_failure" "${reason:-detector probe failed}"
    return $?
  fi
  rm -f "$py_err"
  if [[ "$APPLY" -eq 1 ]]; then
    if append_err="$(append_rows_from_payload "$payload" 2>&1)"; then
      payload="$(jq -c '. + {ledger_append_status:"appended"}' <<<"$payload")"
    else
      payload="$(jq -c --arg err "$append_err" '. + {ledger_append_status:"failed",ledger_append_error:$err}' <<<"$payload")"
      stripped="$(jq -c 'del(.ledger_rows,.fuckup_rows,.panes[].ledger_row,.panes[].fuckup_row)' <<<"$payload")"
      emit "$stripped" "$(jq -r '"status=\(.status) ledger_append_status=failed targets_checked=\(.targets_checked)"' <<<"$stripped")" 3
      return $?
    fi
  fi
  stripped="$(jq -c 'del(.ledger_rows,.fuckup_rows,.panes[].ledger_row,.panes[].fuckup_row)' <<<"$payload")"
  if jq -e '.status == "probe_failure"' >/dev/null <<<"$stripped"; then
    rc=3
  elif jq -e '.status == "stuck"' >/dev/null <<<"$stripped"; then
    rc=1
  elif jq -e '.status == "unknown_stable"' >/dev/null <<<"$stripped"; then
    rc=2
  fi
  emit "$stripped" "$(jq -r '"status=\(.status) stuck_count=\(.stuck_count) targets_checked=\(.targets_checked)"' <<<"$stripped")" "$rc"
}

doctor_command() {
  local action payload rc=0
  action="$(ensure_contract_self_row)"
  payload="$(detector_py doctor "$action")"
  if jq -e '.status == "fail"' >/dev/null <<<"$payload"; then
    rc=1
  fi
  emit "$payload" "$(jq -r '"status=\(.status) count_24h=\(.codex_template_stuck_count_24h) top=\(.codex_stuck_subclass_top // "none")"' <<<"$payload")" "$rc"
}

repair_command() {
  local action="not_requested" payload
  VALIDATE_TARGET="$REPAIR_SCOPE"
  if [[ "$APPLY" -eq 1 && ( "$REPAIR_SCOPE" == "substrate-contract" || "$REPAIR_SCOPE" == "self-row" || "$REPAIR_SCOPE" == "all" ) ]]; then
    action="$(ensure_contract_self_row)"
  fi
  payload="$(detector_py repair "$action")"
  emit "$payload" "$(jq -r '"status=\(.status) scope=\(.scope) planned=\(.planned_actions|length) actual=\(.actual_actions|length)"' <<<"$payload")" 0
}

validate_command() {
  local payload rc=0
  payload="$(detector_py validate)"
  if jq -e '.status == "fail"' >/dev/null <<<"$payload"; then rc=1; fi
  emit "$payload" "$(jq -r '"status=\(.status) target=\(.target)"' <<<"$payload")" "$rc"
}

audit_command() {
  local payload
  payload="$(detector_py audit)"
  emit "$payload" "$(jq -r '"status=\(.status) latest_rows=\(.latest_rows|length)"' <<<"$payload")" 0
}

why_command() {
  local payload
  payload="$(detector_py why)"
  emit "$payload" "$(jq -r '.reason' <<<"$payload")" 0
}

health_command() {
  if [[ "$WATCH" -eq 1 ]]; then
    while true; do
      doctor_command
      sleep "$WATCH_INTERVAL"
    done
  fi
  doctor_command
}

for arg in "$@"; do
  [[ "$arg" == "--json" ]] && JSON_OUT=1
done

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --doctor|doctor) MODE="doctor"; shift ;;
    health|--health) MODE="health"; shift ;;
    repair|--repair) MODE="repair"; shift ;;
    validate) MODE="validate"; VALIDATE_TARGET="${2:-ledger}"; shift 2 ;;
    audit) MODE="audit"; shift ;;
    why) MODE="why"; WHY_ID="${2:-}"; shift 2 ;;
    schema) MODE="schema"; SCHEMA_TOPIC="${2:-detect}"; shift 2 ;;
    --info|info) MODE="info"; shift ;;
    --examples|examples) MODE="examples"; shift ;;
    quickstart) MODE="quickstart"; shift ;;
    help|-h|--help) MODE="help"; shift ;;
    completion) MODE="completion"; COMPLETION_SHELL="${2:-}"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --dry-run) DRY_RUN=1; APPLY=0; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --auto-recover) AUTO_RECOVER=1; shift ;;
    --session) SESSION_NAME="${2:?--session requires NAME}"; shift 2 ;;
    --session=*) SESSION_NAME="${1#*=}"; shift ;;
    --pane) PANE="${2:?--pane requires N}"; shift 2 ;;
    --pane=*) PANE="${1#*=}"; shift ;;
    --worker-panes-from-topology) WORKER_PANES_FROM_TOPOLOGY=1; shift ;;
    --fixture) FIXTURE="${2:?--fixture requires PATH}"; shift 2 ;;
    --fixture=*) FIXTURE="${1#*=}"; shift ;;
    --fixture-dir) FIXTURE_DIR="${2:?--fixture-dir requires PATH}"; shift 2 ;;
    --fixture-dir=*) FIXTURE_DIR="${1#*=}"; shift ;;
    --window-sec) WINDOW_SEC="${2:?--window-sec requires N}"; shift 2 ;;
    --window-sec=*) WINDOW_SEC="${1#*=}"; shift ;;
    --lines) LINES="${2:?--lines requires N}"; shift 2 ;;
    --lines=*) LINES="${1#*=}"; shift ;;
    --ledger) LEDGER="${2:?--ledger requires PATH}"; shift 2 ;;
    --ledger=*) LEDGER="${1#*=}"; shift ;;
    --repo) REPO_ROOT="${2:?--repo requires PATH}"; shift 2 ;;
    --repo=*) REPO_ROOT="${1#*=}"; shift ;;
    --scope) REPAIR_SCOPE="${2:?--scope requires SCOPE}"; shift 2 ;;
    --scope=*) REPAIR_SCOPE="${1#*=}"; shift ;;
    --watch) WATCH=1; shift ;;
    --interval|-i) WATCH_INTERVAL="${2:?--interval requires N}"; shift 2 ;;
    --interval=*) WATCH_INTERVAL="${1#*=}"; shift ;;
    *)
      emit_error 2 "unknown_argument" "unknown argument: $1"
      exit $? ;;
  esac
done

case "$MODE" in
  detect) detect_command ;;
  doctor) doctor_command ;;
  health) health_command ;;
  repair) repair_command ;;
  validate) validate_command ;;
  audit) audit_command ;;
  why) why_command ;;
  schema) schema_json ;;
  info) info_json ;;
  examples) examples_text ;;
  quickstart) quickstart_text ;;
  completion) completion ;;
  help) usage ;;
  *)
    emit_error 2 "unknown_mode" "unknown mode: $MODE"
    exit $? ;;
esac
