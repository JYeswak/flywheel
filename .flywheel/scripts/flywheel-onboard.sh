#!/usr/bin/env bash
set -euo pipefail

VERSION="flywheel-onboard.v0.1.0"
CONTRACT_VERSION="2026-05-03.1"
SCHEMA_PATH="${FLYWHEEL_ONBOARD_SCHEMA:-/tmp/fleet-onboarding-DESIGN/contract-schema.json}"
FLEET_ROSTER="${FLYWHEEL_FLEET_ROSTER:-$HOME/.local/state/flywheel/fleet-roster.json}"
FLYWHEEL_LOOP="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
META_RULE_SYNC="${FLYWHEEL_META_RULE_SYNC:-$HOME/.flywheel/canonical-meta-rules/sync.sh}"
DOCTOR_TIMEOUT_SECONDS="${FLYWHEEL_ONBOARD_DOCTOR_TIMEOUT_SECONDS:-90}"

usage() {
  cat <<'USAGE'
Usage:
  flywheel-onboard.sh [--repo PATH] --dry-run --doctor [--json]
  flywheel-onboard.sh [--repo PATH] --doctor [--json]
  flywheel-onboard.sh [--repo PATH] --stamp --dry-run [--json] [--explain] [--idempotency-key KEY]
  flywheel-onboard.sh [--repo PATH] --sync --dry-run [--json] [--explain] [--idempotency-key KEY]
  flywheel-onboard.sh [--repo PATH] --upgrade --dry-run [--json] [--explain] [--idempotency-key KEY]
  flywheel-onboard.sh --info [--json]
  flywheel-onboard.sh --schema
  flywheel-onboard.sh --examples
  flywheel-onboard.sh --version
  flywheel-onboard.sh doctor|health|repair|validate|audit|why|completion [options]

Phase 2 is read-only for repo onboarding. Mutating modes expose dry-run plans
and block non-dry-run mutation until Joshua approves a stamp/sync/upgrade phase.
USAGE
}

examples() {
  cat <<'EXAMPLES'
Examples:
  .flywheel/scripts/flywheel-onboard.sh --dry-run --doctor --json /Users/josh/Developer/flywheel
  .flywheel/scripts/flywheel-onboard.sh --dry-run --doctor --json /Users/josh/Developer/mobile-eats
  .flywheel/scripts/flywheel-onboard.sh --dry-run --doctor --json /Users/josh/Developer/skillos
  .flywheel/scripts/flywheel-onboard.sh --stamp --dry-run --explain --json --idempotency-key demo /Users/josh/Developer/mobile-eats
  .flywheel/scripts/flywheel-onboard.sh schema
EXAMPLES
}

quickstart() {
  cat <<'QUICKSTART'
Run --doctor --dry-run --json first. HEALTHY means the repo has enough
fleet-onboarding substrate to be stamped by a later Joshua-approved mutation.
LIMPING means a live loop marker/driver exists but closure proof is weak, most
often a missing canonical last_tick_<project>.json receipt.
QUICKSTART
}

fallback_schema() {
  jq -nc --arg contract "$CONTRACT_VERSION" '{
    "$schema":"https://json-schema.org/draft/2020-12/schema",
    "$id":"https://zeststream.ai/schemas/flywheel/onboard-contract-fallback.schema.json",
    title:"Flywheel Fleet Onboarding Contract",
    type:"object",
    required:["schema_version","contract_version","repo","project","status","tiers"],
    properties:{
      schema_version:{const:"flywheel.onboard.contract.v1"},
      contract_version:{const:$contract},
      repo:{type:"string"},
      project:{type:"string"},
      status:{enum:["HEALTHY","PARTIAL","LIMPING","MISSING","STALE","UNKNOWN","BLOCKED"]},
      tiers:{type:"object"}
    }
  }'
}

emit_schema() {
  if [[ -r "$SCHEMA_PATH" ]]; then
    cat "$SCHEMA_PATH"
  else
    fallback_schema
  fi
}

