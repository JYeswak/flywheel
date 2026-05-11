#!/usr/bin/env bash
# canonical-cli-scoping-allow-large: canonical operator CLI with embedded parser, doctor, repair, and audit surfaces.
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial → passing per bead flywheel-1hshd.7)
set -euo pipefail

# NEW (flywheel-1hshd.7): --schema dash-flag form — parity with existing
# `schema <topic>` positional subcommand. Bash translates --schema [topic]
# into the positional form BEFORE the python heredoc parses argv, so the
# existing python `mode == "schema"` dispatch handler serves it unchanged.
# Skip when "schema" already appears as a positional (idempotent).
if [[ $# -gt 0 ]] && { [[ "$1" == "--schema" ]] || [[ "$1" == --schema=* ]]; }; then
  _topic="envelope"
  if [[ "$1" == --schema=* ]]; then
    _topic="${1#*=}"
    shift
  else
    shift
    if [[ $# -gt 0 && "${1:-}" != --* ]]; then _topic="$1"; shift; fi
  fi
  set -- schema "$_topic" "$@"
  unset _topic
fi

exec python3 - "$0" "$@" <<'PY'
import argparse
import json
import os
import re
import shlex
import subprocess
import sys
import time
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

VERSION = "callback-envelope-schema-validator.v1.0.0"
SCHEMA_VERSION = "callback-envelope-schema.v1"
DOCTOR_SCHEMA_VERSION = "callback-envelope-schema.doctor.v1"
CONTRACT_SCHEMA_VERSION = "substrate-loop-contract.v1"

SCRIPT_PATH = Path(sys.argv[1]).resolve()
SCRIPT_DIR = SCRIPT_PATH.parent
REPO_ROOT_DEFAULT = SCRIPT_DIR.parent.parent if SCRIPT_DIR.name == "scripts" else Path.cwd()

ENV = os.environ
REPO_ROOT = Path(ENV.get("CALLBACK_ENVELOPE_SCHEMA_REPO", str(REPO_ROOT_DEFAULT))).expanduser()
LEDGER = Path(ENV.get("CALLBACK_ENVELOPE_SCHEMA_LEDGER", str(Path.home() / ".local/state/flywheel/callback-envelope-schema.jsonl"))).expanduser()
FUCKUP_LOG = Path(ENV.get("CALLBACK_ENVELOPE_SCHEMA_FUCKUP_LOG", str(Path.home() / ".local/state/flywheel/fuckup-log.jsonl"))).expanduser()
CONTRACT_LEDGER = Path(ENV.get("CALLBACK_ENVELOPE_SCHEMA_CONTRACT_LEDGER", str(Path.home() / ".local/state/flywheel/substrate-loop-contract.jsonl"))).expanduser()
DISPATCH_LOG = Path(ENV.get("CALLBACK_ENVELOPE_SCHEMA_DISPATCH_LOG", str(REPO_ROOT / ".flywheel/dispatch-log.jsonl"))).expanduser()
JSONL_APPEND_LIB = Path(ENV.get("FLYWHEEL_JSONL_APPEND_LIB", str(Path.home() / ".local/share/flywheel-watchers/lib/jsonl-append.sh"))).expanduser()
NOW_OVERRIDE = ENV.get("CALLBACK_ENVELOPE_SCHEMA_NOW", "")

REQUIRED_FIELDS = [
    "quality_bar_passed",
    "composite_score",
    "jeff_score",
    "donella_score",
    "joshua_score",
    "rust/python_clean",
    "cli_canonical",
    "readme_quality",
]

CLEAN_VALUES = {"yes", "no", "n/a"}
QBP_VALUES = {"yes", "no"}


def now_dt() -> datetime:
    if NOW_OVERRIDE:
        value = NOW_OVERRIDE
        if value.endswith("Z"):
            value = value[:-1] + "+00:00"
        try:
            return datetime.fromisoformat(value).astimezone(timezone.utc)
        except ValueError:
            pass
    return datetime.now(timezone.utc)


def now_iso() -> str:
    return now_dt().strftime("%Y-%m-%dT%H:%M:%SZ")


def emit(payload, json_out: bool, text: str, rc: int = 0) -> int:
    if json_out:
        print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
    else:
        print(text)
    return rc


def usage() -> str:
    return """usage:
  callback-envelope-schema-validator.sh --doctor [--json]
  callback-envelope-schema-validator.sh doctor [--json]
  callback-envelope-schema-validator.sh health [--watch] [--interval N] [--json]
  callback-envelope-schema-validator.sh repair --scope ledger|substrate-contract|all [--dry-run|--apply] [--json]
  callback-envelope-schema-validator.sh validate envelope (--callback-envelope TEXT|--callback-envelope-file PATH|--stdin) [--apply] [--json]
  callback-envelope-schema-validator.sh audit [--json]
  callback-envelope-schema-validator.sh why FIELD_OR_VIOLATION [--json]
  callback-envelope-schema-validator.sh schema envelope|doctor|ledger|contract [--json]
  callback-envelope-schema-validator.sh --info|--examples|quickstart|help TOPIC|completion bash|zsh
"""


def examples() -> str:
    return """callback-envelope-schema-validator.sh validate envelope --callback-envelope 'quality_bar_passed=yes composite_score=9.6 jeff_score=9.5 donella_score=9.6 joshua_score=9.7 rust/python_clean=n/a cli_canonical=yes readme_quality=n/a' --json
callback-envelope-schema-validator.sh validate envelope --callback-envelope-file /tmp/done-callback.txt --apply --json
callback-envelope-schema-validator.sh --doctor --json | jq .
callback-envelope-schema-validator.sh repair --scope substrate-contract --apply --json
"""


def quickstart() -> str:
    return """1. Validate a callback envelope in dry-run mode before close.
2. Use --apply only from the close handler or explicit verification path.
3. Inspect 24h compliance with --doctor --json.
4. Add the substrate-loop-contract self-row with repair --scope substrate-contract --apply.
"""


def json_bool(value: bool) -> bool:
    return bool(value)


def scalar_to_text(value) -> str:
    if value is None:
        return ""
    if isinstance(value, bool):
        return "yes" if value else "no"
    return str(value)


def tokenize_envelope(text: str) -> list[str]:
    tokens: list[str] = []
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "=" in line and re.match(r"^[A-Za-z0-9_./-]+=", line):
            key = line.split("=", 1)[0]
            if " " not in key and "\t" not in key and key in ALIAS_MAP:
                tokens.append(line)
                continue
        try:
            parts = shlex.split(line)
        except ValueError:
            parts = line.split()
        tokens.extend(parts)
    return tokens


ALIAS_MAP = {
    "quality_bar_passed": "quality_bar_passed",
    "qbp": "quality_bar_passed",
    "composite_score": "composite_score",
    "composite": "composite_score",
    "self_grade": "self_grade",
    "jeff_score": "jeff_score",
    "donella_score": "donella_score",
    "joshua_score": "joshua_score",
    "rust/python_clean": "rust_python_clean",
    "rust_python_clean": "rust_python_clean",
    "rust_clean": "rust_clean",
    "rust": "rust_clean",
    "python_clean": "python_clean",
    "python": "python_clean",
    "cli_canonical": "cli_canonical",
    "cli": "cli_canonical",
    "readme_quality": "readme_quality",
    "readme": "readme_quality",
}


def expand_token(token: str) -> list[str]:
    if "=" not in token:
        return []
    if "/" in token:
        compact = []
        token_for_scan = token.replace("=n/a", "=__NA__")
        pattern = re.compile(r"(?:(?<=/)|^)([A-Za-z0-9_.-]+(?:/[A-Za-z0-9_.-]+)?)=([^/]*(?:/(?![A-Za-z0-9_.-]+(?:/[A-Za-z0-9_.-]+)?=)[^/]*)*)")
        for match in pattern.finditer(token_for_scan):
            key = match.group(1)
            if key in ALIAS_MAP:
                compact.append(f"{key}={match.group(2).replace('__NA__', 'n/a')}")
        if compact:
            return compact
    return [token]


def parse_envelope_text(text: str) -> dict:
    raw: dict[str, str] = {}
    for token in tokenize_envelope(text):
        for expanded in expand_token(token):
            if "=" not in expanded:
                continue
            key, value = expanded.split("=", 1)
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            normalized = ALIAS_MAP.get(key)
            if not normalized:
                continue
            if normalized == "self_grade":
                if "composite_score" not in raw:
                    raw[normalized] = value
                continue
            raw[normalized] = value
    if "composite_score" not in raw and "self_grade" in raw:
        parsed = parse_number(raw["self_grade"])
        if parsed is not None:
            raw["composite_score"] = str(parsed)
    return raw


def parse_number(value: str):
    if value is None:
        return None
    match = re.search(r"-?\d+(?:\.\d+)?", str(value))
    if not match:
        return None
    try:
        return float(match.group(0))
    except ValueError:
        return None


def clean_value(value: str) -> str:
    return str(value).strip().lower()


def validate_fields(fields: dict, source: str = "") -> dict:
    missing: list[str] = []
    violations: list[str] = []

    def has(name: str) -> bool:
        return str(fields.get(name, "")).strip() != ""

    if not has("quality_bar_passed"):
        missing.append("quality_bar_passed")
    if not has("composite_score"):
        missing.append("composite_score")
    for judge in ("jeff_score", "donella_score", "joshua_score"):
        if not has(judge):
            missing.append(judge)

    combined_clean = has("rust_python_clean")
    split_clean = has("rust_clean") and has("python_clean")
    if not combined_clean and not split_clean:
        missing.append("rust/python_clean")
    if not has("cli_canonical"):
        missing.append("cli_canonical")
    if not has("readme_quality"):
        missing.append("readme_quality")

    qbp = clean_value(fields.get("quality_bar_passed", ""))
    if has("quality_bar_passed") and qbp not in QBP_VALUES:
        violations.append("quality_bar_passed_invalid")
    if has("quality_bar_passed") and qbp != "yes":
        violations.append("quality_bar_not_passed")

    composite = parse_number(fields.get("composite_score", ""))
    if has("composite_score") and composite is None:
        violations.append("composite_score_invalid")
    elif composite is not None and composite < 9.5:
        violations.append("composite_below_quality_bar")
        if qbp == "yes":
            violations.append("quality_bar_passed_composite_mismatch")

    judge_scores = {}
    for judge in ("jeff_score", "donella_score", "joshua_score"):
        score = parse_number(fields.get(judge, ""))
        if has(judge) and score is None:
            violations.append(f"{judge}_invalid")
        elif score is not None:
            judge_scores[judge] = score
            if qbp == "yes" and score < 9:
                violations.append(f"{judge}_below_9")

    clean_fields = []
    if combined_clean:
        clean_fields.append(("rust/python_clean", fields.get("rust_python_clean", "")))
    else:
        if has("rust_clean"):
            clean_fields.append(("rust_clean", fields.get("rust_clean", "")))
        if has("python_clean"):
            clean_fields.append(("python_clean", fields.get("python_clean", "")))
    if has("cli_canonical"):
        clean_fields.append(("cli_canonical", fields.get("cli_canonical", "")))
    if has("readme_quality"):
        clean_fields.append(("readme_quality", fields.get("readme_quality", "")))
    for name, value in clean_fields:
        if clean_value(value) not in CLEAN_VALUES:
            violations.append(f"{name}_invalid")

    valid = not missing and not violations
    normalized_fields = {
        "quality_bar_passed": qbp if has("quality_bar_passed") else None,
        "composite_score": composite,
        "jeff_score": judge_scores.get("jeff_score"),
        "donella_score": judge_scores.get("donella_score"),
        "joshua_score": judge_scores.get("joshua_score"),
        "rust/python_clean": clean_value(fields.get("rust_python_clean", "")) if combined_clean else None,
        "rust_clean": clean_value(fields.get("rust_clean", "")) if has("rust_clean") else None,
        "python_clean": clean_value(fields.get("python_clean", "")) if has("python_clean") else None,
        "cli_canonical": clean_value(fields.get("cli_canonical", "")) if has("cli_canonical") else None,
        "readme_quality": clean_value(fields.get("readme_quality", "")) if has("readme_quality") else None,
    }
    return {
        "schema_version": SCHEMA_VERSION,
        "status": "pass" if valid else "fail",
        "valid": valid,
        "source": source,
        "fields": normalized_fields,
        "missing_fields": missing,
        "violations": violations,
    }


def load_envelope(args) -> tuple[str, str]:
    if args.callback_envelope is not None:
        return args.callback_envelope, "arg"
    if args.callback_envelope_file:
        path = Path(args.callback_envelope_file).expanduser()
        return path.read_text(encoding="utf-8", errors="replace"), str(path)
    if args.stdin or not sys.stdin.isatty():
        return sys.stdin.read(), "stdin"
    raise ValueError("missing callback envelope input")


def append_validated(path: Path, row: dict) -> None:
    row_text = json.dumps(row, sort_keys=True, separators=(",", ":"))
    if not JSONL_APPEND_LIB.is_file():
        raise RuntimeError(f"JSONL append primitive missing: {JSONL_APPEND_LIB}")
    cmd = 'source "$1"; fw_jsonl_append_validated "$2" "$3"'
    completed = subprocess.run(
        ["bash", "-c", cmd, "bash", str(JSONL_APPEND_LIB), str(path), row_text],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if completed.returncode != 0:
        raise RuntimeError(completed.stderr.strip() or f"fw_jsonl_append_validated failed rc={completed.returncode}")


def validation_row(result: dict, args, input_source: str) -> dict:
    row = {
        "schema_version": SCHEMA_VERSION,
        "ts": now_iso(),
        "event": "callback_envelope_schema_validation",
        "status": result["status"],
        "valid": result["valid"],
        "missing_fields": result["missing_fields"],
        "violations": result["violations"],
        "fields": result["fields"],
        "callback_envelope_source": input_source,
        "dry_run": not args.apply,
        "apply": args.apply,
    }
    task_id = extract_task_id(args.callback_envelope or "")
    if task_id:
        row["task_id"] = task_id
    return row


def fuckup_row(result: dict, input_source: str) -> dict:
    return {
        "schema_version": SCHEMA_VERSION,
        "ts": now_iso(),
        "trauma_class": "callback-envelope-schema-failed",
        "class": "callback-envelope-schema-failed",
        "severity": "medium",
        "what_happened": "callback envelope failed L111 schema validation before close",
        "callback_envelope_source": input_source,
        "missing_fields": result["missing_fields"],
        "violations": result["violations"],
        "should_become": "bead",
    }


def extract_task_id(text: str) -> str:
    match = re.search(r"\bDONE\s+([A-Za-z0-9_.:/-]+)", text or "")
    return match.group(1) if match else ""


def run_validate(args) -> int:
    try:
        text, source = load_envelope(args)
    except Exception as exc:
        payload = {"schema_version": SCHEMA_VERSION, "status": "fail", "valid": False, "missing_fields": REQUIRED_FIELDS, "violations": ["input_missing"], "error": str(exc), "dry_run": not args.apply, "apply": args.apply, "ledger_written": False}
        return emit(payload, args.json, f"FAIL input_missing error={exc}", 2)

    fields = parse_envelope_text(text)
    result = validate_fields(fields, source)
    row = validation_row(result, args, source)
    ledger_written = False
    fuckup_written = False
    append_error = ""

    if args.apply:
        try:
            append_validated(LEDGER, row)
            ledger_written = True
            if not result["valid"]:
                append_validated(FUCKUP_LOG, fuckup_row(result, source))
                fuckup_written = True
        except Exception as exc:
            append_error = str(exc)

    payload = {
        **result,
        "version": VERSION,
        "required_fields": REQUIRED_FIELDS,
        "callback_envelope_source": source,
        "ledger_path": str(LEDGER),
        "fuckup_log_path": str(FUCKUP_LOG),
        "dry_run": not args.apply,
        "apply": args.apply,
        "ledger_written": ledger_written,
        "fuckup_written": fuckup_written,
    }
    if append_error:
        payload["append_error"] = append_error
        return emit(payload, args.json, f"FAIL append_error={append_error}", 3)
    rc = 0 if result["valid"] else 1
    text_out = "PASS callback_envelope_schema" if result["valid"] else f"FAIL missing={','.join(result['missing_fields'])} violations={','.join(result['violations'])}"
    return emit(payload, args.json, text_out, rc)


def read_jsonl(path: Path) -> list[dict]:
    rows = []
    if not path.is_file():
        return rows
    with path.open("r", encoding="utf-8", errors="replace") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(obj, dict):
                rows.append(obj)
    return rows


def parse_ts(value) -> float:
    if not value:
        return 0.0
    raw = str(value)
    if raw.endswith("Z"):
        raw = raw[:-1] + "+00:00"
    try:
        return datetime.fromisoformat(raw).timestamp()
    except ValueError:
        return 0.0


def row_to_envelope_text(row: dict) -> str:
    parts = []
    for key, value in row.items():
        if isinstance(value, (dict, list)):
            continue
        text = scalar_to_text(value)
        if text:
            parts.append(f"{key}={shlex.quote(text)}")
    return " ".join(parts)


def is_callback_candidate(row: dict) -> bool:
    if row.get("callback_received_at") not in (None, "", "null"):
        return True
    if str(row.get("event", "")).startswith("callback_envelope"):
        return True
    if "DONE " in json.dumps(row, sort_keys=True):
        return True
    return False


def doctor_payload() -> dict:
    now_epoch = now_dt().timestamp()
    since = now_epoch - 86400
    candidates: list[dict] = []

    for row in read_jsonl(DISPATCH_LOG):
        ts = parse_ts(row.get("callback_received_at") or row.get("ts"))
        if ts and ts < since:
            continue
        if is_callback_candidate(row):
            result = validate_fields(parse_envelope_text(row_to_envelope_text(row)), str(DISPATCH_LOG))
            candidates.append({"source": "dispatch-log", "task_id": row.get("task_id", ""), "result": result})

    for row in read_jsonl(LEDGER):
        ts = parse_ts(row.get("ts"))
        if ts and ts < since:
            continue
        if str(row.get("schema_version", "")).startswith(SCHEMA_VERSION):
            result = {
                "schema_version": SCHEMA_VERSION,
                "status": row.get("status", "fail"),
                "valid": bool(row.get("valid", row.get("status") == "pass")),
                "missing_fields": row.get("missing_fields", []),
                "violations": row.get("violations", []),
                "fields": row.get("fields", {}),
                "source": str(LEDGER),
            }
            candidates.append({"source": "schema-ledger", "task_id": row.get("task_id", ""), "result": result})

    total = len(candidates)
    passed = sum(1 for item in candidates if item["result"].get("valid"))
    violations = total - passed
    compliance = 100 if total == 0 else int((passed * 100) / total)
    missing_counter = Counter()
    violation_counter = Counter()
    for item in candidates:
        for field in item["result"].get("missing_fields", []) or []:
            missing_counter[field] += 1
        for violation in item["result"].get("violations", []) or []:
            violation_counter[violation] += 1
    top_missing = missing_counter.most_common(1)[0][0] if missing_counter else None
    status = "pass"
    if compliance < 70 or violations > 5:
        status = "error"
    elif compliance < 90:
        status = "warn"
    return {
        "schema_version": DOCTOR_SCHEMA_VERSION,
        "validator_schema_version": SCHEMA_VERSION,
        "status": status,
        "repo": str(REPO_ROOT),
        "ledger_path": str(LEDGER),
        "dispatch_log_path": str(DISPATCH_LOG),
        "callback_envelope_schema_compliance_24h_pct": compliance,
        "callback_envelope_schema_violations_24h": violations,
        "callback_envelope_schema_top_missing_field": top_missing,
        "callbacks_scanned_24h": total,
        "callbacks_passing_schema_24h": passed,
        "top_violations": [{"violation": name, "count": count} for name, count in violation_counter.most_common(10)],
        "top_missing_fields": [{"field": name, "count": count} for name, count in missing_counter.most_common(10)],
    }


def run_doctor(args) -> int:
    payload = doctor_payload()
    rc = 1 if payload["status"] == "error" else 0
    return emit(payload, args.json, f"status={payload['status']} callback_envelope_schema_compliance_24h_pct={payload['callback_envelope_schema_compliance_24h_pct']} callback_envelope_schema_violations_24h={payload['callback_envelope_schema_violations_24h']}", rc)


def run_health(args) -> int:
    rc = 0
    while True:
        payload = doctor_payload()
        health = "green" if payload["status"] == "pass" else ("degraded" if payload["status"] == "warn" else "critical")
        payload = {**payload, "health": health}
        rc = 0 if health == "green" else (1 if health == "degraded" else 3)
        emit(payload, args.json, f"health={health} compliance={payload['callback_envelope_schema_compliance_24h_pct']}", rc)
        if not args.watch:
            break
        time.sleep(args.interval)
    return rc


def substrate_contract_row() -> dict:
    return {
        "primitive_name": "callback-envelope-schema-validator",
        "declares_loop": "yes",
        "self_repair_action": "callback-envelope-schema-validator.sh repair --scope all --apply",
        "measurement_field": "callback_envelope_schema_compliance_24h_pct",
        "escalation_path": "doctor scope callback-envelope-schema error -> fuckup-log:class=callback-envelope-schema-failed",
        "schema_version": CONTRACT_SCHEMA_VERSION,
        "bootstrap_seed_v1": "1t6x9 wires L111 callback quality envelope validation into close path",
        "ts": now_iso(),
    }


def run_repair(args) -> int:
    scope = args.scope
    planned = []
    actual = []
    if scope in ("ledger", "all"):
        planned.append({"action": "ensure_directory", "path": str(LEDGER.parent)})
    if scope in ("substrate-contract", "all"):
        planned.append({"action": "append_substrate_loop_contract_self_row", "path": str(CONTRACT_LEDGER), "primitive_name": "callback-envelope-schema-validator"})
    if args.apply:
        if scope in ("ledger", "all"):
            LEDGER.parent.mkdir(parents=True, exist_ok=True)
            actual.append({"action": "ensured_directory", "path": str(LEDGER.parent)})
        if scope in ("substrate-contract", "all"):
            append_validated(CONTRACT_LEDGER, substrate_contract_row())
            actual.append({"action": "appended_substrate_loop_contract_self_row", "path": str(CONTRACT_LEDGER)})
    payload = {
        "schema_version": SCHEMA_VERSION,
        "mode": "repair",
        "status": "pass",
        "scope": scope,
        "dry_run": not args.apply,
        "apply": args.apply,
        "planned_actions": planned,
        "actual_actions": actual,
    }
    return emit(payload, args.json, f"repair status=pass scope={scope} apply={'yes' if args.apply else 'no'}", 0)


def run_audit(args) -> int:
    rows = read_jsonl(LEDGER)[-20:]
    payload = {"schema_version": SCHEMA_VERSION, "mode": "audit", "ledger_path": str(LEDGER), "rows_seen_count": len(read_jsonl(LEDGER)), "recent_rows": rows}
    return emit(payload, args.json, f"audit rows_seen_count={payload['rows_seen_count']}", 0)


WHY = {
    "quality_bar_passed": "must be yes|no and must be yes for close acceptance",
    "composite_score": "must parse as a number and be >= 9.5",
    "jeff_score": "must parse as a number and be >= 9 when quality_bar_passed=yes",
    "donella_score": "must parse as a number and be >= 9 when quality_bar_passed=yes",
    "joshua_score": "must parse as a number and be >= 9 when quality_bar_passed=yes",
    "rust/python_clean": "must be present as rust/python_clean=yes|no|n/a or split rust_clean/python_clean values",
    "cli_canonical": "must be yes|no|n/a",
    "readme_quality": "must be yes|no|n/a",
    "composite_below_quality_bar": "composite_score is below the L111 >=9.5 threshold",
    "quality_bar_passed_composite_mismatch": "quality_bar_passed=yes contradicted composite_score below threshold",
    "callback-envelope-schema-failed": "close-handler should block close and emit a fuckup row",
}


def run_why(args) -> int:
    explanation = WHY.get(args.why_id, "unknown field or violation")
    payload = {"schema_version": SCHEMA_VERSION, "mode": "why", "id": args.why_id, "explanation": explanation}
    return emit(payload, args.json, f"{args.why_id}: {explanation}", 0)


def schema_payload(topic: str) -> dict:
    if topic == "envelope":
        return {"schema_version": SCHEMA_VERSION, "required_fields": REQUIRED_FIELDS, "thresholds": {"composite_score_min": 9.5, "judge_score_min_when_quality_bar_passed_yes": 9}, "allowed_values": {"quality_bar_passed": sorted(QBP_VALUES), "clean_fields": sorted(CLEAN_VALUES)}}
    if topic == "doctor":
        return {"schema_version": DOCTOR_SCHEMA_VERSION, "required_fields": ["callback_envelope_schema_compliance_24h_pct", "callback_envelope_schema_violations_24h", "callback_envelope_schema_top_missing_field"], "thresholds": {"warn": "compliance < 90", "error": "compliance < 70 OR violations > 5"}}
    if topic == "ledger":
        return {"schema_version": SCHEMA_VERSION, "required_fields": ["schema_version", "ts", "event", "status", "valid", "missing_fields", "violations", "fields", "dry_run", "apply"]}
    if topic == "contract":
        return {"schema_version": CONTRACT_SCHEMA_VERSION, "required_fields": ["primitive_name", "declares_loop", "self_repair_action", "measurement_field", "escalation_path", "schema_version", "bootstrap_seed_v1"]}
    raise ValueError(f"unknown schema topic: {topic}")


def run_schema(args) -> int:
    try:
        payload = schema_payload(args.schema_topic)
    except ValueError as exc:
        print(f"ERR: {exc}", file=sys.stderr)
        return 2
    return emit(payload, args.json, f"schema_version={payload['schema_version']}", 0)


def info_payload() -> dict:
    return {
        "name": "callback-envelope-schema-validator.sh",
        "version": VERSION,
        "schema_version": SCHEMA_VERSION,
        "repo": str(REPO_ROOT),
        "ledger": str(LEDGER),
        "fuckup_log": str(FUCKUP_LOG),
        "contract_ledger": str(CONTRACT_LEDGER),
        "dispatch_log": str(DISPATCH_LOG),
        "jsonl_append_lib": str(JSONL_APPEND_LIB),
        "exit_codes": {"0": "valid/pass or healthy", "1": "schema validation failed or doctor error", "2": "usage/input error", "3": "validated append failed"},
    }


def completion(shell: str) -> str:
    if shell == "bash":
        return """_callback_envelope_schema_validator_completion() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "--doctor doctor health repair validate audit why schema --callback-envelope --callback-envelope-file --stdin --scope --dry-run --apply --json --info --examples quickstart help completion" -- "$cur") )
}
complete -F _callback_envelope_schema_validator_completion callback-envelope-schema-validator.sh
"""
    if shell == "zsh":
        return "compadd -- --doctor doctor health repair validate audit why schema --callback-envelope --callback-envelope-file --stdin --scope --dry-run --apply --json --info --examples quickstart help completion\n"
    raise ValueError("completion shell must be bash or zsh")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("command", nargs="?", default="")
    parser.add_argument("subcommand", nargs="?", default="")
    parser.add_argument("extra", nargs="*")
    parser.add_argument("--doctor", action="store_true")
    parser.add_argument("--health", action="store_true")
    parser.add_argument("--repair", action="store_true")
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--examples", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--watch", action="store_true")
    parser.add_argument("-i", "--interval", type=float, default=5)
    parser.add_argument("--scope", default="ledger", choices=["ledger", "substrate-contract", "all"])
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--callback-envelope", default=None)
    parser.add_argument("--callback-envelope-file", default="")
    parser.add_argument("--stdin", action="store_true")
    parser.add_argument("--repo", default="")
    parser.add_argument("--fix", action="store_true")
    parser.add_argument("--explain", action="store_true")
    parser.add_argument("--no-color", action="store_true")
    parser.add_argument("--no-emoji", action="store_true")
    parser.add_argument("--idempotency-key", default="")
    parser.add_argument("--width", default="")
    return parser


def main(argv: list[str]) -> int:
    if not argv:
        argv = ["doctor"]
    if any(arg in ("--help", "-h") for arg in argv):
        print(usage(), end="")
        return 0
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.repo:
        global REPO_ROOT, DISPATCH_LOG
        REPO_ROOT = Path(args.repo).expanduser()
        if "CALLBACK_ENVELOPE_SCHEMA_DISPATCH_LOG" not in ENV:
            DISPATCH_LOG = REPO_ROOT / ".flywheel/dispatch-log.jsonl"

    mode = args.command
    if args.doctor:
        mode = "doctor"
    elif args.health:
        mode = "health"
    elif args.repair:
        mode = "repair"
    elif args.info:
        mode = "info"
    elif args.examples:
        mode = "examples"

    if mode in ("doctor", ""):
        return run_doctor(args)
    if mode == "health":
        return run_health(args)
    if mode == "repair":
        return run_repair(args)
    if mode == "validate" and args.subcommand == "envelope":
        return run_validate(args)
    if mode == "audit":
        return run_audit(args)
    if mode == "why":
        args.why_id = args.subcommand
        if not args.why_id:
            print("ERR: why requires FIELD_OR_VIOLATION", file=sys.stderr)
            return 2
        return run_why(args)
    if mode == "schema":
        args.schema_topic = args.subcommand or "envelope"
        return run_schema(args)
    if mode == "info":
        return emit(info_payload(), args.json, f"callback-envelope-schema-validator {VERSION}", 0)
    if mode == "examples":
        if args.json:
            return emit({"mode": "examples", "examples": [line for line in examples().splitlines() if line]}, True, "", 0)
        print(examples(), end="")
        return 0
    if mode == "quickstart":
        if args.json:
            return emit({"mode": "quickstart", "steps": [line for line in quickstart().splitlines() if line]}, True, "", 0)
        print(quickstart(), end="")
        return 0
    if mode == "help":
        print(usage(), end="")
        return 0
    if mode == "completion":
        shell = args.subcommand
        try:
            print(completion(shell), end="")
            return 0
        except ValueError as exc:
            print(f"ERR: {exc}", file=sys.stderr)
            return 2
    print(f"ERR: unknown command: {mode}", file=sys.stderr)
    print(usage(), file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[2:]))
PY
