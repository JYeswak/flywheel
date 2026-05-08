#!/usr/bin/env bash
# canonical-cli-scoping-allow-large: 3fzcm needs one portable watcher with doctor/health/repair plus synthetic fixture tests.
set -euo pipefail

VERSION="storage-headroom-watcher.v1.0.0"
SCHEMA_VERSION="storage-headroom-watcher.v1"
CONTRACT_SCHEMA_VERSION="substrate-loop-contract.v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO_ROOT="${STORAGE_HEADROOM_WATCHER_REPO:-$REPO_ROOT_DEFAULT}"
LEDGER="${STORAGE_HEADROOM_WATCHER_LEDGER:-$HOME/.local/state/flywheel/storage-headroom-watcher.jsonl}"
CONTRACT_LEDGER="${STORAGE_HEADROOM_WATCHER_CONTRACT_LEDGER:-$HOME/.local/state/flywheel/substrate-loop-contract.jsonl}"
FUCKUP_LOG="${STORAGE_HEADROOM_WATCHER_FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
PROBE="${STORAGE_HEADROOM_WATCHER_PROBE:-$SCRIPT_DIR/storage-probe.sh}"
JSONL_APPEND_LIB="${STORAGE_HEADROOM_WATCHER_JSONL_APPEND_LIB:-${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}}"

MODE="run"
JSON_OUT=0
APPLY=0
DRY_RUN=1
AUTO=0
WATCH=0
WATCH_INTERVAL=300
BUFFER_GB="${STORAGE_HEADROOM_WATCHER_BUFFER_GB:-55}"
STOP_GB="${STORAGE_HEADROOM_WATCHER_STOP_GB:-60}"
AUTO_APPLY_THRESHOLD_GB="${STORAGE_HEADROOM_WATCHER_AUTO_APPLY_THRESHOLD_GB:-50}"
FIXTURE="${STORAGE_HEADROOM_WATCHER_FIXTURE:-}"
TRIGGER="${STORAGE_HEADROOM_WATCHER_TRIGGER:-manual}"
REPAIR_SCOPE="substrate-contract"
VALIDATE_TARGET="ledger"
WHY_ID=""
SCHEMA_TOPIC="run"
COMPLETION_SHELL=""

usage() {
  cat <<'EOF'
usage:
  storage-headroom-watcher.sh [--dry-run|--apply|--auto] [--buffer-gb N] [--stop-gb N] [--json]
  storage-headroom-watcher.sh --doctor [--json]
  storage-headroom-watcher.sh health [--watch] [--interval N] [--json]
  storage-headroom-watcher.sh repair --scope ledger|substrate-contract|all [--dry-run|--apply] [--json]
  storage-headroom-watcher.sh validate ledger|protected-paths [--json]
  storage-headroom-watcher.sh audit [--json]
  storage-headroom-watcher.sh why ID [--json]
  storage-headroom-watcher.sh schema run|doctor|ledger|contract|fixture [--json]
  storage-headroom-watcher.sh --info|--examples|quickstart|help TOPIC|completion bash|zsh
EOF
}

json_bool() {
  if [[ "$1" == "1" ]]; then printf true; else printf false; fi
}

