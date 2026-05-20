#!/usr/bin/env bash
# canonical-cli-scoping-allow-large: dispatch requires one portable gate script with canonical CLI surfaces and embedded plan/audit parser.
set -euo pipefail

VERSION="quality-bar-close-gate.v1.1.0"
SCHEMA_VERSION="quality-bar-close-gate.v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO_ROOT="${QUALITY_BAR_CLOSE_GATE_REPO:-$REPO_ROOT_DEFAULT}"
LEDGER="${QUALITY_BAR_CLOSE_GATE_LEDGER:-$HOME/.local/state/flywheel/quality-bar-close-gate.jsonl}"
CONTRACT_LEDGER="${QUALITY_BAR_CLOSE_GATE_CONTRACT_LEDGER:-$HOME/.local/state/flywheel/substrate-loop-contract.jsonl}"
NTM_COVERAGE_TREND_SCRIPT="${QUALITY_BAR_CLOSE_GATE_NTM_COVERAGE_TREND_SCRIPT:-$REPO_ROOT_DEFAULT/.flywheel/scripts/ntm-surface-coverage-trend.sh}"
EVIDENCE_PACK_RESOLVER="${QUALITY_BAR_CLOSE_GATE_EVIDENCE_PACK_RESOLVER:-$REPO_ROOT_DEFAULT/.flywheel/scripts/evidence-pack-resolve.sh}"
JSONL_APPEND_LIB="${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"

MODE=""
JSON_OUT=0
PLAN_SLUG=""
APPLY=0
DRY_RUN=1
WATCH=0
WATCH_INTERVAL=5
REPAIR_SCOPE="ledger"
WHY_ID=""
SCHEMA_TOPIC="plan"
COMPLETION_SHELL=""
WIDTH=100
PREDICTIONS_FILE=""
APPLIES_AT_PHASE="phase3"

usage() {
  cat <<'EOF'
usage:
  quality-bar-close-gate.sh --plan-slug SLUG [--dry-run|--apply] [--json]
  quality-bar-close-gate.sh validate plan --plan-slug SLUG [--json]
  quality-bar-close-gate.sh --doctor [--json]
  quality-bar-close-gate.sh --health [--watch] [--interval N] [--json]
  quality-bar-close-gate.sh --repair [--scope ledger|substrate-contract|all] [--dry-run|--apply] [--json]
  quality-bar-close-gate.sh lock-predictions --plan-slug SLUG --predictions-file PATH [--applies-at-phase PHASE] --apply [--json]
  quality-bar-close-gate.sh audit [--json]
  quality-bar-close-gate.sh why REASON [--json]
  quality-bar-close-gate.sh schema plan|doctor|ledger|contract [--json]
  quality-bar-close-gate.sh --info|--examples|quickstart|help TOPIC|completion bash|zsh
EOF
}

now_iso() {
  printf '%s\n' "${QUALITY_BAR_CLOSE_GATE_NOW:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
}

json_bool() {
  if [[ "$1" == "1" ]]; then printf true; else printf false; fi
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

info_json() {
  jq -nc \
    --arg name "quality-bar-close-gate.sh" \
    --arg version "$VERSION" \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg repo "$REPO_ROOT" \
    --arg ledger "$LEDGER" \
    --arg contract_ledger "$CONTRACT_LEDGER" \
    --arg jsonl_append_lib "$JSONL_APPEND_LIB" \
    --arg ntm_coverage_trend_script "$NTM_COVERAGE_TREND_SCRIPT" \
    --arg evidence_pack_resolver "$EVIDENCE_PACK_RESOLVER" \
    '{name:$name,version:$version,schema_version:$schema_version,repo:$repo,ledger:$ledger,substrate_loop_contract_ledger:$contract_ledger,jsonl_append_lib:$jsonl_append_lib,ntm_coverage_trend_script:$ntm_coverage_trend_script,evidence_pack_resolver:$evidence_pack_resolver,exit_codes:{"0":"quality bar pass","1":"quality bar pending or fail","2":"usage error","3":"append primitive unavailable or failed"},thresholds:{pending:{warn:20,error:50},failed:{warn:5,error:10},compliance_score:{minimum:700,maximum:1000,convergence_streak_minimum:2},convergence_telemetry:{complex_requires_stable_rounds:2},ntm_surface_coverage:{minimum_avg:7,target_avg:10}},required_evidence:["schema_version>=5:hypothesis_slate[2..5]","schema_version>=5:exactly_one_is_third_alternative","schema_version>=5:kill_condition_per_strategy","schema_version>=5:prediction_lock_receipt_valid_when_predictions_present","schema_version>=4:compliance_pack_path","schema_version>=4:compliance_score>=700","schema_version>=4:convergence_streak>=2","schema_version>=4:EV anchors resolve when plan artifacts cite EV-NNN","schema_version>=4:evidence[] excerpts match source lines when present","schema_version>=4:relation=refutes blocks active target findings","schema_version>=4:complex plans require two stable 05-POLISH-rN.json telemetry rounds","schema_version>=4:evidence_pack_resolves=yes for v2 packs","schema_version>=4:legacy pack includes spec.json+evidence.json+compliance.json+theater.json+test_depth.json+scorecard.md+REPORT.md","schema_version<4:quality_bar_passed","schema_version<4:jeff_score>=9","schema_version<4:donella_score>=9_or_auto_advance","schema_version<4:composite>=9.5","critical_findings=0","future ntm-surface-wire-in plans require ntm coverage_avg>=7"]}'
}

examples_text() {
  cat <<'EOF'
quality-bar-close-gate.sh --plan-slug wire-or-explain-tick-gate-2026-05-04 --json
quality-bar-close-gate.sh --plan-slug wire-or-explain-tick-gate-2026-05-04 --apply --json
quality-bar-close-gate.sh lock-predictions --plan-slug wire-or-explain-tick-gate-2026-05-04 --predictions-file predictions.json --applies-at-phase phase3 --apply --json
quality-bar-close-gate.sh --doctor --json | jq '.plan_state_quality_bar_pending_count'
quality-bar-close-gate.sh repair --scope all --dry-run --json
EOF
}

quickstart_text() {
  cat <<'EOF'
1. Run --doctor --json to inspect Phase 5 quality-bar close pressure.
2. Run --plan-slug <slug> --json before any current_phase=polish -> ready transition.
3. Only close Phase 5 when decision=pass; pending/fail refuses close.
4. Add --apply after pass/pending/fail review to append the close-gate ledger row.
EOF
}

schema_json() {
  case "$SCHEMA_TOPIC" in
    plan)
      jq -nc --arg schema_version "$SCHEMA_VERSION.plan" '{schema_version:$schema_version,required:["plan_slug","decision","quality_bar_mode","critical_findings","reasons","hypothesis_slate_valid"],legacy_required:["jeff","donella","joshua","composite"],compliance_required:["compliance_score","compliance_threshold","compliance_pack_path","convergence_streak","evidence_pack_resolves"],schema_v5_required:["hypothesis_slate[2..5]","exactly_one_is_third_alternative","kill_condition_per_strategy"],prediction_lock_required_when_present:["STATE.json.prediction_lock.locked_at","STATE.json.predictions[].prediction","STATE.json.predictions[].ts","STATE.json.predictions[].hash","STATE.json.predictions[].applies_at_phase"],ev_anchor_required_when_present:["compliance-pack evidence[].ev_id","evidence[].source","evidence[].excerpt","evidence[].relation=supports|refutes|informs","evidence[].target_finding_id","plan artifact EV-NNN citations resolve"],convergence_telemetry_required_for_complex_plans:["05-POLISH-rN.json","two consecutive rounds with kills_gte_adds=true","two consecutive rounds with no_new_deltas=true"],conditional_required:{ntm_surface_wire_in:["ntm_surface_coverage_trend.coverage_avg>=7"]}}' ;;
    doctor)
      jq -nc '{schema_version:"quality-bar-close-gate.doctor.v1",required:["plan_state_quality_bar_pending_count","plan_state_quality_bar_failed_count","plan_state_quality_bar_passed_count"]}' ;;
    ledger)
      jq -nc '{schema_version:"quality-bar-close-gate.ledger.v1",required:["ts","plan_slug","decision","jeff","donella","joshua","composite","critical_findings"]}' ;;
    contract)
      jq -nc '{schema_version:"substrate-loop-contract.v1",required:["primitive_name","declares_loop","self_repair_action","measurement_field","escalation_path","schema_version","bootstrap_seed_v1"]}' ;;
    *)
      echo "ERR: unknown schema topic: $SCHEMA_TOPIC" >&2
      return 2 ;;
  esac
}

completion() {
  case "$COMPLETION_SHELL" in
    bash)
      cat <<'EOF'
_quality_bar_close_gate_completion() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "--plan-slug --doctor --health --watch --interval --repair --scope --dry-run --apply validate audit why schema --info --examples quickstart help completion --json --repo --ledger --width" -- "$cur") )
}
complete -F _quality_bar_close_gate_completion quality-bar-close-gate.sh
EOF
      ;;
    zsh)
      printf 'compadd -- --plan-slug --doctor --health --watch --interval --repair --scope --dry-run --apply validate audit why schema --info --examples quickstart help completion --json --repo --ledger --width\n'
      ;;
    *)
      echo "ERR: completion shell must be bash or zsh" >&2
      return 2 ;;
  esac
}

