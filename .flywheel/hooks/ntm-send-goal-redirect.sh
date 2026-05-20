#!/usr/bin/env bash
# CANONICAL FLYWHEEL HOOK — ntm-send-goal-redirect.sh
#
# Canonical source: /Users/josh/Developer/flywheel/.flywheel/hooks/ntm-send-goal-redirect.sh
# Schema:           skillos.hook_manifest.v1
# Doctrine ref:     feedback_use_flywheel_dispatch_skill_never_raw_script.md,
#                   canonical-codex-orch-dispatch-pattern.md (skillos 2def252b)
# Purpose:          Reject raw 'ntm send' that smuggles /goal content; redirect to canonical
#                   codex-goal-activate.sh / flywheel:dispatch surfaces.
#
# Installed by:     /flywheel:sync-hooks (consumer-side pull).
# DO NOT EDIT IN CONSUMER REPOS. Patch this canonical copy and re-sync.

set -euo pipefail

BLOCK_MESSAGE='RAW ntm send with /goal content is BANNED. Codex panes need codex-goal-activate.sh canonical primitive (7-step keystroke + bracketed paste). Use Skill(flywheel:dispatch) which routes correctly. Override via ~/.flywheel/raw-ntm-goal-authorized.json (canonical-wrapper internal use only).'
LOG_PATH="${NTM_SEND_GOAL_REDIRECT_LOG:-$HOME/.local/state/flywheel/dispatch-bypass-blocked.jsonl}"
AUTH_PATH="${NTM_SEND_GOAL_REDIRECT_AUTH:-$HOME/.flywheel/raw-ntm-goal-authorized.json}"
HOOK_INPUT="$(cat)"

HOOK_INPUT="$HOOK_INPUT" python3 - "$LOG_PATH" "$AUTH_PATH" "$BLOCK_MESSAGE" <<'PY'
import datetime as dt
import json
import os
import re
import shlex
import sys
from pathlib import Path

log_path = Path(sys.argv[1]).expanduser()
auth_path = Path(sys.argv[2]).expanduser()
block_message = sys.argv[3]

try:
    event = json.loads(os.environ.get("HOOK_INPUT", "{}"))
except Exception:
    sys.exit(0)

if event.get("tool_name") != "Bash":
    sys.exit(0)

command = event.get("tool_input", {}).get("command", "") or ""
if not re.search(r"\bntm\s+send\b", command):
    sys.exit(0)


def extract_session_pane(cmd):
    try:
        tokens = shlex.split(cmd)
    except ValueError:
        tokens = cmd.split()

    session = None
    pane = None
    for idx, token in enumerate(tokens):
        if token == "send" and idx > 0 and tokens[idx - 1].endswith("ntm"):
            if idx + 1 < len(tokens):
                session = tokens[idx + 1]
        elif token.startswith("--pane="):
            pane = token.split("=", 1)[1]
        elif token == "--pane" and idx + 1 < len(tokens):
            pane = tokens[idx + 1]
    return session, pane


def command_files(cmd):
    try:
        tokens = shlex.split(cmd)
    except ValueError:
        return []

    files = []
    for idx, token in enumerate(tokens):
        if token.startswith("--file="):
            files.append(Path(token.split("=", 1)[1]).expanduser())
        elif token == "--file" and idx + 1 < len(tokens):
            files.append(Path(tokens[idx + 1]).expanduser())
    return files


def file_has_goal_payload(path):
    try:
        text = path.read_text(errors="replace")[:4096]
    except Exception:
        return False
    return bool(re.search(r"(?m)^/goal\b", text) or re.search(r"(?m)^/[^\s]+[ \t]+TASK\b", text))


def command_has_goal_payload(cmd):
    patterns = [
        r"\bntm\s+send\b[\s\S]*(?:['\"])?/goal\b",
        r"\bntm\s+send\b[\s\S]*(?:['\"])?/[^\s'\"]+\s+TASK\b",
    ]
    if any(re.search(pattern, cmd) for pattern in patterns):
        return True
    return any(file_has_goal_payload(path) for path in command_files(cmd))


def authorized(session):
    if not auth_path.exists():
        return False
    try:
        data = json.loads(auth_path.read_text())
    except Exception:
        return False

    expires = data.get("expires_ts")
    if expires:
        try:
            exp = dt.datetime.fromisoformat(str(expires).replace("Z", "+00:00"))
            if dt.datetime.now(dt.timezone.utc) > exp:
                return False
        except Exception:
            return False

    if data.get("allow_all") is True:
        return True

    pids = {str(os.getpid()), str(os.getppid())}
    for key in ("caller_pids", "authorized_pids", "pids"):
        if pids.intersection({str(item) for item in data.get(key, [])}):
            return True

    sessions = set()
    for key in ("sessions", "session_names", "authorized_sessions"):
        sessions.update(str(item) for item in data.get(key, []))
    return bool(session and session in sessions)


session, pane = extract_session_pane(command)
if not command_has_goal_payload(command) or authorized(session):
    sys.exit(0)

log_path.parent.mkdir(parents=True, exist_ok=True)
snippet = re.sub(r"\s+", " ", command).strip()[:240]
row = {
    "ts": dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z"),
    "command_snippet": snippet,
    "session": session,
    "pane": pane,
    "blocked_reason": "raw_ntm_send_goal_payload",
}
with log_path.open("a") as fh:
    fh.write(json.dumps(row, separators=(",", ":")) + "\n")

print(block_message, file=sys.stderr)
sys.exit(2)
PY