now_iso() {
  printf '%s\n' "${STORAGE_HEADROOM_WATCHER_NOW:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
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

rows_json() {
  if [[ -s "$LEDGER" ]]; then
    jq -s -c 'map(select(type == "object"))' "$LEDGER" 2>/dev/null || printf '[]\n'
  else
    printf '[]\n'
  fi
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
    '{primitive_name:"storage-headroom-watcher",declares_loop:"yes",self_repair_action:"storage-headroom-watcher.sh --apply",measurement_field:"storage_headroom_watcher_apply_count_24h",escalation_path:"doctor scope error -> fuckup-log:class=storage-headroom-prune-exhausted",schema_version:$schema_version,bootstrap_seed_v1:"3fzcm recurring storage-headroom watcher self-row",ts:$ts}'
}

valid_contract_self_row_present() {
  contract_rows_json | jq -e --arg schema "$CONTRACT_SCHEMA_VERSION" '
    [ .[] | select(.primitive_name == "storage-headroom-watcher") ]
    | last
    | type == "object"
      and .declares_loop == "yes"
      and (.self_repair_action // "") != ""
      and (.measurement_field // "") == "storage_headroom_watcher_apply_count_24h"
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
    --arg name "storage-headroom-watcher.sh" \
    --arg version "$VERSION" \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg repo "$REPO_ROOT" \
    --arg ledger "$LEDGER" \
    --arg contract_ledger "$CONTRACT_LEDGER" \
    --arg fuckup_log "$FUCKUP_LOG" \
    --arg probe "$PROBE" \
    --argjson buffer "$BUFFER_GB" \
    --argjson stop "$STOP_GB" \
    --argjson auto_threshold "$AUTO_APPLY_THRESHOLD_GB" \
    '{name:$name,version:$version,schema_version:$schema_version,repo:$repo,ledger:$ledger,substrate_loop_contract_ledger:$contract_ledger,fuckup_log:$fuckup_log,probe:$probe,defaults:{dry_run:true,buffer_gb:$buffer,stop_gb:$stop,auto_apply_threshold_gb:$auto_threshold},safe_categories:["docker-model-runner-image-revert","docker-unused-images","pnpm-store-prune","go-clean-cache-modcache","ml-model-cache-files"],protected_paths:["~/.local/bin/*.bak*","~/.local/share/flywheel-watchers/backups/","active workspaces",".beads",".git"],exit_codes:{"0":"ok or watcher dry-run/apply completed","1":"safe categories exhausted before buffer","2":"usage error","3":"append primitive unavailable or append failed"}}'
}

examples_text() {
  cat <<'EOF'
storage-headroom-watcher.sh --json
storage-headroom-watcher.sh --auto --trigger tick --json
storage-headroom-watcher.sh --apply --buffer-gb 55 --stop-gb 60 --json
storage-headroom-watcher.sh --doctor --json | jq '.storage_headroom_watcher_apply_count_24h'
storage-headroom-watcher.sh repair --scope all --apply --json
EOF
}

quickstart_text() {
  cat <<'EOF'
1. Run without --apply to dry-run safe storage categories against the current storage probe.
2. Tick close should use --auto; it only switches to --apply below 50GB free.
3. Apply stops once free space reaches the stop target, default 60GB.
4. If safe categories cannot reach the buffer, the watcher logs storage-headroom-prune-exhausted.
EOF
}

schema_json() {
  case "$SCHEMA_TOPIC" in
    run)
      jq -nc '{schema_version:"storage-headroom-watcher.run.v1",required:["disk_free_gb_before","disk_free_gb_after","buffer_gb","dry_run","apply","categories_to_prune","protected_paths_enforced"]}' ;;
    doctor)
      jq -nc '{schema_version:"storage-headroom-watcher.doctor.v1",required:["storage_headroom_watcher_last_fired_ts","storage_headroom_watcher_last_apply_ts","storage_headroom_watcher_apply_count_24h","storage_headroom_watcher_buffer_gb","storage_headroom_watcher_freed_mb_24h"]}' ;;
    ledger)
      jq -nc '{schema_version:"storage-headroom-watcher.ledger.v1",required:["ts","trigger","buffer_gb","disk_free_gb_before","disk_free_gb_after","freed_mb","categories_pruned","exhausted"]}' ;;
    contract)
      jq -nc --arg schema_version "$CONTRACT_SCHEMA_VERSION" '{schema_version:$schema_version,required:["primitive_name","declares_loop","self_repair_action","measurement_field","escalation_path","schema_version","bootstrap_seed_v1"]}' ;;
    fixture)
      jq -nc '{schema_version:"storage-headroom-watcher.fixture.v1",fields:["disk_free_gb","category_freed_mb","candidate_paths"]}' ;;
    *)
      echo "ERR: unknown schema topic: $SCHEMA_TOPIC" >&2
      return 2 ;;
  esac
}

completion() {
  case "$COMPLETION_SHELL" in
    bash)
      cat <<'EOF'
