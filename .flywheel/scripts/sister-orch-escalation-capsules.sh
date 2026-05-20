#!/usr/bin/env bash
set -euo pipefail

VERSION="sister-orch-escalation-capsules.v1.0.0"
SCHEMA_VERSION="sister-orch-escalation-capsule/v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO="$REPO_DEFAULT"
COMMAND=""
INBOX_JSON=""
JSON_OUT=0
DRY_RUN=0
FUCKUP_LOG="${SISTER_ORCH_ESCALATION_FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"

usage() {
  cat <<'EOF'
usage:
  sister-orch-escalation-capsules.sh schema --json
  sister-orch-escalation-capsules.sh scan --inbox-json PATH [--repo PATH] [--dry-run] [--json]

Scans fleet-mail inbox rows for [ESCALATE] blocker capsules, validates the
body contract, stages a /flywheel:plan bead, and logs the escalation trauma.
EOF
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    schema|scan) COMMAND="$1"; shift ;;
    --repo) REPO="${2:?}"; shift 2 ;;
    --inbox-json) INBOX_JSON="${2:?}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

schema_json() {
  jq -nc --arg version "$VERSION" --arg schema "$SCHEMA_VERSION" '{
    name:"sister-orch-escalation-capsules.sh",
    version:$version,
    schema_version:$schema,
    subject_prefix:"[ESCALATE]",
    required_body_fields:["blocker_id","tick_count","sister_session","blocker_class","evidence_paths"],
    optional_body_fields:["schema_version","escalation_bead_id","next_action","owner_route"],
    body_contract:{
      blocker_id:"stable blocker id, not prose",
      tick_count:"integer >= 2",
      sister_session:"source NTM session, e.g. skillos or mobile-eats",
      blocker_class:"reason class, normally sister-orch-2-tick-blocker",
      evidence_paths:"comma-separated durable evidence paths"
    },
    arrival_action:"create-or-reuse P0 bead whose body cites /flywheel:plan next-action",
    fuckup_log_class:"sister-orch-2-tick-blocker"
  }'
}

if [[ "$COMMAND" == "schema" ]]; then
  schema_json
  exit 0
fi

if [[ "$COMMAND" != "scan" || -z "$INBOX_JSON" ]]; then
  usage >&2
  exit 2
fi

python3 - "$REPO" "$INBOX_JSON" "$FUCKUP_LOG" "$DRY_RUN" "$JSON_OUT" "$SCHEMA_VERSION" <<'PY'
import hashlib, json, os, re, sys, tempfile
from datetime import datetime, timezone
from pathlib import Path

repo, inbox_path, fuckup_log = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])
dry_run, json_out, schema_version = sys.argv[4] == "1", sys.argv[5] == "1", sys.argv[6]
issues_path = repo / ".beads" / "issues.jsonl"
SUBJECT_PREFIX = "[ESCALATE]"
REQUIRED = ["blocker_id", "tick_count", "sister_session", "blocker_class", "evidence_paths"]

def iso():
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

def read_messages(path):
    text = path.read_text(encoding="utf-8") if path.exists() else ""
    if not text.strip():
        return []
    try:
        data = json.loads(text)
        if isinstance(data, list):
            return data
        if isinstance(data, dict):
            return data.get("messages") or data.get("inbox") or [data]
    except json.JSONDecodeError:
        pass
    rows = []
    for line in text.splitlines():
        if line.strip():
            rows.append(json.loads(line))
    return rows

def read_jsonl(path):
    if not path.exists():
        return []
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip():
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return rows

def append_jsonl(path, row):
    if dry_run:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")

def parse_body(body):
    fields = {}
    for raw in str(body or "").splitlines():
        if ":" not in raw:
            continue
        key, value = raw.split(":", 1)
        key = key.strip()
        if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", key):
            fields[key] = value.strip()
    if "ticks_survived" in fields and "tick_count" not in fields:
        fields["tick_count"] = fields["ticks_survived"]
    return fields

def slug(value):
    text = re.sub(r"[^a-z0-9]+", "-", str(value).lower()).strip("-")
    return text[:72] or "unknown"

def existing_issue_id(title):
    for row in read_jsonl(issues_path):
        if row.get("title") == title and str(row.get("status") or "open").lower() not in {"closed", "done", "resolved"}:
            return row.get("id")
    return None

