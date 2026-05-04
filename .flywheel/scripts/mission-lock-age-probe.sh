#!/usr/bin/env bash
set -euo pipefail

VERSION="2026-05-03.1"
SCHEMA_VERSION="flywheel.mission_lock_age.v1"
FRESH_HOURS=168
STALE_ERROR_HOURS=720
MODE="snapshot"
REPO="${MISSION_LOCK_AGE_REPO:-$PWD}"

usage() {
  cat <<'USAGE'
Usage:
  mission-lock-age-probe.sh --repo=<path> [--json]
  mission-lock-age-probe.sh --repo=<path> --doctor --json
  mission-lock-age-probe.sh --repo=<path> --health --json
  mission-lock-age-probe.sh --info --json
  mission-lock-age-probe.sh --schema
  mission-lock-age-probe.sh --examples
USAGE
}

emit_examples() {
  cat <<'EXAMPLES'
Examples:
  .flywheel/scripts/mission-lock-age-probe.sh --repo /Users/josh/Developer/flywheel --json
  .flywheel/scripts/mission-lock-age-probe.sh --repo /Users/josh/Developer/mobile-eats --doctor --json
  .flywheel/scripts/mission-lock-age-probe.sh --info --json
  .flywheel/scripts/mission-lock-age-probe.sh --schema
EXAMPLES
}

emit_schema() {
  jq -nc --arg schema_version "$SCHEMA_VERSION" --arg version "$VERSION" '{
    schema_version:$schema_version,
    probe_version:$version,
    required_fields:[
      "mission_lock_age_hours",
      "mission_lock_status",
      "locked_at",
      "mission_lock_id",
      "lock_hash_matches_lock_log"
    ],
    mission_lock_status_values:["fresh","stale-warn","stale-error","unlocked","missing"],
    thresholds:{fresh_hours:168, stale_error_hours:720},
    doctor_probe:{
      name:"mission_lock_age",
      mutation_free:true,
      stale_error_behavior:"warn_and_surface"
    },
    metadata_sources:["yaml_frontmatter","yaml_code_block","kv_block"]
  }'
}

emit_info() {
  jq -nc \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg version "$VERSION" \
    --arg default_repo "$REPO" \
    --argjson fresh_hours "$FRESH_HOURS" \
    --argjson stale_error_hours "$STALE_ERROR_HOURS" \
    '{
      schema_version:$schema_version,
      mode:"info",
      success:true,
      probe_version:$version,
      default_repo:$default_repo,
      thresholds:{fresh_hours:$fresh_hours, stale_warn_hours:$fresh_hours, stale_error_hours:$stale_error_hours},
      dependencies:{python3:true,jq:true,shasum:true},
      notes:["read-only probe","understands YAML frontmatter, mission-lock YAML code blocks, and legacy key-value metadata"]
    }'
}

emit_probe() {
  local repo="$1" mode="$2"
  python3 - "$repo" "$mode" "$VERSION" "$SCHEMA_VERSION" "$FRESH_HOURS" "$STALE_ERROR_HOURS" <<'PY'
from __future__ import annotations

import datetime as dt
import hashlib
import json
import os
import re
import sys
from pathlib import Path

repo_arg, mode, version, schema_version, fresh_raw, stale_raw = sys.argv[1:]
fresh_hours = int(fresh_raw)
stale_error_hours = int(stale_raw)


def now_utc() -> dt.datetime:
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0)


def iso_now() -> str:
    return now_utc().isoformat().replace("+00:00", "Z")


def clean_scalar(value: str) -> str:
    value = value.strip()
    if not value:
        return ""
    if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
        return value[1:-1]
    return value


def parse_simple_yaml(lines: list[str]) -> dict[str, str]:
    data: dict[str, str] = {}
    key_re = re.compile(r"^([A-Za-z_][A-Za-z0-9_-]*)\s*:\s*(.*)$")
    for line in lines:
        match = key_re.match(line.rstrip("\n"))
        if not match:
            continue
        key, raw_value = match.groups()
        data[key] = clean_scalar(raw_value)
    return data


def metadata_from_text(text: str) -> tuple[dict[str, str], str]:
    lines = text.splitlines()
    if lines and lines[0].strip() == "---":
        block: list[str] = []
        for line in lines[1:]:
            if line.strip() == "---":
                return parse_simple_yaml(block), "yaml_frontmatter"
            block.append(line)

    for idx, line in enumerate(lines):
        if line.strip() == "```yaml":
            block = []
            for inner in lines[idx + 1 :]:
                if inner.strip() == "```":
                    return parse_simple_yaml(block), "yaml_code_block"
                block.append(inner)

    block = []
    started = False
    key_re = re.compile(r"^[A-Za-z_][A-Za-z0-9_-]*\s*:")
    for line in lines:
        stripped = line.strip()
        if not started and (not stripped or stripped.startswith("#")):
            continue
        if key_re.match(line):
            started = True
            block.append(line)
            continue
        if started and not stripped:
            break
        if started and (line.startswith(" ") or line.startswith("\t")):
            continue
        if started:
            break
    return parse_simple_yaml(block), "kv_block"