_storage_headroom_watcher_completion() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "--doctor health repair validate audit why schema --dry-run --apply --auto --buffer-gb --stop-gb --auto-apply-threshold-gb --trigger --fixture --ledger --json --info --examples quickstart help completion --scope --watch --interval" -- "$cur") )
}
complete -F _storage_headroom_watcher_completion storage-headroom-watcher.sh
EOF
      ;;
    zsh)
      printf 'compadd -- --doctor health repair validate audit why schema --dry-run --apply --auto --buffer-gb --stop-gb --auto-apply-threshold-gb --trigger --fixture --ledger --json --info --examples quickstart help completion --scope --watch --interval\n'
      ;;
    *)
      echo "ERR: completion shell must be bash or zsh" >&2
      return 2 ;;
  esac
}

watcher_py() {
  local py_mode="$1" contract_action="${2:-not_requested}"
  python3 - "$py_mode" "$REPO_ROOT" "$LEDGER" "$CONTRACT_LEDGER" "$FUCKUP_LOG" "$PROBE" "$FIXTURE" "$BUFFER_GB" "$STOP_GB" "$AUTO_APPLY_THRESHOLD_GB" "$APPLY" "$DRY_RUN" "$AUTO" "$TRIGGER" "$VERSION" "$SCHEMA_VERSION" "$contract_action" "$VALIDATE_TARGET" "$WHY_ID" <<'PY'
import json
import os
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone, timedelta
from pathlib import Path

(
    mode,
    repo_raw,
    ledger_raw,
    contract_ledger_raw,
    fuckup_log_raw,
    probe_raw,
    fixture_raw,
    buffer_raw,
    stop_raw,
    auto_threshold_raw,
    apply_raw,
    dry_raw,
    auto_raw,
    trigger,
    version,
    schema_version,
    contract_action,
    validate_target,
    why_id,
) = sys.argv[1:]

repo = Path(repo_raw)
ledger = Path(ledger_raw)
contract_ledger = Path(contract_ledger_raw)
fuckup_log = Path(fuckup_log_raw)
probe = Path(probe_raw)
fixture = Path(fixture_raw) if fixture_raw else None
buffer_gb = float(buffer_raw)
stop_gb = float(stop_raw)
auto_threshold_gb = float(auto_threshold_raw)
apply_requested = apply_raw == "1"
dry_run = dry_raw == "1"
auto = auto_raw == "1"
now = os.environ.get("STORAGE_HEADROOM_WATCHER_NOW") or datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
CATEGORIES = [
    "docker-model-runner-image-revert",
    "docker-unused-images",
    "pnpm-store-prune",
    "go-clean-cache-modcache",
    "ml-model-cache-files",
]

def parse_ts(value):
    if not isinstance(value, str) or not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None

def read_json(path):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except Exception as exc:
        return {"status": "fail", "errors": [{"code": "fixture_unreadable", "message": str(exc)}]}

def read_jsonl(path):
    rows = []
    try:
        for line in Path(path).read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            try:
                item = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(item, dict):
                rows.append(item)
    except FileNotFoundError:
        pass
    return rows

def probe_json():
    if fixture:
        payload = read_json(fixture)
        payload.setdefault("schema_version", "storage-headroom-watcher.fixture.v1")
        payload.setdefault("status", "ok")
        return payload
    if probe.exists() and os.access(probe, os.X_OK):
        proc = subprocess.run([str(probe), "--json"], text=True, capture_output=True)
        if proc.returncode == 0:
            try:
                return json.loads(proc.stdout)
            except json.JSONDecodeError:
                return {"status": "fail", "errors": [{"code": "storage_probe_invalid_json"}]}
        return {"status": "fail", "errors": [{"code": "storage_probe_failed", "stderr": proc.stderr[-500:]}]}
    usage = shutil.disk_usage(str(Path.home()))
    total = usage.total / 1024**3
    free = usage.free / 1024**3
    return {
        "status": "ok",
        "disk_total_gb": round(total, 2),
        "disk_free_gb": round(free, 2),
        "disk_free_pct": round((free / total) * 100, 2) if total else 0,
    }

def free_gb(payload):
    try:
        return float(payload.get("disk_free_gb"))
    except Exception:
        return 0.0

def is_protected(path_raw):
    try:
        path = Path(path_raw).expanduser()
    except Exception:
        return True
    text = str(path)
    home = str(Path.home())
    repo_text = str(repo)
    if text.startswith(f"{home}/.local/bin/") and ".bak" in path.name:
        return True
    if text.startswith(f"{home}/.local/share/flywheel-watchers/backups/"):
        return True
    if text == f"{repo_text}/.git" or text.startswith(f"{repo_text}/.git/"):
        return True
    if text == f"{repo_text}/.beads" or text.startswith(f"{repo_text}/.beads/"):
        return True
    if text == repo_text or text.startswith(f"{repo_text}/"):
        return True
    return False

def fixture_category_freed_mb(payload, category):
    mapping = payload.get("category_freed_mb")
    if isinstance(mapping, dict):
        try:
            return float(mapping.get(category, 0))
        except Exception:
            return 0.0
    return 0.0

def command_exists(name):
    return shutil.which(name) is not None

def run_command(command):
    proc = subprocess.run(command, text=True, capture_output=True)
    return {
        "command": command,
        "returncode": proc.returncode,
        "stdout_tail": proc.stdout[-300:],
        "stderr_tail": proc.stderr[-300:],
    }

def docker_model_runner_safe():
    if not command_exists("docker"):
        return False, "docker_missing"
    image_check = subprocess.run(["docker", "image", "inspect", "docker/model-runner:latest"], text=True, capture_output=True)
    if image_check.returncode != 0:
        return False, "docker_model_runner_image_absent"
    ps = subprocess.run(["docker", "ps", "-a", "--filter", "ancestor=docker/model-runner:latest", "-q"], text=True, capture_output=True)
    if ps.stdout.strip():
        return False, "docker_model_runner_container_exists"
    return True, "safe"

def ml_cache_candidates():
    roots = [
        Path.home() / ".cache/torch/hub/checkpoints",
        Path.home() / ".cache/whisper",
        Path.home() / ".cache/huggingface/hub",
    ]
    candidates = []
    max_candidates = int(os.environ.get("STORAGE_HEADROOM_WATCHER_MAX_ML_FILES", "20"))
    min_mb = float(os.environ.get("STORAGE_HEADROOM_WATCHER_MIN_ML_FILE_MB", "100"))
    for root in roots:
        if not root.exists():
            continue
        for path in root.rglob("*"):
            if len(candidates) >= max_candidates:
                return candidates
            try:
                if not path.is_file() or path.is_symlink() or is_protected(str(path)):
                    continue
                size_mb = path.stat().st_size / 1024**2
            except OSError:
                continue
            if size_mb >= min_mb:
                candidates.append({"path": str(path), "size_mb": round(size_mb, 2)})
    return candidates

def file_open(path):
    if not command_exists("lsof"):
        return False
    proc = subprocess.run(["lsof", "--", path], text=True, capture_output=True)
    return proc.returncode == 0 and bool(proc.stdout.strip())

def apply_live_category(category):
    before = free_gb(probe_json())
    result = {"category": category, "status": "skipped", "reason": "not_applicable", "freed_mb": 0, "protected_skips": []}
    if category == "docker-model-runner-image-revert":
        ok, reason = docker_model_runner_safe()
        if ok:
            result["command_result"] = run_command(["docker", "image", "rm", "docker/model-runner:latest"])
            result["status"] = "applied" if result["command_result"]["returncode"] == 0 else "failed"
        else:
            result["reason"] = reason
    elif category == "docker-unused-images":
        if command_exists("docker"):
            result["command_result"] = run_command(["docker", "image", "prune", "-f"])
            result["status"] = "applied" if result["command_result"]["returncode"] == 0 else "failed"
            result["reason"] = "dangling_images_only"
        else:
            result["reason"] = "docker_missing"
    elif category == "pnpm-store-prune":
        if command_exists("pnpm"):
            result["command_result"] = run_command(["pnpm", "store", "prune"])
            result["status"] = "applied" if result["command_result"]["returncode"] == 0 else "failed"
        else:
            result["reason"] = "pnpm_missing"
    elif category == "go-clean-cache-modcache":
        if command_exists("go"):
            result["command_result"] = run_command(["go", "clean", "-cache", "-modcache"])
            result["status"] = "applied" if result["command_result"]["returncode"] == 0 else "failed"
        else:
            result["reason"] = "go_missing"
    elif category == "ml-model-cache-files":
        removed = []
        protected = []
        for candidate in ml_cache_candidates():
            path = candidate["path"]
            if is_protected(path) or file_open(path):
                protected.append(path)
                continue
            try:
                os.remove(path)
                removed.append(candidate)
            except OSError as exc:
                protected.append(f"{path}:{exc.__class__.__name__}")
        result["status"] = "applied" if removed else "skipped"
        result["removed_files"] = removed
        result["protected_skips"] = protected
        result["reason"] = "regular_model_cache_files_only"
    after = free_gb(probe_json())
    result["freed_mb"] = max(0, round((after - before) * 1024, 2))
    return result, after

def run_payload():
    initial = probe_json()
    disk_before = free_gb(initial)
    effective_apply = bool(apply_requested)
    if auto and disk_before < auto_threshold_gb:
        effective_apply = True
    effective_dry_run = not effective_apply
    categories_to_prune = CATEGORIES if disk_before < buffer_gb else []
    candidate_paths = initial.get("candidate_paths") if isinstance(initial.get("candidate_paths"), list) else []
    protected_violations = [str(p) for p in candidate_paths if is_protected(str(p))]
    categories_pruned = []
    disk_after = disk_before
    for category in categories_to_prune:
        if effective_dry_run:
            continue
        if fixture:
            freed_mb = fixture_category_freed_mb(initial, category)
            disk_after = round(disk_after + (freed_mb / 1024), 3)
            categories_pruned.append({"category": category, "status": "simulated", "freed_mb": freed_mb})
        else:
            result, disk_after = apply_live_category(category)
            categories_pruned.append(result)
        if disk_after >= stop_gb:
            break
    estimated_freed_mb = 0.0
    if fixture:
        estimated_freed_mb = sum(fixture_category_freed_mb(initial, cat) for cat in categories_to_prune)
    freed_mb = max(0, round((disk_after - disk_before) * 1024, 2))
    exhausted = bool(categories_to_prune and effective_apply and disk_after < buffer_gb)
    status = "ok"
    if exhausted:
        status = "fail"
    ledger_row = None
    fuckup_row = None
    if effective_apply or trigger == "tick":
        ledger_row = {
            "schema_version": "storage-headroom-watcher.ledger.v1",
            "version": version,
            "ts": now,
            "trigger": trigger,
            "buffer_gb": buffer_gb,
            "stop_gb": stop_gb,
            "auto_apply_threshold_gb": auto_threshold_gb,
            "disk_free_gb_before": disk_before,
            "disk_free_gb_after": disk_after,
            "freed_mb": freed_mb,
            "categories_to_prune": categories_to_prune,
            "categories_pruned": categories_pruned,
            "exhausted": exhausted,
            "tick_hook_heartbeat": bool(trigger == "tick" and not effective_apply),
            "dry_run": effective_dry_run,
            "apply": effective_apply,
            "protected_paths_enforced": True,
            "protected_path_violations": [],
            "fixture": str(fixture) if fixture else None,
        }
    if exhausted:
        fuckup_row = {
            "schema_version": "flywheel-fuckup-log.v1",
            "ts": now,
            "class": "storage-headroom-prune-exhausted",
            "severity": "high",
            "what_happened": "storage-headroom-watcher exhausted safe categories before buffer",
            "bead": "flywheel-3fzcm",
            "disk_free_gb_after": disk_after,
            "buffer_gb": buffer_gb,
            "safe_categories": CATEGORIES,
        }
    return {
        "schema_version": "storage-headroom-watcher.run.v1",
        "version": version,
        "status": status,
        "success": status == "ok",
        "ts": now,
        "repo": str(repo),
        "ledger_path": str(ledger),
        "fuckup_log": str(fuckup_log),
        "probe": str(probe),
        "fixture": str(fixture) if fixture else None,
        "dry_run": effective_dry_run,
        "apply": effective_apply,
        "auto": auto,
        "trigger": trigger,
        "buffer_gb": buffer_gb,
        "stop_gb": stop_gb,
        "auto_apply_threshold_gb": auto_threshold_gb,
        "disk_free_gb_before": disk_before,
        "disk_free_gb_after": disk_after,
        "freed_mb": freed_mb,
        "estimated_freed_mb": round(estimated_freed_mb, 2),
        "categories_to_prune": categories_to_prune,
        "categories_pruned": categories_pruned,
        "exhausted": exhausted,
        "protected_paths_enforced": True,
        "protected_path_violations": [],
        "protected_candidate_paths_skipped": protected_violations,
        "ledger_row": ledger_row,
        "fuckup_row": fuckup_row,
    }

def doctor_payload():
    rows = read_jsonl(ledger)
    cutoff_base = parse_ts(now) or datetime.now(timezone.utc)
    cutoff = cutoff_base - timedelta(hours=24)
    last_fired_ts = None
    ts_values = [row.get("ts") for row in rows if parse_ts(row.get("ts"))]
    if ts_values:
        last_fired_ts = max(ts_values)
    apply_rows = []
    for row in rows:
        if not row.get("categories_pruned") and row.get("apply") is not True:
            continue
        dt = parse_ts(row.get("ts"))
        if dt and dt >= cutoff:
            apply_rows.append(row)
    apply_count = len(apply_rows)
    freed_mb = round(sum(float(row.get("freed_mb") or 0) for row in apply_rows), 2)
    last_apply_ts = None
    if apply_rows:
        last_apply_ts = max((row.get("ts") for row in apply_rows if row.get("ts")), default=None)
    status = "ok"
    errors = []
    warnings = []
    if apply_count > 10:
        status = "fail"
        errors.append({"code": "storage_headroom_watcher_apply_count_high", "apply_count_24h": apply_count, "threshold": 10})
    elif apply_count > 5:
        status = "warn"
        warnings.append({"code": "storage_headroom_watcher_apply_count_elevated", "apply_count_24h": apply_count, "threshold": 5})
    if last_fired_ts is None and status == "ok":
        status = "warn"
        warnings.append({"code": "storage_headroom_watcher_last_fired_missing", "threshold_hours": 24})
    return {
        "schema_version": "storage-headroom-watcher.doctor.v1",
        "version": version,
        "status": status,
        "ts": now,
        "repo": str(repo),
        "ledger_path": str(ledger),
        "substrate_loop_contract_ledger": str(contract_ledger),
        "storage_headroom_watcher_last_fired_ts": last_fired_ts,
        "storage_headroom_watcher_last_apply_ts": last_apply_ts,
        "storage_headroom_watcher_apply_count_24h": apply_count,
        "storage_headroom_watcher_buffer_gb": buffer_gb,
        "storage_headroom_watcher_freed_mb_24h": freed_mb,
        "storage_headroom_watcher_apply_warn_threshold_24h": 5,
        "storage_headroom_watcher_apply_error_threshold_24h": 10,
        "substrate_loop_contract_self_row_action": contract_action,
        "errors": errors,
        "warnings": warnings,
    }

def validate_payload():
    if validate_target == "protected-paths":
        samples = [
            str(Path.home() / ".local/bin/tool.bak.20260505"),
            str(Path.home() / ".local/share/flywheel-watchers/backups/x"),
            str(repo / ".git/config"),
            str(repo / ".beads/issues.jsonl"),
        ]
        return {
            "schema_version": "storage-headroom-watcher.validate.v1",
            "status": "ok" if all(is_protected(path) for path in samples) else "fail",
            "target": validate_target,
            "samples": [{"path": path, "protected": is_protected(path)} for path in samples],
        }
    invalid = 0
    total = 0
    try:
        for line in ledger.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            total += 1
            try:
                row = json.loads(line)
                if not isinstance(row, dict):
                    invalid += 1
            except json.JSONDecodeError:
                invalid += 1
    except FileNotFoundError:
        pass
    return {
        "schema_version": "storage-headroom-watcher.validate.v1",
        "status": "ok" if invalid == 0 else "fail",
        "target": "ledger",
        "ledger_path": str(ledger),
        "row_count": total,
        "invalid_rows": invalid,
    }

def repair_payload():
    planned = []
    actual = []
    if validate_target in {"ledger", "all"}:
        planned.append("ensure-ledger-directory")
        if apply_requested:
            ledger.parent.mkdir(parents=True, exist_ok=True)
            actual.append("ensured-ledger-directory")
    if validate_target in {"substrate-contract", "self-row", "all"}:
        planned.append("ensure-substrate-loop-contract-self-row")
        if contract_action in {"present", "appended"}:
            actual.append(f"substrate-loop-contract-self-row-{contract_action}")
    return {
        "schema_version": "storage-headroom-watcher.repair.v1",
        "status": "ok",
        "dry_run": not apply_requested,
        "apply": apply_requested,
        "scope": validate_target,
        "planned_actions": planned,
        "actual_actions": actual,
    }

def why_payload():
    reasons = {
        "docker-model-runner-image-revert": "Removes only docker/model-runner:latest when no container references that image.",
        "docker-unused-images": "Runs Docker image prune for dangling images only; Docker volumes are outside this watcher.",
        "pnpm-store-prune": "pnpm store prune removes unreferenced store packages and is cache-like.",
        "go-clean-cache-modcache": "go clean cache/modcache removes rebuildable Go caches.",
        "ml-model-cache-files": "Removes regular large model-cache files outside protected paths and skips open files.",
        "storage-headroom-prune-exhausted": "Safe categories ended before the buffer; durable fuckup row is the escalation path.",
    }
    return {
        "schema_version": "storage-headroom-watcher.why.v1",
        "id": why_id,
        "reason": reasons.get(why_id, "unknown id"),
        "known_ids": sorted(reasons),
    }

if mode == "run":
    print(json.dumps(run_payload(), sort_keys=True, separators=(",", ":")))
elif mode == "doctor":
    print(json.dumps(doctor_payload(), sort_keys=True, separators=(",", ":")))
elif mode == "validate":
    print(json.dumps(validate_payload(), sort_keys=True, separators=(",", ":")))
elif mode == "repair":
    print(json.dumps(repair_payload(), sort_keys=True, separators=(",", ":")))
elif mode == "audit":
    payload = doctor_payload()
    payload["schema_version"] = "storage-headroom-watcher.audit.v1"
    payload["latest_rows"] = read_jsonl(ledger)[-5:]
    print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
elif mode == "why":
    print(json.dumps(why_payload(), sort_keys=True, separators=(",", ":")))
else:
    print(json.dumps({"schema_version": "storage-headroom-watcher.error.v1", "status": "fail", "reason": "unknown-python-mode"}))
    sys.exit(2)
PY
}