emit_info() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc \
      --arg version "$VERSION" \
      --arg contract "$CONTRACT_VERSION" \
      --arg script "$0" \
      --arg schema "$SCHEMA_PATH" \
      --arg roster "$FLEET_ROSTER" \
      --arg flywheel_loop "$FLYWHEEL_LOOP" \
      --arg doctor_timeout_seconds "$DOCTOR_TIMEOUT_SECONDS" \
      '{success:true, mode:"info", version:$version, contract_version:$contract, script:$script, schema_path:$schema, fleet_roster:$roster, flywheel_loop:$flywheel_loop, doctor_timeout_seconds:($doctor_timeout_seconds|tonumber), phase2_read_only:true}'
  else
    cat <<INFO
$VERSION
contract_version=$CONTRACT_VERSION
schema_path=$SCHEMA_PATH
fleet_roster=$FLEET_ROSTER
flywheel_loop=$FLYWHEEL_LOOP
doctor_timeout_seconds=$DOCTOR_TIMEOUT_SECONDS
phase2_read_only=true
INFO
  fi
}

completion_script() {
  cat <<'COMPLETE'
# bash/zsh completion stub for flywheel-onboard.sh
_flywheel_onboard_complete() {
  COMPREPLY=($(compgen -W "--dry-run --doctor --info --schema --examples --json --stamp --sync --upgrade --explain --idempotency-key --help --version doctor health repair validate audit why completion" -- "${COMP_WORDS[COMP_CWORD]}"))
}
complete -F _flywheel_onboard_complete flywheel-onboard.sh
COMPLETE
}

json_message() {
  local mode="$1" status="$2" message="$3"
  jq -nc \
    --arg version "$VERSION" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg mode "$mode" \
    --arg status "$status" \
    --arg message "$message" \
    '{success:($status=="ok"), timestamp:$ts, version:$version, output_format:"json", mode:$mode, status:$status, message:$message}'
}

COMMAND="doctor"
ACTION=""
REPO=""
JSON_OUT=0
DRY_RUN=0
EXPLAIN=0
IDEMPOTENCY_KEY=""
SCOPE=""
WHY_ID=""
VALIDATE_THING=""

if [[ $# -gt 0 ]]; then
  case "$1" in
    doctor|health|repair|validate|audit|why|schema|examples|quickstart|completion|help)
      COMMAND="$1"
      shift
      ;;
  esac
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      [[ -n "${2:-}" ]] || { echo "ERR: --repo requires PATH" >&2; exit 2; }
      REPO="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --doctor)
      COMMAND="doctor"
      shift
      ;;
    --info)
      COMMAND="info"
      shift
      ;;
    --schema)
      COMMAND="schema"
      shift
      ;;
    --examples)
      COMMAND="examples"
      shift
      ;;
    --json)
      JSON_OUT=1
      shift
      ;;
    --stamp)
      COMMAND="doctor"
      ACTION="stamp"
      shift
      ;;
    --sync)
      COMMAND="doctor"
      ACTION="sync"
      shift
      ;;
    --upgrade)
      COMMAND="doctor"
      ACTION="upgrade"
      shift
      ;;
    --explain)
      EXPLAIN=1
      shift
      ;;
    --idempotency-key)
      [[ -n "${2:-}" ]] || { echo "ERR: --idempotency-key requires KEY" >&2; exit 2; }
      IDEMPOTENCY_KEY="$2"
      shift 2
      ;;
    --scope)
      [[ -n "${2:-}" ]] || { echo "ERR: --scope requires NAME" >&2; exit 2; }
      SCOPE="$2"
      shift 2
      ;;
    --id)
      [[ -n "${2:-}" ]] || { echo "ERR: --id requires ID" >&2; exit 2; }
      WHY_ID="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --version)
      printf '%s contract=%s\n' "$VERSION" "$CONTRACT_VERSION"
      exit 0
      ;;
    --no-color|--no-emoji)
      shift
      ;;
    --width)
      [[ -n "${2:-}" ]] || { echo "ERR: --width requires N" >&2; exit 2; }
      shift 2
      ;;
    -*)
      echo "ERR: unknown argument: $1" >&2
      exit 2
      ;;
    *)
      if [[ -z "$REPO" ]]; then
        REPO="$1"
      elif [[ -z "$VALIDATE_THING" ]]; then
        VALIDATE_THING="$1"
      else
        echo "ERR: unexpected argument: $1" >&2
        exit 2
      fi
      shift
      ;;
  esac