def legacy_body_hash(text: str) -> str:
    out: list[str] = []
    in_yaml = False
    in_kv = False
    body = False
    key_re = re.compile(r"^[A-Za-z_][A-Za-z0-9_-]*\s*:")
    for idx, line in enumerate(text.splitlines(True), start=1):
        if idx == 1 and re.match(r"^---\s*$", line):
            in_yaml = True
            continue
        if in_yaml and re.match(r"^---\s*$", line):
            in_yaml = False
            body = True
            continue
        if in_yaml:
            continue
        if not in_kv and not body and re.match(r"^#\s", line):
            continue
        if not in_kv and not body and re.match(r"^\s*$", line):
            continue
        if not in_kv and not body and key_re.match(line):
            in_kv = True
            continue
        if in_kv and key_re.match(line):
            continue
        if in_kv and re.match(r"^\s*$", line):
            body = True
            continue
        if in_kv:
            body = True
        if body:
            out.append(line)
    return hashlib.sha256("".join(out).encode()).hexdigest()


def parse_time(value: str | None) -> dt.datetime | None:
    if not value:
        return None
    raw = value.strip().strip('"').strip("'")
    candidates = [raw]
    if raw.endswith("Z"):
        candidates.append(raw[:-1] + "+00:00")
    for candidate in candidates:
        try:
            parsed = dt.datetime.fromisoformat(candidate)
            if parsed.tzinfo is None:
                parsed = parsed.replace(tzinfo=dt.timezone.utc)
            return parsed.astimezone(dt.timezone.utc)
        except ValueError:
            pass
    try:
        parsed_date = dt.date.fromisoformat(raw)
        return dt.datetime.combine(parsed_date, dt.time.min, tzinfo=dt.timezone.utc)
    except ValueError:
        return None


def load_lock_log(path: Path) -> list[dict]:
    if not path.exists():
        return []
    rows = []
    for line in path.read_text(errors="replace").splitlines():
        if not line.strip():
            continue
        try:
            rows.append(json.loads(line))
        except Exception:
            continue
    return rows


def mission_rows(rows: list[dict], mission_lock_id: str | None) -> list[dict]:
    selected = []
    for row in rows:
        file_value = str(row.get("file") or "")
        files_changed = row.get("files_changed") or []
        action = str(row.get("action") or "")
        row_id = row.get("mission_lock_id")
        touches_mission = (
            file_value in ("MISSION.md", ".flywheel/MISSION.md")
            or ".flywheel/MISSION.md" in files_changed
            or "mission" in action
            or row_id is not None
        )
        if not touches_mission:
            continue
        if mission_lock_id and row_id and row_id != mission_lock_id:
            continue
        selected.append(row)
    return selected


def base_payload(repo: Path, mission_path: Path, status: str, reason: str) -> dict:
    return {
        "schema_version": schema_version,
        "mode": mode,
        "success": status == "fresh",
        "probe_version": version,
        "checked_at": iso_now(),
        "repo": str(repo),
        "mission_path": str(mission_path),
        "mission_lock_age_hours": None,
        "mission_lock_age_days": None,
        "age_days": None,
        "threshold_hours": stale_error_hours,
        "threshold_days": stale_error_hours // 24,
        "mission_lock_status": status,
        "state": status,
        "locked_at": None,
        "mission_lock_id": None,
        "lock_hash": None,
        "computed_body_hash": None,
        "lock_hash_matches_body": None,
        "lock_hash_matches_lock_log": None,
        "mission_lock_id_matches_lock_log": None,
        "metadata_source": None,
        "lock_log_path": str(repo / ".flywheel" / "lock-log.jsonl"),
        "reason": reason,
        "warnings": [reason],
    }


repo = Path(os.path.expanduser(repo_arg)).resolve()
flywheel_dir = repo / ".flywheel"
mission_path = flywheel_dir / "MISSION.md"

if not flywheel_dir.exists():
    print(json.dumps(base_payload(repo, mission_path, "missing", "flywheel_dir_missing"), separators=(",", ":")))
    sys.exit(0)
if not mission_path.exists():
    print(json.dumps(base_payload(repo, mission_path, "unlocked", "mission_missing"), separators=(",", ":")))
    sys.exit(0)