quality_bar_python() {
  local py_mode="$1"
  python3 - "$py_mode" "$REPO_ROOT" "${PLAN_SLUG:-}" "$EVIDENCE_PACK_RESOLVER" "${PREDICTIONS_FILE:-}" "${APPLIES_AT_PHASE:-phase3}" "$APPLY" "$(now_iso)" <<'PY'
import hashlib
import json
import re
import subprocess
import sys
from datetime import datetime, timezone, timedelta
from pathlib import Path

mode, repo_raw, slug, resolver_raw = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
predictions_file, applies_at_phase, apply_raw, now_value = sys.argv[5], sys.argv[6], sys.argv[7], sys.argv[8]
repo = Path(repo_raw)
evidence_pack_resolver = Path(resolver_raw).expanduser()

def read_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return None
    except Exception as exc:
        return {"_invalid_json": type(exc).__name__}

def as_num(value):
    if isinstance(value, bool) or value is None:
        return None
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, str):
        if value.strip().lower() == "auto_advance":
            return "auto_advance"
        match = re.search(r"-?\d+(?:\.\d+)?", value)
        if match:
            return float(match.group(0))
    return None

def truthy(value):
    if value is True:
        return True
    if isinstance(value, str) and value.strip().lower() in {"true", "yes", "pass", "passed"}:
        return True
    return False

def falsey(value):
    if value is False:
        return True
    if isinstance(value, str) and value.strip().lower() in {"false", "no", "fail", "failed"}:
        return True
    return False

def parse_dt(value):
    if not isinstance(value, str) or not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None

def score_from_audit(text, label):
    label_re = re.escape(label)
    patterns = [
        rf"{label_re}_score\s*[:=|]\s*(auto_advance|-?\d+(?:\.\d+)?)",
        rf"{label_re}\s+score\s*[:=|]\s*(auto_advance|-?\d+(?:\.\d+)?)",
        rf"{label_re}\s*[:=|]\s*(auto_advance|-?\d+(?:\.\d+)?)",
        rf"\|\s*{label_re}\s*\|\s*(auto_advance|-?\d+(?:\.\d+)?)\s*\|",
    ]
    for pattern in patterns:
        match = re.search(pattern, text, flags=re.I)
        if match:
            return as_num(match.group(1))
    return None

def critical_from_audit(text):
    patterns = [
        r"critical_findings\s*[:=|]\s*(\d+)",
        r"critical\s+findings\s*[:=|]\s*(\d+)",
        r"critical\s*[:=|]\s*(\d+)",
        r"\|\s*critical\s*\|\s*(\d+)\s*\|",
    ]
    for pattern in patterns:
        match = re.search(pattern, text, flags=re.I)
        if match:
            return int(match.group(1))
    return None

REQUIRED_COMPLIANCE_PACK_FILES = [
    "spec.json",
    "evidence.json",
    "compliance.json",
    "theater.json",
    "test_depth.json",
    "scorecard.md",
    "REPORT.md",
]

def state_schema_version(state):
    value = as_num(state.get("schema_version"))
    return int(value) if isinstance(value, (int, float)) else 1

def resolve_pack_path(path_value, plan_dir):
    if not isinstance(path_value, str) or not path_value.strip():
        return None
    path = Path(path_value.strip()).expanduser()
    if not path.is_absolute():
        path = plan_dir / path
    return path

def evidence_pack_version(pack_path):
    if not pack_path.is_file():
        return None
    try:
        text = pack_path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return None
    try:
        parsed = json.loads(text)
        if isinstance(parsed, dict):
            return parsed.get("evidence_pack_version")
    except Exception:
        pass
    if re.search(r"(?m)^\s*evidence_pack_version\s*:\s*2\s*$", text):
        return 2
    return None