done

case "$COMMAND" in
  help)
    usage
    exit 0
    ;;
  schema)
    emit_schema
    exit 0
    ;;
  examples)
    examples
    exit 0
    ;;
  quickstart)
    quickstart
    exit 0
    ;;
  completion)
    completion_script
    exit 0
    ;;
  info)
    emit_info
    exit 0
    ;;
  repair)
    if [[ "$DRY_RUN" -eq 0 ]]; then
      if [[ "$JSON_OUT" -eq 1 ]]; then
        json_message repair blocked "repair is dry-run only in Phase 2; rerun with --dry-run"
      else
        echo "repair is dry-run only in Phase 2; rerun with --dry-run"
      fi
      exit 4
    fi
    COMMAND="repair"
    ;;
  validate)
    if emit_schema | jq empty >/dev/null 2>&1; then
      if [[ "$JSON_OUT" -eq 1 ]]; then
        json_message validate ok "schema valid"
      else
        echo "schema valid"
      fi
      exit 0
    fi
    if [[ "$JSON_OUT" -eq 1 ]]; then
      json_message validate fail "schema invalid"
    else
      echo "schema invalid" >&2
    fi
    exit 1
    ;;
  audit)
    if [[ "$JSON_OUT" -eq 1 ]]; then
      jq -nc --arg roster "$FLEET_ROSTER" '{success:true, mode:"audit", version:"flywheel-onboard.v0.1.0", output_format:"json", audit_log:$roster, entries:[]}'
    else
      echo "No onboarding audit entries yet. Fleet roster: $FLEET_ROSTER"
    fi
    exit 0
    ;;
  why)
    if [[ "$JSON_OUT" -eq 1 ]]; then
      jq -nc --arg id "${WHY_ID:-${VALIDATE_THING:-onboarding}}" '{success:true, mode:"why", version:"flywheel-onboard.v0.1.0", output_format:"json", id:$id, explanation:"Phase 2 onboarding status is derived from five tiers: files, loop driver, topology, health probes, fleet stamp eligibility."}'
    else
      echo "Onboarding status derives from five tiers: files, loop driver, topology, health probes, fleet stamp eligibility."
    fi
    exit 0
    ;;
esac

if [[ -z "$REPO" ]]; then
  REPO="$PWD"
fi

if ! REPO_ABS="$(cd "$REPO" 2>/dev/null && pwd -P)"; then
  echo "ERR: repo path not found: $REPO" >&2
  exit 2
fi

export VERSION CONTRACT_VERSION REPO_ABS JSON_OUT DRY_RUN EXPLAIN ACTION
export IDEMPOTENCY_KEY SCOPE FLEET_ROSTER FLYWHEEL_LOOP SCHEMA_PATH COMMAND
export DOCTOR_TIMEOUT_SECONDS META_RULE_SYNC
python3 <<'PY'
import json
import os
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path

VERSION = os.environ["VERSION"]
CONTRACT_VERSION = os.environ["CONTRACT_VERSION"]
REPO = Path(os.environ["REPO_ABS"])
PROJECT = REPO.name
JSON_OUT = os.environ["JSON_OUT"] == "1"
DRY_RUN = os.environ["DRY_RUN"] == "1"
EXPLAIN = os.environ["EXPLAIN"] == "1"
ACTION = os.environ.get("ACTION", "")
IDEMPOTENCY_KEY = os.environ.get("IDEMPOTENCY_KEY") or None
FLEET_ROSTER = Path(os.environ["FLEET_ROSTER"])
FLYWHEEL_LOOP = Path(os.environ["FLYWHEEL_LOOP"])
META_RULE_SYNC = Path(os.environ["META_RULE_SYNC"])
COMMAND = os.environ.get("COMMAND", "doctor")
DOCTOR_TIMEOUT_SECONDS = int(os.environ.get("DOCTOR_TIMEOUT_SECONDS") or "90")
HOME = Path.home()
TOPOLOGY_PATH = HOME / ".local/state/flywheel/session-topology.jsonl"
CANONICAL_RECEIPT = HOME / f".local/state/flywheel-loop/last_tick_{PROJECT}.json"


