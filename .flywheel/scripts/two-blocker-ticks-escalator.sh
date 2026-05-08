#!/usr/bin/env bash
set -u -o pipefail

VERSION="two-blocker-ticks-escalator.v1.0.0"
SCHEMA_VERSION="two-blocker-ticks/v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO="$REPO_DEFAULT"
DISPATCH_LOG="${TWO_BLOCKER_TICKS_DISPATCH_LOG:-$REPO/.flywheel/dispatch-log.jsonl}"
STATE="${TWO_BLOCKER_TICKS_STATE:-$HOME/.local/state/flywheel/two-blocker-ticks-state.json}"
LEDGER="${TWO_BLOCKER_TICKS_LEDGER:-$HOME/.local/state/flywheel/two-blocker-ticks-escalator-ledger.jsonl}"
COORDINATION_LOG="${TWO_BLOCKER_TICKS_COORDINATION_LOG:-$HOME/.local/state/flywheel/cross-orch-coordination.jsonl}"
FUCKUP_LOG="${TWO_BLOCKER_TICKS_FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
ISSUES_JSONL="${TWO_BLOCKER_TICKS_ISSUES_JSONL:-$REPO/.beads/issues.jsonl}"
THRESHOLD="${TWO_BLOCKER_TICKS_THRESHOLD:-2}"
COMMAND=""
AUTO_ESCALATE=0
JSON_OUT=0

usage() {
  cat <<'EOF'
usage:
  two-blocker-ticks-escalator.sh check [--repo PATH] [--threshold 2] [--auto-escalate] [--json]
  two-blocker-ticks-escalator.sh --info|--help|--examples

Scans .flywheel/dispatch-log.jsonl for overdue callbacks and escalates blockers
that survive two consecutive detector ticks.
EOF
}

examples() {
  cat <<'EOF'
examples:
  .flywheel/scripts/two-blocker-ticks-escalator.sh check --json
  .flywheel/scripts/two-blocker-ticks-escalator.sh check --threshold 3 --json
  TWO_BLOCKER_TICKS_STATE=/tmp/two-state.json .flywheel/scripts/two-blocker-ticks-escalator.sh check --auto-escalate --json
EOF
}

info_json() {
  jq -nc --arg version "$VERSION" --arg schema "$SCHEMA_VERSION" --arg repo "$REPO" --arg state "$STATE" --arg ledger "$LEDGER" \
    '{name:"two-blocker-ticks-escalator.sh",version:$version,schema_version:$schema,repo:$repo,state_path:$state,ledger_path:$ledger,commands:["check","--repo","--threshold","--auto-escalate","--json","--info","--examples","--help"],exits:{"0":"probe completed, including fail-open GRAY","2":"usage error"}}'
}

