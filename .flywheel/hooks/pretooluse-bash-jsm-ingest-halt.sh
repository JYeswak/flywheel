#!/usr/bin/env bash
# CANONICAL FLYWHEEL HOOK — pretooluse-bash-jsm-ingest-halt.sh
#
# Canonical source: /Users/josh/Developer/flywheel/.flywheel/hooks/pretooluse-bash-jsm-ingest-halt.sh
# Schema:           skillos.hook_manifest.v1
# Doctrine ref:     jsm-ingest-halt doctrine (skills DB integrity + storage + lift receipt)
# Purpose:          Halt jsm create/validate/push/ingest while a valid ingest-halt-lift receipt is absent.
#
# Installed by:     /flywheel:sync-hooks (consumer-side pull).
# DO NOT EDIT IN CONSUMER REPOS. Patch this canonical copy and re-sync.

set -euo pipefail

INPUT_JSON="$(cat)"
LOG_PATH="${JSM_INGEST_HALT_LOG:-$HOME/.local/state/flywheel/jsm-ingest-halt-blocks.jsonl}"
LIFT_RECEIPT="${JSM_INGEST_HALT_LIFT_RECEIPT:-$HOME/.local/state/jsm/ingest-halt-lift.json}"

INPUT_JSON="$INPUT_JSON" LOG_PATH="$LOG_PATH" LIFT_RECEIPT="$LIFT_RECEIPT" python3 <<'PY'
import datetime as dt
import json
import os
import re
import shlex
import sys
from pathlib import Path

MUTATION_RE = re.compile(
    r"(?:(?:^|[;&|()]\s*|(?:^|[;&|()]\s*)(?:if|then|do|while|until)\s+)"
    r"(?:env\s+\S+=\S+\s+)*(?:timeout\s+\S+\s+)?(?:\S*/)?jsm\s+"
    r"(create|validate|push|ingest)\b)"
)


def load_event():
    try:
        return json.loads(os.environ.get("INPUT_JSON", "") or "{}")
    except json.JSONDecodeError:
        return {}


def command_text(event):
    if event.get("tool_name") not in (None, "Bash"):
        return ""
    return ((event.get("tool_input") or {}).get("command") or "").strip()


def shlex_mutation_verb(command):
    try:
        tokens = shlex.split(command)
    except ValueError:
        return None
    wrappers = {"env", "timeout", "command"}
    for idx, token in enumerate(tokens):
        base = token.rsplit("/", 1)[-1]
        if base != "jsm":
            continue
        prev = tokens[idx - 1].rsplit("/", 1)[-1] if idx else ""
        if idx and prev not in wrappers and not any(sep in prev for sep in (";", "&&", "||", "|")):
            pass
        if idx + 1 < len(tokens) and tokens[idx + 1] in {"create", "validate", "push", "ingest"}:
            return tokens[idx + 1]
    return None


def mutation_verb(command):
    match = MUTATION_RE.search(command)
    if match:
        return match.group(1)
    return shlex_mutation_verb(command)


def lift_receipt_valid(path):
    try:
        data = json.loads(path.read_text())
    except Exception:
        return False, "missing_or_invalid_lift_receipt"
    checks = {
        "status": data.get("status") == "lift_approved",
        "joshua_approved": data.get("joshua_approved") is True,
        "skillos_ack": data.get("skillos_ack") is True,
        "flywheel_ack": data.get("flywheel_ack") is True,
        "skills_db_integrity": data.get("skills_db_integrity") == "ok",
        "fast_lane_ok_cycles": int(data.get("fast_lane_ok_cycles", 0) or 0) >= 3,
        "storage_percent": float(data.get("storage_percent", 101) or 101) < 85,
    }
    failed = [key for key, ok in checks.items() if not ok]
    if failed:
        return False, "lift_receipt_failed:" + ",".join(failed)
    return True, "lift_receipt_valid"


event = load_event()
command = command_text(event)
if not command:
    sys.exit(0)

verb = mutation_verb(command)
if not verb:
    sys.exit(0)

lift_path = Path(os.environ["LIFT_RECEIPT"]).expanduser()
allowed, lift_reason = lift_receipt_valid(lift_path)
if allowed:
    sys.exit(0)

log_path = Path(os.environ["LOG_PATH"]).expanduser()
log_path.parent.mkdir(parents=True, exist_ok=True)
row = {
    "schema_version": "flywheel.jsm_ingest_halt_block/v1",
    "ts": dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "verb": verb,
    "lift_receipt": str(lift_path),
    "lift_reason": lift_reason,
    "command_sha256": __import__("hashlib").sha256(command.encode("utf-8")).hexdigest(),
    "command_snippet": re.sub(r"\s+", " ", command)[:240],
}
with log_path.open("a", encoding="utf-8") as handle:
    handle.write(json.dumps(row, separators=(",", ":"), sort_keys=True) + "\n")

reason = (
    "JSM ingest halt active: jsm create/validate/push/ingest are blocked until "
    "storage <85%, skills.db integrity ok, fast-lane scan_status ok for 3 cycles, "
    "and Joshua+SkillOS+Flywheel lift approval are recorded in "
    f"{lift_path}."
)
print(reason, file=sys.stderr)
print(json.dumps({
    "decision": "block",
    "reason": reason,
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason,
    },
}, separators=(",", ":")))
sys.exit(2)
PY