run_watcher() {
  local payload ledger_row fuckup_row stripped rc=0
  payload="$(watcher_py run)"
  ledger_row="$(jq -c '.ledger_row // empty' <<<"$payload")"
  fuckup_row="$(jq -c '.fuckup_row // empty' <<<"$payload")"
  if [[ -n "$ledger_row" && "$ledger_row" != "null" ]]; then
    append_validated "$LEDGER" "$ledger_row"
    payload="$(jq -c '. + {ledger_append_status:"appended"}' <<<"$payload")"
  fi
  if [[ -n "$fuckup_row" && "$fuckup_row" != "null" ]]; then
    append_validated "$FUCKUP_LOG" "$fuckup_row"
    payload="$(jq -c '. + {fuckup_append_status:"appended"}' <<<"$payload")"
  fi
  stripped="$(jq -c 'del(.ledger_row,.fuckup_row)' <<<"$payload")"
  if jq -e '.status == "fail"' >/dev/null <<<"$stripped"; then
    rc=1
  fi
  emit "$stripped" "$(jq -r '"status=\(.status) free_before=\(.disk_free_gb_before) free_after=\(.disk_free_gb_after) apply=\(.apply) categories=\(.categories_to_prune|join(","))"' <<<"$stripped")" "$rc"
}

doctor_watcher() {
  local action payload rc=0
  action="$(ensure_contract_self_row)"
  payload="$(watcher_py doctor "$action")"
  if jq -e '.status == "fail"' >/dev/null <<<"$payload"; then
    rc=1
  fi
  emit "$payload" "$(jq -r '"status=\(.status) apply_count_24h=\(.storage_headroom_watcher_apply_count_24h) freed_mb_24h=\(.storage_headroom_watcher_freed_mb_24h)"' <<<"$payload")" "$rc"
}