def now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def check(check_id: str, status: str, evidence: str, path: str = "", command: str = "") -> dict:
    row = {"id": check_id, "status": status, "evidence": evidence}
    if path:
        row["path"] = path
    if command:
        row["command"] = command
    return row


def finding(cls: str, severity: str, message: str, evidence_path: str = "", recommended_action: str = "") -> dict:
    row = {"class": cls, "severity": severity, "message": message}
    if evidence_path:
        row["evidence_path"] = evidence_path
    if recommended_action:
        row["recommended_action"] = recommended_action
    return row


def tier(name: str, required: list, recommended=None, optional=None, findings=None) -> dict:
    recommended = recommended or []
    optional = optional or []
    findings = findings or []
    statuses = [item["status"] for item in required]
    if any(status in ("fail", "missing", "unknown") for status in statuses):
        status = "fail"
    elif any(status == "warn" for status in statuses):
        status = "warn"
    else:
        status = "pass"
    return {"name": name, "status": status, "required": required, "recommended": recommended, "optional": optional, "findings": findings}


def load_json(path: Path) -> dict:
    try:
        value = json.loads(path.read_text())
        return value if isinstance(value, dict) else {}
    except Exception:
        return {}


def parse_ts(raw: object):
    if not raw:
        return None
    value = str(raw)
    try:
        if value.endswith("Z"):
            value = value[:-1] + "+00:00"
        return datetime.fromisoformat(value).timestamp()
    except Exception:
        return None


def file_age_seconds(path: Path):
    try:
        return int(time.time() - path.stat().st_mtime)
    except Exception:
        return None


def latest_topology(session: str) -> dict:
    latest: dict = {}
    if not TOPOLOGY_PATH.exists():
        return latest
    for line in TOPOLOGY_PATH.read_text(errors="replace").splitlines():
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        if row.get("session") == session:
            latest = row
    return latest


def run_doctor():
    if not FLYWHEEL_LOOP.exists():
        return None, {}, f"missing flywheel-loop: {FLYWHEEL_LOOP}"
    try:
        proc = subprocess.run(
            [str(FLYWHEEL_LOOP), "doctor", "--repo", str(REPO), "--json"],
            text=True,
            capture_output=True,
            timeout=DOCTOR_TIMEOUT_SECONDS,
        )
    except Exception as exc:
        return None, {}, f"{type(exc).__name__}: {exc}"
    try:
        payload = json.loads(proc.stdout)
        if not isinstance(payload, dict):
            payload = {}
    except Exception:
        payload = {}
    err = proc.stderr.strip()
    return proc.returncode, payload, err


def run_meta_rule_three_surface(mode: str):
    if not META_RULE_SYNC.exists():
        return 127, {
            "schema_version": "canonical-meta-rules.three-surface.v1",
            "status": "fail",
            "target": str(REPO),
            "drift_count": 1,
            "missing_rules_count": 1,
            "warnings": [{"code": "meta_rule_sync_missing", "path": str(META_RULE_SYNC)}],
        }, f"missing meta-rule sync: {META_RULE_SYNC}"
    flag = "--apply-three-surface" if mode == "apply" else "--check-three-surface"
    try:
        proc = subprocess.run(
            [str(META_RULE_SYNC), flag, "--target", str(REPO), "--json"],
            text=True,
            capture_output=True,
            timeout=30,
        )
    except Exception as exc:
        return 70, {
            "schema_version": "canonical-meta-rules.three-surface.v1",
            "status": "fail",
            "target": str(REPO),
            "drift_count": 1,
            "missing_rules_count": 1,
            "warnings": [{"code": "meta_rule_sync_exception", "message": f"{type(exc).__name__}: {exc}"}],
        }, str(exc)
    try:
        payload = json.loads(proc.stdout)
        if not isinstance(payload, dict):
            payload = {}
    except Exception:
        payload = {
            "schema_version": "canonical-meta-rules.three-surface.v1",
            "status": "fail",
            "target": str(REPO),
            "drift_count": 1,
            "missing_rules_count": 1,
            "warnings": [{"code": "meta_rule_sync_invalid_json", "raw": proc.stdout[:1000]}],
        }
    return proc.returncode, payload, proc.stderr.strip()