text = mission_path.read_text(errors="replace")
metadata, metadata_source = metadata_from_text(text)
status_value = (metadata.get("status") or "").strip().lower()
locked_at_raw = metadata.get("locked_at") or None
mission_lock_id = metadata.get("mission_lock_id") or None
lock_hash = metadata.get("lock_hash") or None
computed_hash = legacy_body_hash(text)

locked = parse_time(locked_at_raw)
warnings: list[str] = []
reason = None

if status_value != "locked":
    mission_status = "unlocked"
    reason = "status_not_locked"
elif locked is None:
    mission_status = "unlocked"
    reason = "locked_at_missing_or_invalid"
else:
    age_hours = max(0.0, (now_utc() - locked).total_seconds() / 3600)
    if age_hours >= stale_error_hours:
        mission_status = "stale-error"
        reason = "locked_at_gte_30d"
    elif age_hours >= fresh_hours:
        mission_status = "stale-warn"
        reason = "locked_at_gte_7d"
    else:
        mission_status = "fresh"

rows = load_lock_log(flywheel_dir / "lock-log.jsonl")
selected_rows = mission_rows(rows, mission_lock_id)
hash_evidence_rows = [r for r in selected_rows if r.get("lock_hash")]
matching_hash_rows = [r for r in selected_rows if lock_hash and r.get("lock_hash") == lock_hash]
matching_id_rows = [r for r in rows if mission_lock_id and r.get("mission_lock_id") == mission_lock_id]

lock_hash_matches_lock_log = None if (not lock_hash or (not mission_lock_id and not hash_evidence_rows)) else bool(matching_hash_rows)
mission_lock_id_matches_lock_log = None if not mission_lock_id else bool(matching_id_rows)
lock_hash_matches_body = None if not lock_hash else lock_hash == computed_hash

if lock_hash_matches_lock_log is False:
    warnings.append("lock_hash_not_found_in_lock_log")
if mission_lock_id_matches_lock_log is False:
    warnings.append("mission_lock_id_not_found_in_lock_log")
if lock_hash_matches_body is False:
    warnings.append("lock_hash_body_mismatch")
if reason:
    warnings.append(reason)

age_hours_value = None
age_days_value = None
if locked is not None:
    age_hours_value = round(max(0.0, (now_utc() - locked).total_seconds() / 3600), 2)
    age_days_value = int(age_hours_value // 24)

payload = {
    "schema_version": schema_version,
    "mode": mode,
    "success": mission_status == "fresh",
    "probe_version": version,
    "checked_at": iso_now(),
    "repo": str(repo),
    "mission_path": str(mission_path),
    "mission_lock_age_hours": age_hours_value,
    "mission_lock_age_days": age_days_value,
    "age_days": age_days_value,
    "threshold_hours": stale_error_hours,
    "threshold_days": stale_error_hours // 24,
    "thresholds": {
        "fresh_hours": fresh_hours,
        "stale_warn_hours": fresh_hours,
        "stale_error_hours": stale_error_hours,
    },
    "mission_lock_status": mission_status,
    "state": mission_status,
    "locked_at": locked_at_raw,
    "mission_lock_id": mission_lock_id,
    "lock_hash": lock_hash,
    "computed_body_hash": computed_hash,
    "lock_hash_matches_body": lock_hash_matches_body,
    "lock_hash_matches_lock_log": lock_hash_matches_lock_log,
    "mission_lock_id_matches_lock_log": mission_lock_id_matches_lock_log,
    "metadata_source": metadata_source,
    "lock_log_path": str(flywheel_dir / "lock-log.jsonl"),
    "lock_log_match": {
        "hash_match_count": len(matching_hash_rows),
        "id_match_count": len(matching_id_rows),
        "latest_hash_match_ts": matching_hash_rows[-1].get("ts") if matching_hash_rows else None,
        "latest_id_match_ts": matching_id_rows[-1].get("ts") if matching_id_rows else None,
    },
    "reason": reason,
    "warnings": warnings,
}
print(json.dumps(payload, separators=(",", ":")))
PY
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo=*)
      REPO="${1#--repo=}"
      ;;
    --repo)
      shift
      [ "$#" -gt 0 ] || { usage >&2; exit 2; }
      REPO="$1"
      ;;
    --json)
      :
      ;;
    --doctor)
      MODE="doctor"
      ;;
    --health)
      MODE="health"
      ;;
    --info)
      MODE="info"
      ;;
    --schema)
      MODE="schema"
      ;;
    --examples)
      MODE="examples"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

case "$MODE" in
  info)
    emit_info
    ;;
  schema)
    emit_schema
    ;;
  examples)
    emit_examples
    ;;
  snapshot|doctor|health)
    emit_probe "$REPO" "$MODE"
    ;;
esac