run_check() {
  python3 - "$REPO" "$DISPATCH_LOG" "$STATE" "$LEDGER" "$COORDINATION_LOG" "$FUCKUP_LOG" "$ISSUES_JSONL" "$THRESHOLD" "$AUTO_ESCALATE" "${TWO_BLOCKER_TICKS_NOW:-}" "$JSON_OUT" "${TWO_BLOCKER_TICKS_TICK_ID:-}" "${TWO_BLOCKER_TICKS_LOOKBACK_HOURS:-12}" <<'PY'
import fcntl, hashlib, json, os, re, sys, tempfile
from datetime import datetime, timedelta, timezone
from pathlib import Path

repo, dispatch_log, state_path, ledger_path, coord_path, fuckup_log, issues_path = map(Path, sys.argv[1:8])
threshold, auto_escalate = int(sys.argv[8]), sys.argv[9] == "1"
now_arg, json_out, tick_id_arg, lookback_hours = sys.argv[10], sys.argv[11] == "1", sys.argv[12], float(sys.argv[13])
SCHEMA_VERSION = "two-blocker-ticks/v1"
CAPSULE_SCHEMA_VERSION = "sister-orch-escalation-capsule/v1"
CLOSED = {"closed", "done", "resolved", "archived"}

def parse_ts(value, base=None):
    if value is None:
        return None
    text = str(value).strip()
    if not text:
        return None
    if text.startswith("+") and text.endswith("min"):
        base_dt = parse_ts(base)
        if base_dt is None:
            return None
        try:
            return base_dt + timedelta(minutes=int(text[1:-3]))
        except ValueError:
            return None
    try:
        text = text[:-1] + "+00:00" if text.endswith("Z") else text
        dt = datetime.fromisoformat(text)
        return (dt.replace(tzinfo=timezone.utc) if dt.tzinfo is None else dt).astimezone(timezone.utc)
    except ValueError:
        return None

def iso(dt):
    return dt.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")

def read_jsonl(path):
    rows, warnings = [], []
    if not path.exists():
        return rows, [f"missing:{path}"]
    for line_no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip():
            continue
        try:
            rows.append(json.loads(line))
        except json.JSONDecodeError:
            warnings.append(f"malformed_jsonl:{path}:{line_no}")
    return rows, warnings

def callbacked(row):
    event = str(row.get("event") or "").lower()
    return bool(row.get("callback_received_at")) or event in {"callback_received", "completion_received", "callback_transport_test_received"} or event.endswith("_callback_received")

def load_state(path):
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}

def fsync_dir(path):
    try:
        fd = os.open(str(path), os.O_RDONLY)
        os.fsync(fd)
        os.close(fd)
    except OSError:
        pass

def atomic_write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    tmp_path = Path(tmp)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(data, handle, sort_keys=True)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(tmp_path, path)
        fsync_dir(path.parent)
    except Exception:
        try:
            tmp_path.unlink()
        except OSError:
            pass
        raise

def append_jsonl(path, row):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")

def latest_by_id(rows):
    latest = {}
    for row in rows:
        if row.get("id"):
            latest[str(row["id"])] = row
    return latest

def slugify(value):
    text = str(value or "").lower()
    text = re.sub(r"[^a-z0-9]+", "-", text).strip("-")
    return text

def strip_date_suffix(value):
    return re.sub(r"-20[0-9]{2}-[0-9]{2}-[0-9]{2}$", "", value)

def add_closed_key(index, key, issue_id, match_type):
    text = str(key or "").strip()
    if not text:
        return
    index.setdefault(text, {"issue_id": issue_id, "match": match_type})
    slug = slugify(text)
    if slug:
        index.setdefault(slug, {"issue_id": issue_id, "match": f"{match_type}_slug"})

def load_closed_issue_index(rows):
    index = {"by_key": {}, "titles": []}
    for issue_id, row in latest_by_id(rows).items():
        if str(row.get("status") or "").lower() not in CLOSED:
            continue
        add_closed_key(index["by_key"], issue_id, issue_id, "issue_id")
        for field in ("task_id", "dispatch_task_id", "original_blocker_task_id", "blocked_bead_id"):
            add_closed_key(index["by_key"], row.get(field), issue_id, field)
        title_slug = slugify(row.get("title"))
        if title_slug:
            index["titles"].append({"issue_id": issue_id, "title_slug": title_slug, "match": "title_slug"})
            match = re.match(r"^escalate-blocker-(.+)-via-flywheel-plan$", title_slug)
            if match:
                add_closed_key(index["by_key"], match.group(1), issue_id, "escalation_title")
    return index

def closed_issue_match(item, index):
    candidates = []
    for field in ("bead_id", "task_id"):
        raw = item.get(field)
        if raw:
            text = str(raw)
            slug = slugify(text)
            candidates.extend([text, slug, strip_date_suffix(slug)])
    for candidate in candidates:
        if candidate and candidate in index["by_key"]:
            return index["by_key"][candidate]
    bases = {strip_date_suffix(slugify(item.get("task_id"))), strip_date_suffix(slugify(item.get("bead_id")))}
    bases.discard("")
    for base in bases:
        for title in index["titles"]:
            title_slug = title["title_slug"]
            if title_slug == base or title_slug.startswith(f"{base}-") or base.startswith(f"{title_slug}-"):
                return title
    return None