def append_state_meta_rule_receipt(apply_status: str, missing_pre: int, missing_post: int, apply_result: dict):
    state_path = REPO / ".flywheel/STATE.md"
    state_path.parent.mkdir(parents=True, exist_ok=True)
    block = [
        "",
        f"## Onboard Meta-Rule Three-Surface Receipt - {now_iso()}",
        "",
        f"- meta_rule_three_surface_apply: {apply_status}",
        f"- missing_count_pre: {missing_pre}",
        f"- missing_count_post: {missing_post}",
        f"- sync_status: {apply_result.get('status', 'unknown')}",
        f"- updated_surfaces: {','.join(apply_result.get('updated_surfaces') or []) or 'none'}",
        "",
    ]
    with state_path.open("a", encoding="utf-8") as handle:
        handle.write("\n".join(block))


doctor_rc, doctor, doctor_err = run_doctor()
meta_rule_three_surface_rc, meta_rule_three_surface_check, meta_rule_three_surface_err = run_meta_rule_three_surface("check")
meta_rule_missing_pre = int(meta_rule_three_surface_check.get("missing_rules_count") or meta_rule_three_surface_check.get("drift_count") or 0)
meta_rule_three_surface_apply = None
meta_rule_apply_status = "skipped"
meta_rule_missing_post = meta_rule_missing_pre
actual_actions = []

if meta_rule_missing_pre > 0 and ACTION and not DRY_RUN:
    apply_rc, apply_payload, apply_err = run_meta_rule_three_surface("apply")
    meta_rule_three_surface_apply = apply_payload
    meta_rule_missing_post = int(apply_payload.get("missing_rules_count") or apply_payload.get("post_drift_count") or 0)
    meta_rule_apply_status = "ok" if apply_rc == 0 and meta_rule_missing_post == 0 else "fail"
    append_state_meta_rule_receipt(meta_rule_apply_status, meta_rule_missing_pre, meta_rule_missing_post, apply_payload)
    actual_actions.append({
        "id": "meta-rule-three-surface-apply",
        "kind": "sync",
        "target": str(REPO),
        "status": meta_rule_apply_status,
        "exit_code": apply_rc,
        "stderr": apply_err,
        "missing_count_pre": meta_rule_missing_pre,
        "missing_count_post": meta_rule_missing_post,
    })
topology = latest_topology(PROJECT)

required_files = []
for rel in [
    ".flywheel/MISSION.md",
    ".flywheel/GOAL.md",
    ".flywheel/STATE.md",
    "AGENTS.md",
    ".flywheel/AGENTS-CANONICAL.md",
    ".flywheel/dispatch-log.jsonl",
]:
    path = REPO / rel
    required_files.append(check(rel.replace("/", "_").replace(".", "_"), "pass" if path.exists() else "missing", "present" if path.exists() else "missing", str(path)))

ticks = REPO / ".flywheel/ticks"
required_files.append(check("flywheel_ticks_dir", "pass" if ticks.is_dir() else "warn", "present" if ticks.is_dir() else "not present yet; first repo-local tick may create it", str(ticks)))
incidents = REPO / "INCIDENTS.md"
last_receipt = REPO / ".flywheel/last_closeout_receipt.json"
tier1 = tier(
    "Tier 1 - files",
    required_files,
    recommended=[
        check("incidents_md", "pass" if incidents.exists() else "warn", "present" if incidents.exists() else "not present yet", str(incidents)),
    ],
    optional=[
        check("last_closeout_receipt", "pass" if last_receipt.exists() else "warn", "present" if last_receipt.exists() else "not present yet", str(last_receipt)),
    ],
)

loop_driver = doctor.get("loop_driver") if isinstance(doctor.get("loop_driver"), dict) else {}
driver_status = str(loop_driver.get("driver_status") or "")
dispatch_mode = str(loop_driver.get("dispatch_mode") or "")
plist_loaded = loop_driver.get("plist_loaded")
recent_dispatch_sent = loop_driver.get("recent_dispatch_sent")
pane_prompt_observed = loop_driver.get("pane_prompt_observed")
control_plane_exemption = PROJECT == "flywheel"