messages = read_messages(inbox_path)
results, errors = [], []
beads_created, beads_reused, fuckups_logged = [], [], []

for msg in messages:
    subject = str(msg.get("subject") or "")
    if not subject.startswith(SUBJECT_PREFIX):
        continue
    body = msg.get("body_md") if msg.get("body_md") is not None else msg.get("body", "")
    fields = parse_body(body)
    missing = [key for key in REQUIRED if not fields.get(key)]
    try:
        tick_count = int(fields.get("tick_count", "0"))
    except ValueError:
        tick_count = 0
    if missing or tick_count < 2:
        errors.append({"message_id": msg.get("id"), "subject": subject, "reason": "invalid_escalate_capsule", "missing": missing, "tick_count": fields.get("tick_count")})
        continue
    blocker_id = fields["blocker_id"]
    title = f"[plan] sister-orch blocker {blocker_id} via /flywheel:plan"
    existing = existing_issue_id(title)
    if existing:
        bead_id, action = existing, "reused"
        beads_reused.append(bead_id)
    else:
        bead_id = "flywheel-plan-" + hashlib.sha1(blocker_id.encode()).hexdigest()[:10]
        description = "\n".join([
            f"Auto-staged from fleet-mail subject `{subject}`.",
            f"Source sister session: `{fields['sister_session']}`.",
            f"Blocker class: `{fields['blocker_class']}`.",
            f"Tick count: `{tick_count}`.",
            f"Evidence paths: `{fields['evidence_paths']}`.",
            "",
            f"Next action: `/flywheel:plan accretive fix for {blocker_id}`.",
        ])
        append_jsonl(issues_path, {
            "id": bead_id,
            "title": title,
            "description": description,
            "status": "open",
            "priority": 0,
            "issue_type": "task",
            "created_at": iso(),
            "updated_at": iso(),
            "created_by": "sister-orch-escalation-capsules",
            "source": "fleet-mail-escalate-capsule",
            "source_message_id": msg.get("id"),
            "labels": ["sister-orch-2-tick-blocker", "flywheel-plan", "fleet-mail-escalation"],
        })
        beads_created.append(bead_id)
        action = "created"
    append_jsonl(fuckup_log, {
        "ts": iso(),
        "session": fields["sister_session"],
        "pane": None,
        "agent": "sister-orch-escalation-capsules",
        "git_repo": str(repo),
        "trauma_class": "sister-orch-2-tick-blocker",
        "severity": "high",
        "what_happened": f"[ESCALATE] capsule arrived for blocker {blocker_id} after {tick_count} ticks",
        "what_attempted": ["sister orch local blocker path survived two ticks"],
        "what_worked": [f"staged {bead_id} for /flywheel:plan"],
        "rule_violated_or_proven": "feedback_two_blocker_ticks_escalate_to_flywheel_plan",
        "evidence": [p.strip() for p in fields["evidence_paths"].split(",") if p.strip()],
        "should_become": "bead",
        "source_message_id": msg.get("id"),
        "blocker_id": blocker_id,
        "tick_count": tick_count,
    })
    if not dry_run:
        fuckups_logged.append("sister-orch-2-tick-blocker")
    results.append({"message_id": msg.get("id"), "subject": subject, "blocker_id": blocker_id, "tick_count": tick_count, "sister_session": fields["sister_session"], "bead_id": bead_id, "action": action, "auto_plan_trigger": "bead_staged_with_flywheel_plan_next_action"})

payload = {
    "schema_version": schema_version,
    "status": "pass" if not errors else "warn",
    "repo": str(repo),
    "inbox_json": str(inbox_path),
    "dry_run": dry_run,
    "messages_scanned": len(messages),
    "escalations_found": len(results),
    "escalations": results,
    "beads_created": beads_created,
    "beads_reused": beads_reused,
    "fuckup_log_class": "sister-orch-2-tick-blocker",
    "fuckup_rows_logged": len(fuckups_logged),
    "errors": errors,
}

if json_out:
    print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
else:
    print(f"escalations_found={len(results)} beads_created={len(beads_created)} errors={len(errors)}")

sys.exit(0 if not errors else 1)
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-63-phase-tick-bounded-action.md`