def existing_escalation(latest, title):
    for row in latest.values():
        if str(row.get("status") or "").lower() not in CLOSED and row.get("title") == title:
            return row.get("id")
    return None

def existing_capsule(path, dedupe_key):
    rows, _ = read_jsonl(path)
    return any(row.get("dedupe_key") == dedupe_key and (row.get("kind") == "blocker_escalation" or row.get("event") == "blocker_escalation") for row in rows)

def sister_session():
    return os.environ.get("TWO_BLOCKER_TICKS_SISTER_SESSION") or repo.name or "unknown"

def evidence_paths(bead):
    return [str(dispatch_log), str(issues_path), str(state_path), str(ledger_path)]

def capsule_subject(bead):
    return f"[ESCALATE] blocker survived 2 ticks: {bead['bead_id']}"

def capsule_body(bead, escalation_bead_id):
    evidence = ",".join(evidence_paths(bead))
    return "\n".join([
        f"schema_version: {CAPSULE_SCHEMA_VERSION}",
        f"blocker_id: {bead['bead_id']}",
        f"tick_count: {bead['consecutive_tick_count']}",
        f"sister_session: {sister_session()}",
        "blocker_class: sister-orch-2-tick-blocker",
        f"evidence_paths: {evidence}",
        f"escalation_bead_id: {escalation_bead_id}",
        f"next_action: /flywheel:plan accretive fix for {bead['bead_id']}",
        "owner_route: flywheel:1",
    ]) + "\n"

def append_fuckup_for_capsule(bead, escalation_bead_id, audit_ts):
    row = {
        "ts": audit_ts,
        "session": sister_session(),
        "pane": None,
        "agent": "two-blocker-ticks-escalator",
        "git_repo": str(repo),
        "trauma_class": "sister-orch-2-tick-blocker",
        "severity": "high",
        "what_happened": f"sister orchestrator blocker {bead['bead_id']} survived {bead['consecutive_tick_count']} consecutive ticks",
        "what_attempted": ["local sister-orch tick loop retried blocker path twice"],
        "what_worked": ["escalated to flywheel:1 with [ESCALATE] capsule and /flywheel:plan staging bead"],
        "rule_violated_or_proven": "feedback_two_blocker_ticks_escalate_to_flywheel_plan",
        "evidence": evidence_paths(bead),
        "should_become": "bead",
        "escalation_bead_id": escalation_bead_id,
        "blocker_id": bead["bead_id"],
        "tick_count": bead["consecutive_tick_count"],
    }
    append_jsonl(fuckup_log, row)

def blocked_from_dispatch(rows, now, closed_issue_index):
    latest, blocked = {}, {}
    closed_via_issues = []
    for row in rows:
        key = row.get("bead_id") or row.get("task_id")
        if key:
            latest[str(key)] = row
    for key, row in latest.items():
        row_ts = parse_ts(row.get("ts"))
        if row_ts and row_ts < now - timedelta(hours=lookback_hours):
            continue
        raw_expected = row.get("callback_expected_by")
        if isinstance(raw_expected, str) and raw_expected.startswith("+"):
            continue
        expected = parse_ts(raw_expected, row.get("ts"))
        if callbacked(row) or expected is None or expected >= now:
            continue
        item = {"bead_id": str(row.get("bead_id") or row.get("task_id") or key), "task_id": row.get("task_id"), "callback_expected_by": iso(expected), "dispatch_ts": row.get("ts"), "target": row.get("to") or row.get("target") or row.get("session")}
        issue_match = closed_issue_match(item, closed_issue_index)
        if issue_match:
            closed_via_issues.append({**item, "closed_issue_id": issue_match["issue_id"], "closed_match": issue_match["match"]})
            continue
        blocked[key] = item
    return blocked, closed_via_issues