validate_watcher() {
  local payload rc=0
  payload="$(watcher_py validate)"
  if jq -e '.status == "fail"' >/dev/null <<<"$payload"; then
    rc=1
  fi
  emit "$payload" "$(jq -r '"status=\(.status) target=\(.target)"' <<<"$payload")" "$rc"
}

repair_watcher() {
  local action="not_requested" payload
  VALIDATE_TARGET="$REPAIR_SCOPE"
  if [[ "$APPLY" -eq 1 && ( "$REPAIR_SCOPE" == "substrate-contract" || "$REPAIR_SCOPE" == "self-row" || "$REPAIR_SCOPE" == "all" ) ]]; then
    action="$(ensure_contract_self_row)"
  fi
  payload="$(watcher_py repair "$action")"
  emit "$payload" "$(jq -r '"status=\(.status) scope=\(.scope) planned=\(.planned_actions|length) actual=\(.actual_actions|length)"' <<<"$payload")" 0
}

audit_watcher() {
  local action="not_requested" payload
  payload="$(watcher_py audit "$action")"
  emit "$payload" "$(jq -r '"status=\(.status) latest_rows=\(.latest_rows|length)"' <<<"$payload")" 0
}

why_watcher() {
  local payload
  payload="$(watcher_py why)"
  emit "$payload" "$(jq -r '.reason' <<<"$payload")" 0
}