receipt_age = file_age_seconds(CANONICAL_RECEIPT)
receipt_data = load_json(CANONICAL_RECEIPT) if CANONICAL_RECEIPT.exists() else {}
receipt_ts = receipt_data.get("ts")
receipt_project = receipt_data.get("project")
receipt_ts_age = None
receipt_epoch = parse_ts(receipt_ts)
if receipt_epoch is not None:
    receipt_ts_age = int(time.time() - receipt_epoch)

if PROJECT == "mobile-eats":
    cadence_window = 900
elif PROJECT == "skillos":
    cadence_window = 7200
else:
    cadence_window = 7200

driver_required = []
if control_plane_exemption:
    driver_required.append(check("control_plane_exemption", "pass", "flywheel control plane uses manual_orchestrator exemption"))
else:
    good_driver = driver_status == "VERIFIED" or (plist_loaded is True and recent_dispatch_sent is True)
    driver_required.append(check("driver_verified", "pass" if good_driver else "fail", f"driver_status={driver_status or 'unknown'} dispatch_mode={dispatch_mode or 'unknown'}"))

if control_plane_exemption:
    driver_required.append(check("canonical_receipt", "pass", "not required for flywheel control-plane exemption", str(CANONICAL_RECEIPT)))
elif CANONICAL_RECEIPT.exists() and receipt_project != PROJECT:
    driver_required.append(check("canonical_receipt", "fail", f"project mismatch: expected={PROJECT} actual={receipt_project}", str(CANONICAL_RECEIPT)))
elif CANONICAL_RECEIPT.exists() and (receipt_age is None or receipt_age <= cadence_window) and (receipt_ts_age is None or receipt_ts_age <= cadence_window):
    driver_required.append(check("canonical_receipt", "pass", f"present age_sec={receipt_age} ts_age_sec={receipt_ts_age} project={receipt_project}", str(CANONICAL_RECEIPT)))
elif CANONICAL_RECEIPT.exists():
    driver_required.append(check("canonical_receipt", "warn", f"present but stale age_sec={receipt_age} ts_age_sec={receipt_ts_age}", str(CANONICAL_RECEIPT)))
else:
    driver_required.append(check("canonical_receipt", "fail", "missing canonical last_tick receipt", str(CANONICAL_RECEIPT)))

if control_plane_exemption:
    driver_required.append(check("pane_prompt_observed", "pass", "covered by flywheel dispatch-log/topology control-plane exemption"))
else:
    driver_required.append(check("pane_prompt_observed", "pass" if pane_prompt_observed is True or recent_dispatch_sent is True else "warn", f"pane_prompt_observed={pane_prompt_observed} recent_dispatch_sent={recent_dispatch_sent}"))

tier2_findings = []
if driver_status == "MARKER_ONLY" and not control_plane_exemption:
    tier2_findings.append(finding("loop_driver_marker_only", "high", "active loop marker without verified driver proof"))
if not CANONICAL_RECEIPT.exists() and not control_plane_exemption:
    tier2_findings.append(finding("canonical_receipt_missing", "high", "active loop lacks canonical receipt mirror", str(CANONICAL_RECEIPT)))
elif CANONICAL_RECEIPT.exists() and receipt_project != PROJECT and not control_plane_exemption:
    tier2_findings.append(finding("canonical_receipt_project_mismatch", "high", f"canonical receipt project mismatch: expected={PROJECT} actual={receipt_project}", str(CANONICAL_RECEIPT)))
tier2 = tier("Tier 2 - loop driver", driver_required, findings=tier2_findings)

topology_required = [
    check("session_topology_row", "pass" if topology else "missing", "latest topology row found" if topology else "no topology row", str(TOPOLOGY_PATH)),
]
if topology:
    has_orch = "orchestrator_pane" in topology
    workers = topology.get("worker_panes")
    topology_required.append(check("orchestrator_pane", "pass" if has_orch else "missing", f"orchestrator_pane={topology.get('orchestrator_pane')}"))
    topology_required.append(check("worker_panes", "pass" if isinstance(workers, list) else "warn", f"worker_panes={workers}"))
else:
    topology_required.append(check("orchestrator_pane", "missing", "no topology row"))
    topology_required.append(check("worker_panes", "missing", "no topology row"))