def resolve_v2_evidence_pack(pack_path):
    if not evidence_pack_resolver.is_file():
        return {
            "status": "fail",
            "exit_code": 127,
            "errors": [f"evidence_pack_resolver_missing:{evidence_pack_resolver}"],
        }
    try:
        completed = subprocess.run(
            [str(evidence_pack_resolver), str(pack_path), "--json"],
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except Exception as exc:
        return {
            "status": "fail",
            "exit_code": 127,
            "errors": [f"evidence_pack_resolver_exec_failed:{type(exc).__name__}:{exc}"],
        }
    try:
        payload = json.loads(completed.stdout or "{}")
        if isinstance(payload, dict):
            payload["exit_code"] = completed.returncode
            if completed.stderr.strip():
                payload["stderr"] = completed.stderr.strip()
            return payload
    except Exception:
        pass
    return {
        "status": "fail",
        "exit_code": completed.returncode,
        "stdout": completed.stdout,
        "stderr": completed.stderr,
        "errors": ["evidence_pack_resolver_invalid_json"],
    }

def score_from_scorecard(pack_path):
    scorecard = pack_path / "scorecard.md"
    if not scorecard.is_file():
        return None
    try:
        text = scorecard.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return None
    match = re.search(r"Score:\s*(\d+(?:\.\d+)?)\s*/\s*1000", text, flags=re.I)
    return float(match.group(1)) if match else None

def score_from_compliance_json(pack_path):
    data = read_json(pack_path / "compliance.json")
    if not isinstance(data, dict) or data.get("_invalid_json"):
        return None
    for key in ("compliance_score", "score", "total_score", "final_score"):
        value = as_num(data.get(key))
        if isinstance(value, (int, float)):
            return float(value)
    return None

def convergence_from_pack(pack_path):
    for name in ("convergence.json", "manifest.json"):
        data = read_json(pack_path / name)
        if not isinstance(data, dict) or data.get("_invalid_json"):
            continue
        for key in ("convergence_streak", "zero_finding_rounds", "clean_rounds"):
            value = as_num(data.get(key))
            if isinstance(value, (int, float)):
                return int(value)
        convergence = data.get("convergence")
        if isinstance(convergence, dict):
            for key in ("streak", "convergence_streak", "zero_finding_rounds", "clean_rounds"):
                value = as_num(convergence.get(key))
                if isinstance(value, (int, float)):
                    return int(value)
    return None

def plan_artifact_paths(plan_dir):
    names = [
        "00-PLAN.md",
        "00-PLAN.json",
        "01-RESEARCH-DEEP-DIVE.md",
        "02-REFINE-FINAL.json",
        "02-REFINE.md",
        "03-AUDIT-FINDINGS.md",
        "04-BEADS-DAG.md",
        "05-POLISH.md",
        "STATE.json",
    ]
    paths = []
    for name in names:
        path = plan_dir / name
        if path.is_file():
            paths.append(path)
    for pattern in ("02-REFINE*.md", "02-REFINE*.json", "03-*.md", "04-*.md", "05-POLISH-r*.json"):
        for path in sorted(plan_dir.glob(pattern)):
            if path.is_file() and path not in paths:
                paths.append(path)
    return paths

def ev_anchors_in_plan_artifacts(plan_dir):
    anchors = set()
    sources = {}
    for path in plan_artifact_paths(plan_dir):
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for anchor in re.findall(r"\bEV-[0-9]{3,}\b", text):
            anchors.add(anchor)
            sources.setdefault(anchor, []).append(str(path))
    return anchors, sources

def evidence_rows_from_pack(pack_path):
    rows = []
    for name in ("evidence.json", "compliance.json", "manifest.json"):
        data = read_json(pack_path / name)
        if not isinstance(data, dict) or data.get("_invalid_json"):
            continue
        value = data.get("evidence")
        if isinstance(value, list):
            rows.extend(row for row in value if isinstance(row, dict))
    return rows

def compliance_findings_from_pack(pack_path):
    data = read_json(pack_path / "compliance.json")
    if not isinstance(data, dict) or data.get("_invalid_json"):
        return []
    findings = data.get("findings")
    return findings if isinstance(findings, list) else []

def active_finding_ids(pack_path):
    active = set()
    for row in compliance_findings_from_pack(pack_path):
        if not isinstance(row, dict):
            continue
        finding_id = row.get("id") or row.get("finding_id") or row.get("target_finding_id")
        status = str(row.get("status", "active")).strip().lower()
        if isinstance(finding_id, str) and finding_id and status != "closed":
            active.add(finding_id)
    return active

def resolve_ev_source_path(source_path, plan_dir, pack_path):
    candidate = Path(source_path).expanduser()
    if candidate.is_absolute() and candidate.is_file():
        return candidate
    for base in (plan_dir, repo, pack_path):
        resolved = base / source_path
        if resolved.is_file():
            return resolved
    return None

def parse_ev_source(source):
    if not isinstance(source, str):
        return None, None, None
    match = re.match(r"^(.+):([0-9]+)(?:-([0-9]+))?$", source)
    if not match:
        return None, None, None
    start = int(match.group(2))
    end = int(match.group(3) or match.group(2))
    if start < 1 or end < start:
        return None, None, None
    return match.group(1), start, end

def excerpt_from_source(source, plan_dir, pack_path):
    source_path, start, end = parse_ev_source(source)
    if source_path is None:
        return None
    path = resolve_ev_source_path(source_path, plan_dir, pack_path)
    if path is None:
        return None
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError:
        return None
    if end > len(lines):
        return None
    return "\n".join(lines[start - 1:end])

def validate_ev_anchors(plan_dir, pack_path):
    cited_anchors, anchor_sources = ev_anchors_in_plan_artifacts(plan_dir)
    evidence_rows = evidence_rows_from_pack(pack_path) if pack_path and pack_path.is_dir() else []
    ev_ids = {row.get("ev_id") for row in evidence_rows if isinstance(row.get("ev_id"), str)}
    missing = sorted(anchor for anchor in cited_anchors if anchor not in ev_ids)
    errors = []
    if missing:
        errors.append("ev_anchor_unresolved")
    active_ids = active_finding_ids(pack_path) if pack_path and pack_path.is_dir() else set()
    refute_targets = sorted({
        row.get("target_finding_id")
        for row in evidence_rows
        if row.get("relation") == "refutes" and row.get("target_finding_id") in active_ids
    })
    if refute_targets:
        errors.append("refute_contradiction_unresolved")
    excerpt_mismatches = []
    schema_errors = []
    for index, row in enumerate(evidence_rows, start=1):
        ev_id = row.get("ev_id")
        if not isinstance(ev_id, str) or not re.fullmatch(r"EV-[0-9]{3,}", ev_id):
            schema_errors.append(f"evidence_{index}_ev_id_invalid")
        relation = row.get("relation")
        if relation not in {"supports", "refutes", "informs"}:
            schema_errors.append(f"{ev_id or index}_relation_invalid")
        if not non_empty_str(row.get("target_finding_id")):
            schema_errors.append(f"{ev_id or index}_target_finding_id_missing")
        excerpt = row.get("excerpt")
        source = row.get("source")
        expected = excerpt_from_source(source, plan_dir, pack_path)
        if not isinstance(excerpt, str) or expected is None or excerpt != expected:
            excerpt_mismatches.append(ev_id if isinstance(ev_id, str) else f"row_{index}")
    if schema_errors:
        errors.append("ev_evidence_schema_invalid")
    if excerpt_mismatches:
        errors.append("evidence_excerpt_mismatch")
    status = "not_present"
    if cited_anchors or evidence_rows:
        status = "pass" if not errors else "fail"
    return {
        "ev_anchor_status": status,
        "ev_anchor_cited_count": len(cited_anchors),
        "ev_anchor_defined_count": len(ev_ids),
        "ev_anchor_missing": missing,
        "ev_anchor_sources": anchor_sources,
        "ev_evidence_rows_count": len(evidence_rows),
        "ev_evidence_schema_errors": sorted(set(schema_errors)),
        "ev_excerpt_mismatches": sorted(set(excerpt_mismatches)),
        "ev_refute_active_targets": refute_targets,
        "ev_anchor_errors": errors,
    }

def best_compliance_evidence(state, plan_dir):
    evidence = state.get("quality_bar_evidence")
    rows = evidence if isinstance(evidence, list) else []
    candidates = []
    for row in rows:
        if not isinstance(row, dict):
            continue
        pack_path = resolve_pack_path(row.get("compliance_pack_path") or row.get("evidence_pack_path"), plan_dir)
        if pack_path is None and isinstance(row.get("artifact"), str):
            artifact_path = resolve_pack_path(row.get("artifact"), plan_dir)
            if artifact_path and artifact_path.is_dir():
                pack_path = artifact_path
        row_score = as_num(row.get("compliance_score"))
        threshold = as_num(row.get("compliance_threshold"))
        row_streak = as_num(row.get("convergence_streak"))
        candidates.append({
            "row": row,
            "pack_path": pack_path,
            "row_score": float(row_score) if isinstance(row_score, (int, float)) else None,
            "threshold": int(threshold) if isinstance(threshold, (int, float)) else 700,
            "row_streak": int(row_streak) if isinstance(row_streak, (int, float)) else None,
        })
    return candidates

def evaluate_compliance_pack(state, plan_dir, result, pending, failing):
    result["quality_bar_mode"] = "compliance_pack"
    result["compliance_score"] = None
    result["compliance_threshold"] = 700
    result["compliance_pack_path"] = None
    result["compliance_pack_missing_files"] = []
    result["evidence_pack_version"] = None
    result["evidence_pack_resolves"] = None
    result["evidence_pack_resolution"] = None
    result["convergence_streak"] = None
    result["ev_anchor_status"] = "not_checked"
    result["ev_anchor_cited_count"] = 0
    result["ev_anchor_defined_count"] = 0
    result["ev_anchor_missing"] = []
    result["ev_anchor_sources"] = {}
    result["ev_evidence_rows_count"] = 0
    result["ev_evidence_schema_errors"] = []
    result["ev_excerpt_mismatches"] = []
    result["ev_refute_active_targets"] = []
    result["ev_anchor_errors"] = []
    candidates = best_compliance_evidence(state, plan_dir)
    if not candidates:
        pending.append("compliance_pack_path_missing")
        return
    usable = None
    for candidate in candidates:
        pack_path = candidate["pack_path"]
        if pack_path is not None:
            usable = candidate
            break
    if usable is None:
        pending.append("compliance_pack_path_missing")
        return
    pack_path = usable["pack_path"]
    result["compliance_pack_path"] = str(pack_path)
    result["compliance_threshold"] = usable["threshold"]
    ev_result = validate_ev_anchors(plan_dir, pack_path)
    result.update(ev_result)
    for error in ev_result["ev_anchor_errors"]:
        failing.append(error)
    result["evidence_pack_version"] = evidence_pack_version(pack_path)
    if result["evidence_pack_version"] == 2:
        resolution = resolve_v2_evidence_pack(pack_path)
        result["evidence_pack_resolution"] = resolution
        result["evidence_pack_resolves"] = "yes" if resolution.get("status") == "pass" else "no"
        if result["evidence_pack_resolves"] != "yes":
            failing.append("evidence_pack_unresolved")
        if isinstance(usable["row_score"], (int, float)):
            result["compliance_score"] = usable["row_score"]
        else:
            pending.append("compliance_score_missing")
        if isinstance(result["compliance_score"], (int, float)) and result["compliance_score"] < result["compliance_threshold"]:
            failing.append("compliance_score_below_700")
        root_streak = as_num(state.get("convergence_streak"))
        streak_candidates = [
            int(root_streak) if isinstance(root_streak, (int, float)) else None,
            usable["row_streak"],
        ]
        result["convergence_streak"] = next((value for value in streak_candidates if isinstance(value, int)), None)
        if result["convergence_streak"] is None:
            pending.append("convergence_streak_missing")
        elif result["convergence_streak"] < 2:
            failing.append("convergence_streak_below_2")
        return
    if not pack_path.is_dir():
        failing.append("compliance_pack_missing")
        return
    result["evidence_pack_resolves"] = "yes"
    missing = [name for name in REQUIRED_COMPLIANCE_PACK_FILES if not (pack_path / name).is_file()]
    result["compliance_pack_missing_files"] = missing
    if missing:
        failing.append("compliance_pack_incomplete")
    score_candidates = [
        usable["row_score"],
        score_from_compliance_json(pack_path),
        score_from_scorecard(pack_path),
    ]
    scores = [score for score in score_candidates if isinstance(score, (int, float))]
    if scores:
        result["compliance_score"] = min(scores)
    else:
        pending.append("compliance_score_missing")
    if isinstance(result["compliance_score"], (int, float)) and result["compliance_score"] < result["compliance_threshold"]:
        failing.append("compliance_score_below_700")
    root_streak = as_num(state.get("convergence_streak"))
    streak_candidates = [
        int(root_streak) if isinstance(root_streak, (int, float)) else None,
        usable["row_streak"],
        convergence_from_pack(pack_path),
    ]
    result["convergence_streak"] = next((value for value in streak_candidates if isinstance(value, int)), None)
    if result["convergence_streak"] is None:
        pending.append("convergence_streak_missing")
    elif result["convergence_streak"] < 2:
        failing.append("convergence_streak_below_2")

def non_empty_str(value):
    return isinstance(value, str) and bool(value.strip())

def validate_hypothesis_slate_object(obj):
    errors = []
    if not isinstance(obj, dict):
        return ["hypothesis_slate_source_not_object"]
    slate = obj.get("hypothesis_slate")
    if not isinstance(slate, list):
        errors.append("hypothesis_slate_missing")
        slate = []
    elif not (2 <= len(slate) <= 5):
        errors.append("hypothesis_count_not_2_to_5")
    ids = []
    third_count = 0
    valid_statuses = {"active", "killed", "adopted"}
    for index, row in enumerate(slate, start=1):
        if not isinstance(row, dict):
            errors.append(f"hypothesis_{index}_not_object")
            continue
        hid = row.get("id")
        ids.append(hid)
        if not (isinstance(hid, str) and re.fullmatch(r"H[1-5]", hid)):
            errors.append(f"hypothesis_{index}_invalid_id")
        for key in ("strategy", "kill_condition"):
            if not non_empty_str(row.get(key)):
                errors.append(f"{hid or index}_{key}_missing")
        if row.get("is_third_alternative") is True:
            third_count += 1
        elif row.get("is_third_alternative") not in (False, None):
            errors.append(f"{hid or index}_is_third_alternative_not_boolean")
        status = row.get("status")
        if status not in valid_statuses:
            errors.append(f"{hid or index}_status_invalid")
        if "killed_by" not in row:
            errors.append(f"{hid or index}_killed_by_missing")
        if "adopted_at_phase" not in row:
            errors.append(f"{hid or index}_adopted_at_phase_missing")
    if len(ids) != len(set(ids)):
        errors.append("hypothesis_ids_not_unique")
    if third_count != 1:
        errors.append("third_alternative_not_exactly_one")
    return errors

def iter_json_slate_candidates(plan_dir):
    names = ("02-REFINE-FINAL.json", "00-PLAN.json", "STATE.json")
    for name in names:
        path = plan_dir / name
        data = read_json(path)
        if isinstance(data, dict) and not data.get("_invalid_json"):
            yield str(path), data
    for path in sorted(plan_dir.glob("02-REFINE-r*.json")):
        data = read_json(path)
        if isinstance(data, dict) and not data.get("_invalid_json"):
            yield str(path), data
    for path in sorted(list(plan_dir.glob("02-REFINE*.md")) + list(plan_dir.glob("00-PLAN.md"))):
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for match in re.finditer(r"```(?:json)?\s*\n?(.*?)```", text, flags=re.S):
            try:
                data = json.loads(match.group(1).strip())
            except json.JSONDecodeError:
                continue
            if isinstance(data, dict) and "hypothesis_slate" in data:
                yield f"{path}#json_fence", data

def validate_hypothesis_slate(state, plan_dir, version):
    if version < 5:
        return {
            "hypothesis_slate_required": False,
            "hypothesis_slate_valid": "yes",
            "hypothesis_slate_source": "grandfathered_schema_version_lt_5",
            "hypothesis_slate_errors": [],
        }
    seen_errors = []
    seen_sources = set()
    for source, candidate in [("STATE.json", state)] + list(iter_json_slate_candidates(plan_dir)):
        if source in seen_sources:
            continue
        seen_sources.add(source)
        errors = validate_hypothesis_slate_object(candidate)
        if not errors:
            return {
                "hypothesis_slate_required": True,
                "hypothesis_slate_valid": "yes",
                "hypothesis_slate_source": source,
                "hypothesis_slate_errors": [],
            }
        seen_errors.extend(errors)
    return {
        "hypothesis_slate_required": True,
        "hypothesis_slate_valid": "no",
        "hypothesis_slate_source": None,
        "hypothesis_slate_errors": sorted(set(seen_errors)) or ["hypothesis_slate_missing"],
    }

def canonical_prediction_hash(prediction):
    payload = json.dumps(prediction, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()

def prediction_lock_rows(state):
    rows = state.get("predictions")
    return rows if isinstance(rows, list) else []

def prediction_lock_time(state):
    lock = state.get("prediction_lock")
    if isinstance(lock, dict):
        return lock.get("locked_at") or lock.get("lock_ts")
    return state.get("prediction_lock_ts") or state.get("lock_ts")

def validate_prediction_lock(state):
    rows = prediction_lock_rows(state)
    result = {
        "prediction_lock_present": bool(rows),
        "prediction_lock_status": "not_present",
        "prediction_lock_count": len(rows),
        "prediction_lock_locked_at": prediction_lock_time(state),
        "prediction_lock_errors": [],
    }
    if not rows:
        return result
    errors = []
    locked_at_raw = result["prediction_lock_locked_at"]
    locked_at = parse_dt(locked_at_raw)
    if not locked_at:
        errors.append("prediction_lock_missing_lock_ts")
    for index, row in enumerate(rows, start=1):
        if not isinstance(row, dict):
            errors.append(f"prediction_{index}_not_object")
            continue
        if "prediction" not in row:
            errors.append(f"prediction_{index}_text_missing")
            continue
        stored_hash = row.get("hash")
        recomputed_hash = canonical_prediction_hash(row.get("prediction"))
        if not isinstance(stored_hash, str) or not stored_hash:
            errors.append(f"prediction_{index}_hash_missing")
        elif stored_hash != recomputed_hash:
            errors.append("prediction_lock_post_hoc_amendment")
        row_ts = parse_dt(row.get("ts"))
        if not row_ts:
            errors.append(f"prediction_{index}_ts_missing")
        elif locked_at and row_ts > locked_at:
            errors.append("prediction_lock_post_hoc_addition")
        if not non_empty_str(row.get("applies_at_phase")):
            errors.append(f"prediction_{index}_applies_at_phase_missing")
    if errors:
        result["prediction_lock_status"] = "fail"
        result["prediction_lock_errors"] = sorted(set(errors))
    else:
        result["prediction_lock_status"] = "pass"
    return result

def int_value(value, default=0):
    parsed = as_num(value)
    if isinstance(parsed, (int, float)):
        return int(parsed)
    return default

def audit_findings_count(state):
    by_sev = state.get("audit_findings_by_severity")
    if isinstance(by_sev, dict):
        total = sum(int_value(value) for value in by_sev.values())
        if total:
            return total
    return int_value(state.get("audit_findings_count"))

def bead_count_for_complexity(state, plan_dir):
    candidates = [
        int_value(state.get("total_beads_in_dag")),
        int_value(state.get("beads_created_count")),
        int_value(state.get("bead_count")),
    ]
    beads = state.get("beads_created")
    if isinstance(beads, list):
        candidates.append(len(beads))
    dag_path = plan_dir / "04-BEADS-DAG.md"
    if dag_path.is_file():
        try:
            text = dag_path.read_text(encoding="utf-8", errors="replace")
            candidates.append(len(set(re.findall(r"\b[A-Za-z0-9._-]+-[A-Za-z0-9._-]{4,}\b", text))))
        except OSError:
            pass
    return max(candidates) if candidates else 0

def expected_polish_rounds(state, artifact_count):
    candidates = [
        int_value(state.get("expected_polish_rounds")),
        int_value(state.get("polish_rounds_expected")),
        int_value(state.get("phase5_expected_polish_rounds")),
        int_value(state.get("polish_round")),
        artifact_count,
    ]
    return max(candidates) if candidates else 0

def load_polish_telemetry_artifacts(plan_dir):
    rows = []
    for path in sorted(plan_dir.glob("05-POLISH-r*.json")):
        match = re.search(r"05-POLISH-r(\d+)\.json$", path.name)
        data = read_json(path)
        if not isinstance(data, dict) or data.get("_invalid_json"):
            rows.append({
                "path": str(path),
                "round": int(match.group(1)) if match else None,
                "valid": False,
                "stable": False,
                "reason": "invalid_json",
            })
            continue
        round_value = data.get("round")
        deltas = data.get("deltas")
        stability = data.get("stability")
        valid = (
            isinstance(round_value, int)
            and isinstance(deltas, dict)
            and all(isinstance(deltas.get(key), int) for key in ("adds", "edits", "kills", "total_changes"))
            and isinstance(data.get("open_findings_after"), int)
            and isinstance(stability, dict)
            and isinstance(stability.get("kills_gte_adds"), bool)
            and isinstance(stability.get("no_new_deltas"), bool)
        )
        stable = bool(valid and stability.get("kills_gte_adds") and stability.get("no_new_deltas"))
        rows.append({
            "path": str(path),
            "round": round_value if isinstance(round_value, int) else (int(match.group(1)) if match else None),
            "valid": valid,
            "stable": stable,
            "deltas": deltas if isinstance(deltas, dict) else {},
            "open_findings_after": data.get("open_findings_after"),
            "stability": stability if isinstance(stability, dict) else {},
            "reason": None if valid else "schema_invalid",
        })
    return sorted(rows, key=lambda row: row.get("round") or 0)

def evaluate_convergence_telemetry(state, plan_dir):
    artifacts = load_polish_telemetry_artifacts(plan_dir)
    bead_count = bead_count_for_complexity(state, plan_dir)
    findings_count = audit_findings_count(state)
    expected_rounds = expected_polish_rounds(state, len(artifacts))
    complex_reasons = []
    if bead_count >= 8:
        complex_reasons.append("beads_gte_8")
    if expected_rounds > 3:
        complex_reasons.append("polish_rounds_gt_3")
    if findings_count >= 5:
        complex_reasons.append("audit_findings_gte_5")
    is_complex = bool(complex_reasons)
    stable_streak = 0
    max_stable_streak = 0
    break_round = None
    for row in artifacts:
        if row.get("stable"):
            stable_streak += 1
            max_stable_streak = max(max_stable_streak, stable_streak)
        else:
            stable_streak = 0
            break_round = row.get("round")
    final_stable_streak = stable_streak
    status = "pass" if final_stable_streak >= 2 else "unstable"
    if not artifacts:
        status = "missing"
    if not is_complex and status != "pass":
        status = "advisory"
    return {
        "convergence_telemetry_required": is_complex,
        "convergence_telemetry_status": status,
        "convergence_telemetry_complex_reasons": complex_reasons,
        "convergence_telemetry_bead_count": bead_count,
        "convergence_telemetry_audit_findings_count": findings_count,
        "convergence_telemetry_expected_polish_rounds": expected_rounds,
        "convergence_telemetry_stable_rounds_required": 2 if is_complex else 0,
        "convergence_telemetry_final_stable_streak": final_stable_streak,
        "convergence_telemetry_max_stable_streak": max_stable_streak,
        "convergence_telemetry_break_round": break_round,
        "convergence_telemetry_rounds": artifacts,
    }

def load_prediction_input(path):
    data = read_json(Path(path))
    if not isinstance(data, (list, dict)) or (isinstance(data, dict) and data.get("_invalid_json")):
        raise SystemExit(f"prediction_file_invalid_json:{path}")
    if isinstance(data, dict):
        data = data.get("predictions")
    if not isinstance(data, list):
        raise SystemExit("prediction_file_predictions_not_array")
    predictions = []
    for index, row in enumerate(data, start=1):
        if isinstance(row, str):
            text = row
        elif isinstance(row, dict) and isinstance(row.get("prediction"), str):
            text = row["prediction"]
        else:
            raise SystemExit(f"prediction_{index}_invalid")
        if not text.strip():
            raise SystemExit(f"prediction_{index}_empty")
        predictions.append(text)
    if not predictions:
        raise SystemExit("prediction_file_empty")
    return predictions

def lock_predictions(slug_value, predictions_path, applies_at_phase, apply_changes, now_value):
    if not predictions_path:
        raise SystemExit("--predictions-file required")
    plan_dir = repo / ".flywheel" / "plans" / slug_value
    state_path = plan_dir / "STATE.json"
    state = read_json(state_path)
    if not isinstance(state, dict) or state.get("_invalid_json"):
        raise SystemExit(f"state_missing_or_invalid:{state_path}")
    predictions = load_prediction_input(predictions_path)
    rows = [
        {
            "prediction": prediction,
            "ts": now_value,
            "hash": canonical_prediction_hash(prediction),
            "applies_at_phase": applies_at_phase,
        }
        for prediction in predictions
    ]
    updated_state = dict(state)
    updated_state["prediction_lock"] = {
        "locked_at": now_value,
        "boundary": "phase2_to_phase3",
        "algorithm": "sha256-canonical-json-v1",
        "immutable_after_phase": 2,
    }
    updated_state["predictions"] = rows
    validation = validate_prediction_lock(updated_state)
    if validation["prediction_lock_status"] != "pass":
        raise SystemExit(",".join(validation["prediction_lock_errors"]))
    if apply_changes:
        state_path.write_text(json.dumps(updated_state, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    return {
        "schema_version": "quality-bar-close-gate.prediction-lock.v1",
        "command": "lock-predictions",
        "status": "pass",
        "plan_slug": slug_value,
        "state_path": str(state_path),
        "apply": bool(apply_changes),
        "prediction_lock": updated_state["prediction_lock"],
        "prediction_lock_count": len(rows),
        "predictions": rows,
    }

def min_evidence_score(evidence, key):
    values = []
    if isinstance(evidence, list):
        for row in evidence:
            if isinstance(row, dict):
                value = as_num(row.get(key))
                if isinstance(value, (int, float)):
                    values.append(float(value))
    return min(values) if values else None

def latest_evidence_time(state):
    dates = []
    evidence = state.get("quality_bar_evidence")
    if isinstance(evidence, list):
        for row in evidence:
            if isinstance(row, dict):
                for key in ("graded_at", "ts", "updated_at"):
                    dt = parse_dt(row.get(key))
                    if dt:
                        dates.append(dt)
    for key in ("quality_bar_graded_at", "ready_at", "phase_started_at", "started_at"):
        dt = parse_dt(state.get(key))
        if dt:
            dates.append(dt)
    return max(dates) if dates else None

def evaluate(slug_value):
    plan_dir = repo / ".flywheel" / "plans" / slug_value
    state_path = plan_dir / "STATE.json"
    audit_path = plan_dir / "03-AUDIT-FINDINGS.md"
    state = read_json(state_path)
    audit_text = None
    if audit_path.is_file():
        audit_text = audit_path.read_text(encoding="utf-8", errors="replace")
    result = {
        "schema_version": "quality-bar-close-gate.plan.v1",
        "plan_slug": slug_value,
        "plan_dir": str(plan_dir),
        "state_path": str(state_path),
        "audit_findings_path": str(audit_path),
        "state_present": state is not None,
        "audit_findings_present": audit_text is not None,
        "current_phase": None,
        "quality_bar_passed": None,
        "state_quality_bar_passed": None,
        "audit_disposition": None,
        "state_schema_version": None,
        "quality_bar_mode": None,
        "jeff": None,
        "donella": None,
        "joshua": None,
        "joshua_auto_advance": False,
        "composite": None,
        "compliance_score": None,
        "compliance_threshold": None,
        "compliance_pack_path": None,
        "compliance_pack_missing_files": [],
        "evidence_pack_version": None,
        "evidence_pack_resolves": None,
        "evidence_pack_resolution": None,
        "convergence_streak": None,
        "ev_anchor_status": "not_checked",
        "ev_anchor_cited_count": 0,
        "ev_anchor_defined_count": 0,
        "ev_anchor_missing": [],
        "ev_anchor_sources": {},
        "ev_evidence_rows_count": 0,
        "ev_evidence_schema_errors": [],
        "ev_excerpt_mismatches": [],
        "ev_refute_active_targets": [],
        "ev_anchor_errors": [],
        "hypothesis_slate_required": False,
        "hypothesis_slate_valid": "yes",
        "hypothesis_slate_source": None,
        "hypothesis_slate_errors": [],
        "prediction_lock_present": False,
        "prediction_lock_status": "not_present",
        "prediction_lock_count": 0,
        "prediction_lock_locked_at": None,
        "prediction_lock_errors": [],
        "convergence_telemetry_required": False,
        "convergence_telemetry_status": "not_checked",
        "convergence_telemetry_complex_reasons": [],
        "convergence_telemetry_bead_count": 0,
        "convergence_telemetry_audit_findings_count": 0,
        "convergence_telemetry_expected_polish_rounds": 0,
        "convergence_telemetry_stable_rounds_required": 0,
        "convergence_telemetry_final_stable_streak": 0,
        "convergence_telemetry_max_stable_streak": 0,
        "convergence_telemetry_break_round": None,
        "convergence_telemetry_rounds": [],
        "critical_findings": 0,
        "three_judges_evidence_present": False,
        "reasons": [],
        "decision": "pending",
        "result": "PENDING",
    }
    pending, failing = [], []
    if state is None:
        pending.append("state_missing")
        result["reasons"] = pending
        return result
    if isinstance(state, dict) and state.get("_invalid_json"):
        failing.append("state_invalid_json")
        result["reasons"] = failing
        result["decision"] = "fail"
        result["result"] = "FAIL"
        return result
    phase = state.get("current_phase")
    version = state_schema_version(state)
    result["current_phase"] = phase
    result["state_schema_version"] = version
    result["audit_disposition"] = state.get("audit_disposition")
    hypothesis_result = validate_hypothesis_slate(state, plan_dir, version)
    result.update(hypothesis_result)
    if result["hypothesis_slate_valid"] != "yes":
        failing.append("hypothesis_slate_invalid")
    prediction_lock_result = validate_prediction_lock(state)
    result.update(prediction_lock_result)
    for error in prediction_lock_result["prediction_lock_errors"]:
        failing.append(error)
    if version >= 5 and phase == "refine":
        result["quality_bar_mode"] = "phase2_hypothesis_slate"
        if failing:
            result["decision"] = "fail"
            result["result"] = "FAIL"
            result["reasons"] = failing
        else:
            result["decision"] = "pass"
            result["result"] = "PASS"
            result["reasons"] = []
        result["quality_bar_passed"] = result["decision"] == "pass"
        return result
    if phase not in {"polish", "ready"}:
        pending.append(f"current_phase_not_polish_or_ready:{phase}")
    if version >= 4:
        result["state_quality_bar_passed"] = None if "quality_bar_passed" not in state else truthy(state.get("quality_bar_passed"))
    elif "quality_bar_passed" not in state:
        pending.append("quality_bar_passed_missing")
    else:
        result["quality_bar_passed"] = truthy(state.get("quality_bar_passed"))
        if falsey(state.get("quality_bar_passed")):
            failing.append("quality_bar_passed_false")
        elif not truthy(state.get("quality_bar_passed")):
            pending.append("quality_bar_passed_unrecognized")
    if version >= 4:
        audit_scores = {}
        result["quality_bar_mode"] = "compliance_pack"
    elif audit_text is None:
        pending.append("audit_findings_missing")
        audit_scores = {}
    else:
        audit_scores = {
            "jeff_score": score_from_audit(audit_text, "jeff"),
            "donella_score": score_from_audit(audit_text, "donella"),
            "joshua_score": score_from_audit(audit_text, "joshua"),
            "composite": score_from_audit(audit_text, "composite"),
        }
        result["three_judges_evidence_present"] = all(audit_scores[k] is not None for k in ("jeff_score", "donella_score", "joshua_score"))
    evidence = state.get("quality_bar_evidence")
    if version >= 4:
        evaluate_compliance_pack(state, plan_dir, result, pending, failing)
    else:
        result["quality_bar_mode"] = "legacy_four_lens"
        state_scores = {
            "jeff_score": min_evidence_score(evidence, "jeff_score"),
            "donella_score": min_evidence_score(evidence, "donella_score"),
            "joshua_score": min_evidence_score(evidence, "joshua_score"),
            "composite": min_evidence_score(evidence, "composite"),
        }
        scores = {}
        for key in ("jeff_score", "donella_score", "joshua_score", "composite"):
            candidates = [v for v in (audit_scores.get(key), state_scores.get(key)) if isinstance(v, (int, float))]
            if candidates:
                scores[key] = min(candidates)
            elif audit_scores.get(key) == "auto_advance":
                scores[key] = "auto_advance"
            else:
                scores[key] = None
        result["jeff"] = scores["jeff_score"]
        result["donella"] = scores["donella_score"]
        result["joshua"] = scores["joshua_score"]
        result["composite"] = scores["composite"]
        if result["jeff"] is None:
            pending.append("jeff_score_missing")
        elif result["jeff"] < 9:
            failing.append("jeff_score_below_9")
        if result["donella"] is None:
            pending.append("donella_score_missing")
        elif result["donella"] < 9:
            failing.append("donella_score_below_9")
        auto_advance = state.get("audit_disposition") == "auto_advance"
        if audit_text and re.search(r"joshua_(score_)?auto_advance\s*[:=]\s*(true|yes|1)|joshua\s*[:=|]\s*auto_advance", audit_text, flags=re.I):
            auto_advance = True
        result["joshua_auto_advance"] = auto_advance
        if result["joshua"] is None:
            if auto_advance:
                result["joshua"] = "auto_advance"
            else:
                pending.append("joshua_score_missing")
        elif isinstance(result["joshua"], (int, float)) and result["joshua"] < 9 and not auto_advance:
            failing.append("joshua_score_below_9")
        if result["composite"] is None:
            pending.append("composite_missing")
        elif result["composite"] < 9.5:
            failing.append("composite_below_9_5")
    state_critical = 0
    by_sev = state.get("audit_findings_by_severity")
    if isinstance(by_sev, dict):
        state_critical = int(as_num(by_sev.get("critical")) or 0)
    state_critical = max(state_critical, int(as_num(state.get("critical_findings")) or 0))
    audit_critical = critical_from_audit(audit_text or "")
    critical = max(state_critical, audit_critical if audit_critical is not None else 0)
    result["critical_findings"] = critical
    if critical > 0:
        failing.append("critical_findings_present")
    convergence_telemetry = evaluate_convergence_telemetry(state, plan_dir)
    result.update(convergence_telemetry)
    if (
        result["convergence_telemetry_required"]
        and result["convergence_telemetry_status"] != "pass"
    ):
        failing.append("convergence_telemetry_unstable")
    if failing:
        result["decision"] = "fail"
        result["result"] = "FAIL"
        result["reasons"] = failing + pending
    elif pending:
        result["decision"] = "pending"
        result["result"] = "PENDING"
        result["reasons"] = pending
    else:
        result["decision"] = "pass"
        result["result"] = "PASS"
        result["reasons"] = []
    if version >= 4:
        result["quality_bar_passed"] = result["decision"] == "pass"
    dt = latest_evidence_time(state)
    result["quality_bar_graded_at"] = dt.isoformat().replace("+00:00", "Z") if dt else None
    result["quality_bar_graded_within_30d"] = bool(dt and dt >= datetime.now(timezone.utc) - timedelta(days=30))
    return result

def doctor():
    plans_dir = repo / ".flywheel" / "plans"
    rows = []
    if plans_dir.is_dir():
        for state_path in sorted(plans_dir.glob("*/STATE.json")):
            rows.append(evaluate(state_path.parent.name))
    polish_rows = [r for r in rows if r.get("current_phase") == "polish"]
    pending = [r for r in polish_rows if r.get("decision") == "pending"]
    failed = [r for r in polish_rows if r.get("decision") == "fail"]
    passed_recent = [r for r in rows if r.get("decision") == "pass" and r.get("quality_bar_graded_within_30d")]
    status = "pass"
    warnings, errors = [], []
    if len(pending) >= 50:
        status = "fail"
        errors.append({"code": "plan_state_quality_bar_pending_error", "count": len(pending), "threshold": 50})
    elif len(pending) >= 20:
        status = "warn"
        warnings.append({"code": "plan_state_quality_bar_pending_warn", "count": len(pending), "threshold": 20})
    if len(failed) >= 10:
        status = "fail"
        errors.append({"code": "plan_state_quality_bar_failed_error", "count": len(failed), "threshold": 10})
    elif len(failed) >= 5 and status != "fail":
        status = "warn"
        warnings.append({"code": "plan_state_quality_bar_failed_warn", "count": len(failed), "threshold": 5})
    return {
        "schema_version": "quality-bar-close-gate.doctor.v1",
        "status": status,
        "repo": str(repo),
        "plans_dir": str(plans_dir),
        "thresholds": {"pending": {"warn": 20, "error": 50}, "failed": {"warn": 5, "error": 10}},
        "plan_state_quality_bar_pending_count": len(pending),
        "plan_state_quality_bar_failed_count": len(failed),
        "plan_state_quality_bar_passed_count": len(passed_recent),
        "pending_plans": [{"plan_slug": r["plan_slug"], "reasons": r["reasons"]} for r in pending[:20]],
        "failed_plans": [{"plan_slug": r["plan_slug"], "reasons": r["reasons"]} for r in failed[:20]],
        "checked_plans_count": len(rows),
        "warnings": warnings,
        "errors": errors,
    }

if mode == "plan":
    print(json.dumps(evaluate(slug), sort_keys=True, separators=(",", ":")))
elif mode == "doctor":
    print(json.dumps(doctor(), sort_keys=True, separators=(",", ":")))
elif mode == "lock-predictions":
    print(json.dumps(lock_predictions(slug, predictions_file, applies_at_phase, apply_raw == "1", now_value), sort_keys=True, separators=(",", ":")))
else:
    raise SystemExit(f"unknown mode: {mode}")
PY
}

evaluate_plan_json() {
  [[ -n "$PLAN_SLUG" ]] || { echo "ERR: --plan-slug required" >&2; return 2; }
  quality_bar_python plan
}

doctor_json() {
  quality_bar_python doctor
}

lock_predictions_json() {
  [[ -n "$PLAN_SLUG" ]] || { echo "ERR: --plan-slug required" >&2; return 2; }
  [[ -n "$PREDICTIONS_FILE" ]] || { echo "ERR: --predictions-file required" >&2; return 2; }
  quality_bar_python lock-predictions
}

contract_row_json() {
  jq -nc \
    --arg ts "$(now_iso)" \
    '{primitive_name:"quality-bar-close-gate",declares_loop:"yes",self_repair_action:"quality-bar-close-gate.sh --repair --scope all --apply",measurement_field:"plan_state_quality_bar_pending_count",escalation_path:"fuckup-log:class=phase5-quality-bar-close-gate",schema_version:"substrate-loop-contract.v1",bootstrap_seed_v1:"Phase 5 close gate audits quality_bar_passed before current_phase=ready",ts:$ts}'
}

contract_row_present() {
  [[ -s "$CONTRACT_LEDGER" ]] || return 1
  jq -s -e '
    [ .[] | select(.primitive_name == "quality-bar-close-gate" and .schema_version == "substrate-loop-contract.v1") ]
    | length > 0
  ' "$CONTRACT_LEDGER" >/dev/null
}

ensure_contract_row() {
  if contract_row_present; then
    printf 'present\n'
    return 0
  fi
  append_validated "$CONTRACT_LEDGER" "$(contract_row_json)"
  printf 'appended\n'
}

ledger_row_json() {
  local payload="$1"
  jq -c --arg ts "$(now_iso)" --arg schema "quality-bar-close-gate.ledger.v1" '
    {
      schema_version:$schema,
      ts:$ts,
      plan_slug:.plan_slug,
      decision:.decision,
      quality_bar_mode:.quality_bar_mode,
      jeff:.jeff,
      donella:.donella,
      joshua:.joshua,
      composite:.composite,
      compliance_score:.compliance_score,
      compliance_threshold:.compliance_threshold,
      compliance_pack_path:.compliance_pack_path,
      evidence_pack_version:.evidence_pack_version,
      evidence_pack_resolves:.evidence_pack_resolves,
      convergence_streak:.convergence_streak,
      ev_anchor_status:.ev_anchor_status,
      ev_anchor_cited_count:.ev_anchor_cited_count,
      ev_evidence_rows_count:.ev_evidence_rows_count,
      convergence_telemetry_status:.convergence_telemetry_status,
      convergence_telemetry_final_stable_streak:.convergence_telemetry_final_stable_streak,
      convergence_telemetry_max_stable_streak:.convergence_telemetry_max_stable_streak,
      critical_findings:.critical_findings,
      reasons:.reasons
    }
  ' <<<"$payload"
}

ntm_surface_coverage_gate_json() {
  if [[ "$PLAN_SLUG" != *"ntm-surface-wire-in"* ]]; then
    jq -nc '{applies:false,status:"not_applicable"}'
    return 0
  fi
  if [[ ! -x "$NTM_COVERAGE_TREND_SCRIPT" ]]; then
    jq -nc --arg path "$NTM_COVERAGE_TREND_SCRIPT" '{applies:true,status:"fail",reason:"ntm_surface_coverage_trend_missing",script:$path,coverage_avg:null,minimum_coverage_avg:7}'
    return 0
  fi
  local output rc
  set +e
  output="$("$NTM_COVERAGE_TREND_SCRIPT" status --json 2>/dev/null)"
  rc=$?
  set -e
  if [[ -z "$output" ]] || ! jq -e 'type=="object"' >/dev/null 2>&1 <<<"$output"; then
    jq -nc --arg path "$NTM_COVERAGE_TREND_SCRIPT" --argjson rc "$rc" '{applies:true,status:"fail",reason:"ntm_surface_coverage_trend_invalid_json",script:$path,exit_code:$rc,coverage_avg:null,minimum_coverage_avg:7}'
    return 0
  fi
  jq -c --arg path "$NTM_COVERAGE_TREND_SCRIPT" '
    (.coverage_avg // null) as $avg
    | . + {
        applies:true,
        script:$path,
        minimum_coverage_avg:7,
        status:(if (($avg // -1) | tonumber) >= 7 then "pass" else "fail" end),
        reason:(if (($avg // -1) | tonumber) >= 7 then null else "ntm_surface_coverage_below_7" end)
      }
  ' <<<"$output"
}

run_validate() {
  local payload decision rc ledger_action="not_requested" ntm_gate ntm_gate_status ntm_gate_reason ntm_gate_avg
  payload="$(evaluate_plan_json)"
  ntm_gate="$(ntm_surface_coverage_gate_json)"
  ntm_gate_status="$(jq -r '.status // "not_applicable"' <<<"$ntm_gate")"
  if [[ "$ntm_gate_status" == "fail" ]]; then
    ntm_gate_reason="$(jq -r '.reason // "ntm_surface_coverage_gate_failed"' <<<"$ntm_gate")"
    ntm_gate_avg="$(jq -r '.coverage_avg // "unknown"' <<<"$ntm_gate")"
    echo "NTM coverage close gate failed: coverage_avg=${ntm_gate_avg} < 7.0 for future wire-in plan; run ntm-surface-coverage-trend.sh chart --days 7 --jsonl and close coverage gaps before ready." >&2
    payload="$(jq -c --arg reason "$ntm_gate_reason" --argjson gate "$ntm_gate" '
      .ntm_surface_coverage_trend = $gate
      | .decision = "fail"
      | .result = "FAIL"
      | .reasons = (((.reasons // []) + [$reason]) | unique)
    ' <<<"$payload")"
  else
    payload="$(jq -c --argjson gate "$ntm_gate" '.ntm_surface_coverage_trend = $gate' <<<"$payload")"
  fi
  decision="$(jq -r '.decision' <<<"$payload")"
  if [[ "$APPLY" -eq 1 ]]; then
    append_validated "$LEDGER" "$(ledger_row_json "$payload")"
    ledger_action="appended"
  fi
  payload="$(jq -c --argjson dry_run "$(json_bool "$DRY_RUN")" --argjson apply "$(json_bool "$APPLY")" --arg ledger "$LEDGER" --arg ledger_action "$ledger_action" '. + {dry_run:$dry_run,apply:$apply,ledger_path:$ledger,ledger_action:$ledger_action}' <<<"$payload")"
  [[ "$decision" == "pass" ]] && rc=0 || rc=1
  emit "$payload" "$(jq -r '.result + " plan=" + .plan_slug + " reason=" + ((.reasons // []) | join(","))' <<<"$payload")" "$rc"
}

run_doctor() {
  local payload contract_action
  contract_action="$(ensure_contract_row)"
  payload="$(doctor_json | jq -c --arg contract_action "$contract_action" --arg contract_ledger "$CONTRACT_LEDGER" '. + {substrate_loop_contract_self_row_action:$contract_action,substrate_loop_contract_ledger:$contract_ledger}')"
  emit "$payload" "status=$(jq -r '.status' <<<"$payload") pending=$(jq -r '.plan_state_quality_bar_pending_count' <<<"$payload") failed=$(jq -r '.plan_state_quality_bar_failed_count' <<<"$payload") passed=$(jq -r '.plan_state_quality_bar_passed_count' <<<"$payload")" 0
}

run_lock_predictions() {
  local payload
  payload="$(lock_predictions_json)"
  emit "$payload" "prediction_lock plan=$(jq -r '.plan_slug' <<<"$payload") count=$(jq -r '.prediction_lock_count' <<<"$payload") apply=$(jq -r '.apply' <<<"$payload")" 0
}

run_health() {
  local payload
  while :; do
    payload="$(doctor_json)"
    emit "$payload" "health=$(jq -r '.status' <<<"$payload") pending=$(jq -r '.plan_state_quality_bar_pending_count' <<<"$payload")" 0 || true
    [[ "$WATCH" -eq 1 ]] || break
    sleep "$WATCH_INTERVAL"
  done
}

run_repair() {
  local planned actual="[]" contract_action="not_requested" payload
  case "$REPAIR_SCOPE" in
    ledger|substrate-contract|all) ;;
    *) echo "ERR: unsupported repair scope: $REPAIR_SCOPE" >&2; return 2 ;;
  esac
  planned="$(jq -nc --arg ledger "$LEDGER" --arg contract_ledger "$CONTRACT_LEDGER" --arg scope "$REPAIR_SCOPE" '{scope:$scope,would_write:[($ledger|split("/")[:-1]|join("/")),($contract_ledger|split("/")[:-1]|join("/"))],would_delete:[],blocked_by:[]}')"
  if [[ "$APPLY" -eq 1 ]]; then
    mkdir -p "$(dirname "$LEDGER")" "$(dirname "$CONTRACT_LEDGER")"
    if [[ "$REPAIR_SCOPE" == "substrate-contract" || "$REPAIR_SCOPE" == "all" ]]; then
      contract_action="$(ensure_contract_row)"
      actual="$(jq -c --arg action "$contract_action" '. + [{action:"ensure_substrate_contract_row",result:$action}]' <<<"$actual")"
    fi
  fi
  payload="$(jq -nc --arg scope "$REPAIR_SCOPE" --argjson dry_run "$(json_bool "$DRY_RUN")" --argjson apply "$(json_bool "$APPLY")" --argjson planned "$planned" --argjson actual "$actual" --arg contract_action "$contract_action" '{command:"repair",scope:$scope,status:"pass",dry_run:$dry_run,apply:$apply,planned_actions:[$planned],actual_actions:$actual,substrate_loop_contract_self_row_action:$contract_action}')"
  emit "$payload" "repair scope=$REPAIR_SCOPE apply=$APPLY" 0
}

run_audit() {
  local payload
  if [[ -s "$LEDGER" ]]; then
    payload="$(tail -20 "$LEDGER" | jq -s -c 'map(select(type=="object")) | {command:"audit",status:"pass",rows:.}')"
  else
    payload="$(jq -nc '{command:"audit",status:"pass",rows:[]}')"
  fi
  emit "$payload" "audit_rows=$(jq -r '.rows | length' <<<"$payload")" 0
}

# flywheel-bg06b: Shape A canonical invertibility per audit-machinery-hygiene-discipline.
# `why list` enumerates all known codes; `why <code>` returns explanation envelope.
# Each known code maps to (explanation, source location, inversion path). Source
# locations are file:approx-line indicators showing where the code is emitted.
run_why() {
  local text payload source inversion
  case "$WHY_ID" in
    list)
      # Enumerate all known codes as a structured JSON array — Shape A
      # invertibility surface: operators see what's auditable without grepping.
      payload="$(jq -nc '{
        command:"why",
        id:"list",
        schema_version:"quality-bar-close-gate.why-list.v1",
        registry_size:15,
        codes:[
          "quality_bar_passed_missing","compliance_pack_path_missing","compliance_pack_missing",
          "compliance_pack_incomplete","compliance_score_below_700","convergence_streak_below_2",
          "convergence_streak_missing","ev_anchor_unresolved","refute_contradiction_unresolved",
          "evidence_excerpt_mismatch","ev_evidence_schema_invalid","convergence_telemetry_unstable",
          "prediction_lock_post_hoc_amendment","prediction_lock_post_hoc_addition","audit_findings_missing"
        ],
        wildcard_patterns:["*_below_*","critical_findings_present","quality_bar_passed_false"],
        catchall:"Inspect the plan validation JSON for the exact reason list."
      }')"
      emit "$payload" "why list: 15 codes + 3 wildcard patterns registered" 0
      return
      ;;
    quality_bar_passed_missing) text="STATE.json lacks quality_bar_passed; Phase 5 close stays pending until the quality bar evidence is written." ; source="run_validate state JSON parse (~line 992-1100)" ; inversion="Check STATE.json under .plans/<slug>/ for quality_bar_passed field" ;;
    compliance_pack_path_missing) text="STATE.json schema v4 lacks quality_bar_evidence[].compliance_pack_path; Phase 5 close stays pending until the beads-compliance evidence pack is cited." ; source="run_validate state JSON parse (~line 992-1100)" ; inversion="Check STATE.json quality_bar_evidence[] array for compliance_pack_path entries" ;;
    compliance_pack_missing|compliance_pack_incomplete) text="The cited beads-compliance pack is missing or incomplete; close requires spec/evidence/compliance/theater/test-depth/scorecard/report files." ; source="evidence_pack_resolver invocation (~line 270-310)" ; inversion="Run evidence-pack-resolve.sh on the compliance_pack_path; check for the 7 required pack files" ;;
    compliance_score_below_700) text="The beads-compliance score is below the 700/1000 close threshold." ; source="run_validate state JSON parse + threshold check" ; inversion="Verify STATE.json compliance_score >= 700; rerun beads-compliance audit if score is stale" ;;
    convergence_streak_below_2|convergence_streak_missing) text="The compliance pack has not shown two consecutive zero-finding rounds; close stays blocked until convergence_streak >= 2." ; source="run_validate state JSON parse" ; inversion="Check STATE.json convergence_streak field; needs >=2 consecutive zero-finding polish rounds" ;;
    ev_anchor_unresolved) text="A plan artifact cites an EV anchor that is missing from the compliance pack evidence array." ; source="run_validate EV anchor resolver (~line 480-570)" ; inversion="Grep plan artifacts for EV-NNN references; verify each is in compliance_pack evidence[]" ;;
    refute_contradiction_unresolved) text="A still-active finding has refuting evidence in the compliance pack; close requires resolving that contradiction first." ; source="run_validate refute-relation resolver" ; inversion="Inspect compliance_pack evidence[] for relation=refutes rows pointing at active findings" ;;
    evidence_excerpt_mismatch) text="A compliance-pack evidence excerpt does not exactly match its cited source line." ; source="run_validate evidence-excerpt match check" ; inversion="Compare each evidence[i].excerpt against the cited source_line; mismatches need re-extraction" ;;
    ev_evidence_schema_invalid) text="A compliance-pack evidence row has an invalid EV id, relation, or target finding id." ; source="run_validate EV evidence schema check" ; inversion="Validate each evidence[] row: ev_id format, relation in {supports,refutes}, target_finding_id valid" ;;
    convergence_telemetry_unstable) text="Complex plans require two consecutive stable polish telemetry rounds where kills_gte_adds=true and no_new_deltas=true." ; source="run_validate convergence telemetry check" ; inversion="Inspect 05-POLISH-rN.json files for the last 2 rounds; both must show kills_gte_adds=true + no_new_deltas=true" ;;
    prediction_lock_post_hoc_amendment) text="A locked prediction no longer matches its pre-execution hash; close is blocked until the plan records the amendment as a failed lock." ; source="run_validate prediction-lock resolver (~line 730-770)" ; inversion="Compare locked prediction's current hash against its lock-time hash in 04-PREDICTION-LOCK.json" ;;
    prediction_lock_post_hoc_addition) text="A prediction row was timestamped after the plan lock boundary; close is blocked because the receipt was amended after convergence." ; source="run_validate prediction-lock resolver" ; inversion="Verify each prediction's timestamp predates the convergence lock boundary in 04-PREDICTION-LOCK.json" ;;
    audit_findings_missing) text="03-AUDIT-FINDINGS.md is missing; close-time gate cannot verify the 3-judges audit evidence." ; source="run_validate audit-text read (~line 994-1000)" ; inversion="Check .plans/<slug>/03-AUDIT-FINDINGS.md exists and contains 3-judges audit content" ;;
    *_below_*|critical_findings_present|quality_bar_passed_false) text="The quality bar explicitly fails; do not auto-close the plan." ; source="run_validate threshold-comparison emit" ; inversion="Inspect STATE.json + plan validation JSON for the specific threshold below the minimum" ;;
    *) text="Inspect the plan validation JSON for the exact reason list." ; source="run_why catchall" ; inversion="Run validate --plan-slug <slug> --json and inspect .errors[]" ;;
  esac
  payload="$(jq -nc --arg id "$WHY_ID" --arg text "$text" --arg src "$source" --arg inv "$inversion" '{command:"why",id:$id,explanation:$text,source:$src,inversion:$inv}')"
  emit "$payload" "$text" 0
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --doctor|doctor) MODE="doctor"; shift ;;
      --health|health) MODE="health"; shift ;;
      --repair|repair) MODE="repair"; shift ;;
      lock-predictions|--lock-predictions) MODE="lock-predictions"; shift ;;
      validate) MODE="validate"; [[ "${2:-}" == "plan" ]] && shift 2 || shift ;;
      audit) MODE="audit"; shift ;;
      why) MODE="why"; WHY_ID="${2:-}"; shift $(( $# > 1 ? 2 : 1 )) ;;
      schema) MODE="schema"; SCHEMA_TOPIC="${2:-plan}"; shift $(( $# > 1 ? 2 : 1 )) ;;
      quickstart) MODE="quickstart"; shift ;;
      help) MODE="help"; SCHEMA_TOPIC="${2:-overview}"; shift $(( $# > 1 ? 2 : 1 )) ;;
      completion) MODE="completion"; COMPLETION_SHELL="${2:-}"; shift $(( $# > 1 ? 2 : 1 )) ;;
      --info) MODE="info"; shift ;;
      --examples|examples) MODE="examples"; shift ;;
      --plan-slug) PLAN_SLUG="${2:-}"; shift 2 ;;
      --plan-slug=*) PLAN_SLUG="${1#*=}"; shift ;;
      --repo) REPO_ROOT="${2:-}"; shift 2 ;;
      --repo=*) REPO_ROOT="${1#*=}"; shift ;;
      --ledger) LEDGER="${2:-}"; shift 2 ;;
      --ledger=*) LEDGER="${1#*=}"; shift ;;
      --contract-ledger) CONTRACT_LEDGER="${2:-}"; shift 2 ;;
      --contract-ledger=*) CONTRACT_LEDGER="${1#*=}"; shift ;;
      --scope) REPAIR_SCOPE="${2:-}"; shift 2 ;;
      --scope=*) REPAIR_SCOPE="${1#*=}"; shift ;;
      --predictions-file) PREDICTIONS_FILE="${2:-}"; shift 2 ;;
      --predictions-file=*) PREDICTIONS_FILE="${1#*=}"; shift ;;
      --applies-at-phase) APPLIES_AT_PHASE="${2:-}"; shift 2 ;;
      --applies-at-phase=*) APPLIES_AT_PHASE="${1#*=}"; shift ;;
      --apply) APPLY=1; DRY_RUN=0; shift ;;
      --dry-run) APPLY=0; DRY_RUN=1; shift ;;
      --watch) WATCH=1; shift ;;
      --interval) WATCH_INTERVAL="${2:-5}"; shift 2 ;;
      --json) JSON_OUT=1; shift ;;
      --width) WIDTH="${2:-100}"; shift 2 ;;
      --no-color|--no-emoji|--explain) shift ;;
      -h|--help) usage; exit 0 ;;
      *) echo "ERR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
  done
  if [[ -z "$MODE" && -n "$PLAN_SLUG" ]]; then
    MODE="validate"
  elif [[ -z "$MODE" ]]; then
    MODE="doctor"
  fi
}

main() {
  parse_args "$@"
  case "$MODE" in
    doctor) run_doctor ;;
    health) run_health ;;
    repair) run_repair ;;
    lock-predictions) run_lock_predictions ;;
    validate) run_validate ;;
    audit) run_audit ;;
    why) [[ -n "$WHY_ID" ]] || { echo "ERR: why requires REASON" >&2; exit 2; }; run_why ;;
    schema) schema_json ;;
    info) emit "$(info_json)" "quality-bar-close-gate $VERSION" 0 ;;
    examples) if [[ "$JSON_OUT" -eq 1 ]]; then examples_text | jq -R -s -c '{command:"examples",examples:split("\n")|map(select(length>0))}'; else examples_text; fi ;;
    quickstart) if [[ "$JSON_OUT" -eq 1 ]]; then quickstart_text | jq -R -s -c '{command:"quickstart",steps:split("\n")|map(select(length>0))}'; else quickstart_text; fi ;;
    help) usage ;;
    completion) completion ;;
    *) echo "ERR: unknown mode: $MODE" >&2; exit 2 ;;
  esac
}

main "$@"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-04-receipt-callback-envelope.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-88-content-addressed-evidence-pack.md`