health_watcher() {
  if [[ "$WATCH" -eq 1 ]]; then
    while true; do
      doctor_watcher
      sleep "$WATCH_INTERVAL"
    done
  fi
  doctor_watcher
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --doctor|doctor) MODE="doctor"; shift ;;
    health|--health) MODE="health"; shift ;;
    repair|--repair) MODE="repair"; shift ;;
    validate) MODE="validate"; VALIDATE_TARGET="${2:-ledger}"; shift 2 ;;
    audit) MODE="audit"; shift ;;
    why) MODE="why"; WHY_ID="${2:-}"; shift 2 ;;
    schema) MODE="schema"; SCHEMA_TOPIC="${2:-run}"; shift 2 ;;
    --info|info) MODE="info"; shift ;;
    --examples|examples) MODE="examples"; shift ;;
    quickstart) MODE="quickstart"; shift ;;
    help|-h|--help) MODE="help"; shift ;;
    completion) MODE="completion"; COMPLETION_SHELL="${2:-}"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --dry-run) DRY_RUN=1; APPLY=0; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --auto) AUTO=1; shift ;;
    --buffer-gb) BUFFER_GB="${2:?--buffer-gb requires N}"; shift 2 ;;
    --buffer-gb=*) BUFFER_GB="${1#*=}"; shift ;;
    --stop-gb) STOP_GB="${2:?--stop-gb requires N}"; shift 2 ;;
    --stop-gb=*) STOP_GB="${1#*=}"; shift ;;
    --auto-apply-threshold-gb) AUTO_APPLY_THRESHOLD_GB="${2:?--auto-apply-threshold-gb requires N}"; shift 2 ;;
    --auto-apply-threshold-gb=*) AUTO_APPLY_THRESHOLD_GB="${1#*=}"; shift ;;
    --fixture) FIXTURE="${2:?--fixture requires PATH}"; shift 2 ;;
    --fixture=*) FIXTURE="${1#*=}"; shift ;;
    --trigger) TRIGGER="${2:?--trigger requires NAME}"; shift 2 ;;
    --trigger=*) TRIGGER="${1#*=}"; shift ;;
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
      echo "ERR: unknown argument: $1" >&2
      usage >&2
      exit 2 ;;
  esac
done

case "$MODE" in
  run) run_watcher ;;
  doctor) doctor_watcher ;;
  health) health_watcher ;;
  repair) repair_watcher ;;
  validate) validate_watcher ;;
  audit) audit_watcher ;;
  why) why_watcher ;;
  schema) schema_json ;;
  info) info_json ;;
  examples) examples_text ;;
  quickstart) quickstart_text ;;
  completion) completion ;;
  help) usage ;;
  *)
    echo "ERR: unknown mode: $MODE" >&2
    exit 2 ;;
esac