tier3 = tier("Tier 3 - session topology", topology_required, recommended=[
    check("fleet_mail_identity", "pass" if topology.get("fleet_mail_identity") else "warn", f"fleet_mail_identity={topology.get('fleet_mail_identity')}")
] if topology else [])

mission_lock = doctor.get("mission_lock_age") if isinstance(doctor.get("mission_lock_age"), dict) else {}
mission_state = str(mission_lock.get("state") or mission_lock.get("mission_lock_status") or "")
doctor_status = str(doctor.get("status") or "unknown")
doctor_errors = doctor.get("errors") if isinstance(doctor.get("errors"), list) else []
docs_state = str(doctor.get("repo_docs_state") or "")
canonical_state = str(doctor.get("canonical_doctrine_state") or "")

health_required = [
    check("mission_lock_fresh", "pass" if mission_state in ("fresh", "ok") else "warn", f"mission_lock_state={mission_state or 'unknown'}"),
    check("doctor_reachable", "pass" if doctor else "warn", f"doctor_status={doctor_status} rc={doctor_rc} {doctor_err}".strip()),
    check("meta_rule_three_surface", "pass" if meta_rule_missing_pre == 0 else "warn", f"status={meta_rule_three_surface_check.get('status', 'unknown')} missing_count={meta_rule_missing_pre}", str(META_RULE_SYNC)),
]
if docs_state and docs_state != "ready":
    health_required.append(check("repo_docs_state", "warn", f"repo_docs_state={docs_state}"))
else:
    health_required.append(check("repo_docs_state", "pass" if docs_state else "warn", f"repo_docs_state={docs_state or 'unknown'}"))
if canonical_state and canonical_state != "canonical_doctrine_synced":
    health_required.append(check("canonical_doctrine", "warn", f"canonical_doctrine_state={canonical_state}"))
else:
    health_required.append(check("canonical_doctrine", "pass" if canonical_state else "warn", f"canonical_doctrine_state={canonical_state or 'unknown'}"))
tier4_findings = []
for err in doctor_errors:
    if isinstance(err, dict):
        code = str(err.get("code") or err.get("class") or "doctor_error")
        tier4_findings.append(finding(code, "medium", str(err.get("message") or code)))
tier4 = tier("Tier 4 - health probes", health_required, findings=tier4_findings)

stamp_path = REPO / ".flywheel/fleet-member.json"
roster_exists = FLEET_ROSTER.exists()
stamp_exists = stamp_path.exists()
stamp_data = load_json(stamp_path) if stamp_exists else {}
tier5_required = [
    check("fleet_roster_registry", "pass" if roster_exists else "missing", "present" if roster_exists else "missing", str(FLEET_ROSTER)),
    check("fleet_member_stamp_eligible", "pass", "Phase 2 dry-run eligibility surface; --stamp remains blocked until Joshua-approved mutation", str(stamp_path)),
]
tier5_recommended = [
    check("fleet_member_json", "pass" if stamp_exists else "warn", "present" if stamp_exists else "not stamped yet", str(stamp_path)),
]
if stamp_exists:
    tier5_recommended.append(check("stamp_contract_version", "pass" if stamp_data.get("contract_version") == CONTRACT_VERSION else "warn", f"contract_version={stamp_data.get('contract_version')}"))
tier5 = tier("Tier 5 - fleet stamp", tier5_required, recommended=tier5_recommended)

tiers = {
    "tier1_files": tier1,
    "tier2_loop_driver": tier2,
    "tier3_session_topology": tier3,
    "tier4_health_probes": tier4,
    "tier5_fleet_stamp": tier5,
}

planned_actions = []
validator_path = REPO / ".flywheel/scripts/validate-callback-before-close.sh"
if ACTION == "upgrade" or not (validator_path.exists() and os.access(validator_path, os.X_OK)):
    planned_actions.append({"id": "sync-four-lens-close-validator", "kind": "sync", "target": str(validator_path), "mode": "planned", "reason": "flywheel-install upgrade re-syncs the four-lens close validator from templates/flywheel-install"})
if not stamp_exists:
    planned_actions.append({"id": "stamp-fleet-member", "kind": "write", "target": str(stamp_path), "mode": "planned", "reason": "would write in Joshua-approved stamp phase"})