def base_payload(now, tick_key, warnings, signal="GRAY", status="gray", errors=None):
    return {"schema_version": SCHEMA_VERSION, "audit_ts": iso(now), "repo": str(repo), "dispatch_log": str(dispatch_log), "state_path": str(state_path), "ledger_path": str(ledger_path), "coordination_log": str(coord_path), "issues_path": str(issues_path), "status": status, "signal": signal, "threshold": threshold, "blocked_beads": [], "blocked_count": 0, "max_consecutive_tick_count": 0, "auto_escalate_requested": auto_escalate, "auto_escalations_filed": [], "auto_escalations": [], "capsules_dispatched": [], "closed_via_issues": [], "tick_key": tick_key, "warnings": warnings, "errors": errors or []}

def build_payload():
    now = parse_ts(now_arg) if now_arg else datetime.now(timezone.utc)
    now = now or datetime.now(timezone.utc)
    tick_key, audit_ts = tick_id_arg or f"tick5m:{int(now.timestamp() // 300)}", iso(now)
    dispatch_rows, warnings = read_jsonl(dispatch_log)
    issue_rows, issue_warnings = read_jsonl(issues_path)
    warnings.extend(issue_warnings)
    closed_issue_index = load_closed_issue_index(issue_rows)
    blocked, closed_via_issues = blocked_from_dispatch(dispatch_rows, now, closed_issue_index)
    lock_path = Path(str(state_path) + ".lock")
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    with lock_path.open("a", encoding="utf-8") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        state, new_state, blocked_beads = load_state(state_path), {}, []
        for key in sorted(blocked):
            item = blocked[key]
            prev = state.get(key, {}) if isinstance(state.get(key), dict) else {}
            prev_count = int(prev.get("consecutive_tick_count") or 0)
            count = max(prev_count, 1) if prev.get("last_seen_tick_key") == tick_key else prev_count + 1
            new_state[key] = {"consecutive_tick_count": count, "last_seen_ts": audit_ts, "last_seen_tick_key": tick_key, "callback_expected_by": item["callback_expected_by"], "task_id": item.get("task_id")}
            blocked_beads.append({**item, "consecutive_tick_count": count, "escalated": False})
        atomic_write_json(state_path, new_state)
    max_count = max([b["consecutive_tick_count"] for b in blocked_beads] or [0])
    signal = "GREEN" if max_count == 0 else "YELLOW" if max_count < threshold else "RED"
    status = "pass" if signal == "GREEN" else "warn" if signal == "YELLOW" else "fail"
    if any(w.startswith("missing:") for w in warnings):
        signal, status = "GRAY", "gray"
    filed, capsules, escalations = [], [], []
    if auto_escalate and signal == "RED":
        latest, _ = read_jsonl(issues_path)
        latest = latest_by_id(latest)
        for bead in blocked_beads:
            if bead["consecutive_tick_count"] < threshold:
                continue
            title = f"escalate-blocker-{bead['bead_id']}-via-flywheel-plan"
            existing = existing_escalation(latest, title)
            if existing:
                bead_id, action = existing, "reused"
            else:
                bead_id = "flywheel-escalate-" + hashlib.sha1(bead["bead_id"].encode()).hexdigest()[:8]
                row = {"id": bead_id, "title": title, "description": f"Auto-filed by two-blocker-ticks-escalator for blocker {bead['bead_id']} surviving {bead['consecutive_tick_count']} consecutive ticks. Next action: /flywheel:plan accretive fix for {bead['bead_id']}.", "status": "open", "priority": 0, "issue_type": "task", "created_at": audit_ts, "updated_at": audit_ts, "created_by": "two-blocker-ticks-escalator", "source_repo": str(repo), "labels": ["two-blocker-ticks-escalate", "flywheel-plan", "jsonl-fallback"]}
                append_jsonl(issues_path, row)
                latest[bead_id] = row
                filed.append(bead_id)
                action = "jsonl_fallback"
            dedupe = f"two-blocker-ticks:{bead['bead_id']}"
            if existing_capsule(coord_path, dedupe):
                cap_action = "reused"
            else:
                cap = {"schema_version": "cross_orch_handoff.v1", "capsule_schema_version": CAPSULE_SCHEMA_VERSION, "ts": audit_ts, "kind": "blocker_escalation", "event": "blocker_escalation", "from": "two-blocker-ticks-escalator", "to": "flywheel:1", "target": "flywheel-orch", "target_session": "flywheel", "target_pane": 1, "requested_owner": "flywheel:1", "blocker_type": "flywheel_class", "blocker_class": "sister-orch-2-tick-blocker", "bead_id": bead["bead_id"], "blocker_id": bead["bead_id"], "tick_count": bead["consecutive_tick_count"], "consecutive_tick_count": bead["consecutive_tick_count"], "sister_session": sister_session(), "callback_expected_by": bead["callback_expected_by"], "proposed_action": f"/flywheel:plan accretive fix for {bead['bead_id']}", "flywheel_orch_action_required": True, "agent_mail_subject": capsule_subject(bead), "agent_mail_body_md": capsule_body(bead, bead_id), "evidence_paths": evidence_paths(bead), "dedupe_key": dedupe}
                append_jsonl(coord_path, cap)
                append_fuckup_for_capsule(bead, bead_id, audit_ts)
                capsules.append(dedupe)
                cap_action = "jsonl_append"
            bead["escalated"] = True
            escalations.append({"blocked_bead_id": bead["bead_id"], "escalation_bead_id": bead_id, "action": action, "capsule_action": cap_action, "dedupe_key": dedupe})
    payload = base_payload(now, tick_key, warnings, signal, status)
    payload.update({"blocked_beads": blocked_beads, "blocked_count": len(blocked_beads), "max_consecutive_tick_count": max_count, "auto_escalations_filed": filed, "auto_escalations": escalations, "capsules_dispatched": capsules, "closed_via_issues": closed_via_issues})
    return payload