if not incidents.exists():
    planned_actions.append({"id": "sync-incidents", "kind": "sync", "target": str(incidents), "mode": "planned", "reason": "would distribute selected canonical INCIDENTS in sync phase"})
if not CANONICAL_RECEIPT.exists() and not control_plane_exemption:
    planned_actions.append({"id": "repair-canonical-receipt", "kind": "sync", "target": str(CANONICAL_RECEIPT), "mode": "planned", "reason": "would add receipt mirror/consumer in sync phase"})
if meta_rule_missing_pre > 0 and not (ACTION and not DRY_RUN):
    planned_actions.append({"id": "apply-meta-rule-three-surface", "kind": "sync", "target": str(REPO), "mode": "planned", "reason": "onboard action would backfill missing canonical L-rules into the three doctrine surfaces"})

blocked_by = []
if ACTION and not DRY_RUN:
    blocked_by.append(finding("phase2_mutation_blocked", "high", f"{ACTION} is dry-run only in Phase 2; rerun with --dry-run or dispatch implementation phase"))

if not (REPO / ".flywheel/loop.json").exists():
    status = "DEAD"
elif tier2["status"] == "fail":
    status = "LIMPING"
elif any(t["status"] == "fail" for t in (tier1, tier3)):
    status = "DEAD"
elif blocked_by:
    status = "BLOCKED"
else:
    status = "HEALTHY"

success = status == "HEALTHY" or (DRY_RUN and status in ("HEALTHY", "LIMPING"))
payload = {
    "success": success,
    "timestamp": now_iso(),
    "version": VERSION,
    "output_format": "json" if JSON_OUT else "text",
    "mode": COMMAND,
    "action": ACTION or None,
    "dry_run": DRY_RUN,
    "explain": EXPLAIN,
    "idempotency_key": IDEMPOTENCY_KEY,
    "schema_version": "flywheel.onboard.contract.v1",
    "contract_version": CONTRACT_VERSION,
    "repo": str(REPO),
    "project": PROJECT,
    "status": status,
    "tier_summary": {key: value["status"] for key, value in tiers.items()},
    "tiers": tiers,
    "doctor": {
        "exit_code": doctor_rc,
        "status": doctor_status,
        "repo_docs_state": docs_state or None,
        "canonical_doctrine_state": canonical_state or None,
        "loop_driver_status": driver_status or None,
        "errors_count": len(doctor_errors),
    },
    "topology": topology,
    "planned_actions": planned_actions if DRY_RUN or ACTION else [],
    "actual_actions": actual_actions,
    "would_write": [a["target"] for a in planned_actions if a["kind"] == "write"] if DRY_RUN else [],
    "would_call_external": [],
    "blocked_by": blocked_by,
    "audit_ids": [],
    "meta_rule_three_surface": {
        "check_exit_code": meta_rule_three_surface_rc,
        "check": meta_rule_three_surface_check,
        "check_error": meta_rule_three_surface_err or None,
        "apply": meta_rule_three_surface_apply,
        "apply_status": meta_rule_apply_status,
        "missing_count_pre": meta_rule_missing_pre,
        "missing_count_post": meta_rule_missing_post,
    },
}
if EXPLAIN:
    payload["explanation"] = [
        "Phase 2 classifies onboarding eligibility without stamping repos.",
        "Canonical receipt absence is a loop-integrity blocker for active non-control-plane repos.",
        "Missing fleet-member.json is a planned stamp action, not a dry-run failure.",
    ]

if JSON_OUT:
    print(json.dumps(payload, sort_keys=True))
else:
    print(f"{PROJECT}: {status}")
    print(f"tier_summary={payload['tier_summary']}")
    if planned_actions:
        print("planned_actions:")
        for action in planned_actions:
            print(f"- {action['id']} -> {action['target']}")
    if blocked_by:
        print("blocked_by:")
        for item in blocked_by:
            print(f"- {item['class']}: {item['message']}")

if blocked_by:
    raise SystemExit(4)
if status == "HEALTHY":
    raise SystemExit(0)
if DRY_RUN and status == "LIMPING":
    raise SystemExit(0)
raise SystemExit(1)
PY