try:
    payload = build_payload()
except Exception as exc:
    payload = base_payload(datetime.now(timezone.utc), tick_id_arg or "", [], errors=[f"probe_error:{type(exc).__name__}:{exc}"])

try:
    row = dict(payload)
    row["event"] = "two_blocker_ticks_decision"
    append_jsonl(ledger_path, row)
except Exception as exc:
    payload["warnings"].append(f"ledger_append_error:{type(exc).__name__}:{exc}")

if json_out:
    print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
else:
    print(f"signal={payload['signal']} blocked={payload['blocked_count']} max_consecutive={payload['max_consecutive_tick_count']} threshold={payload['threshold']}")
PY
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    check) COMMAND="check"; shift ;;
    --repo)
      REPO="${2:?}"
      [[ -z "${TWO_BLOCKER_TICKS_DISPATCH_LOG:-}" ]] && DISPATCH_LOG="$REPO/.flywheel/dispatch-log.jsonl"
      [[ -z "${TWO_BLOCKER_TICKS_ISSUES_JSONL:-}" ]] && ISSUES_JSONL="$REPO/.beads/issues.jsonl"
      shift 2
      ;;
    --threshold) THRESHOLD="${2:?}"; shift 2 ;;
    --auto-escalate) AUTO_ESCALATE=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --info) info_json; exit 0 ;;
    --examples) examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

if ! [[ "$THRESHOLD" =~ ^[1-9][0-9]*$ ]]; then
  printf 'threshold must be a positive integer\n' >&2
  exit 2
fi
if [[ "$COMMAND" != "check" ]]; then
  usage >&2
  exit 2
fi
run_check
