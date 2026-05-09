#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MATRIX_DEFAULT="$ROOT/.flywheel/PLANS/ntm-surface-wire-in-USE-ISSUE-WRAP-2026-05-07/07-VALIDATION-MATRIX.yaml"
LEDGER_DEFAULT="$HOME/.local/state/flywheel/ntm-surface-validation.jsonl"

python3 - "$ROOT" "$MATRIX_DEFAULT" "$LEDGER_DEFAULT" "$@" <<'PY'
import argparse
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

try:
    import yaml
except Exception as exc:
    print(json.dumps({"status": "fail", "reason": "pyyaml_missing", "error": str(exc)}))
    raise SystemExit(2)

ROOT = Path(sys.argv[1])
MATRIX_DEFAULT = Path(sys.argv[2])
LEDGER_DEFAULT = Path(sys.argv[3])
MATRIX_SCHEMA_VERSION = "ntm-surface-validation-matrix.schema.v1"
KNOWN_NTM_SURFACES = {
    "activity", "add", "adopt", "agents", "analytics", "approve", "assign", "attach",
    "audit", "beads", "bind", "bugs", "cass", "changes", "checkpoint", "cleanup",
    "completion", "config", "conflicts", "context", "controller", "coordinator",
    "copy", "create", "dashboard", "deps", "diff", "doctor", "ensemble", "errors",
    "extract", "get-all-session-text", "git", "grep", "guards", "handoff", "health",
    "help", "history", "hooks", "init", "interrupt", "kernel", "kill", "level",
    "list", "lock", "locks", "logs", "mail", "memory", "message", "metrics",
    "models", "modes", "openapi", "overlay", "palette", "personas", "pipeline",
    "plugins", "policy", "preflight", "profile", "quick", "quota", "rebalance",
    "recipes", "redact", "replay", "repo", "respawn", "resume", "review-queue",
    "rollback", "rotate", "safety", "save", "scale", "scan", "scrub", "search",
    "send", "serve", "session-templates", "sessions", "setup", "shell", "spawn",
    "status", "summary", "support-bundle", "swarm", "template", "timeline",
    "tutorial", "unlock", "upgrade", "version", "view", "wait", "watch", "work",
    "workflows", "worktree", "zoom",
}


def utc_now():
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def emit(obj, json_out=True):
    if json_out:
        print(json.dumps(obj, sort_keys=True, separators=(",", ":")))
    else:
        print(f"{obj.get('status', 'unknown')} surfaces={obj.get('surfaces_total', 0)} coverage={obj.get('ntm_surface_coverage_avg')}")


def load_matrix(path):
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or not isinstance(data.get("surfaces"), list):
        raise ValueError("matrix_missing_surfaces")
    return data


def matrix_schema():
    ref = {"$ref": "#/$defs/evidence_ref"}
    return {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "$id": "https://zeststream.ai/schemas/flywheel/ntm-surface-validation-matrix.v1.schema.json",
        "title": "NTM surface validation matrix v1",
        "type": "object",
        "additionalProperties": False,
        "required": ["schema_version", "surfaces"],
        "properties": {
            "schema_version": {"oneOf": [{"const": 1}, {"const": "ntm-surface-validation-matrix.v1"}]},
            "generated_at": {"type": "string", "format": "date-time"},
            "ntm_version": {"type": "string"},
            "generation_notes": {"type": "array", "items": {"type": "string"}},
            "socraticode": {
                "type": "object",
                "additionalProperties": False,
                "properties": {
                    "project_path": {"type": "string"},
                    "queries_required": {"type": "integer", "minimum": 0},
                    "queries_completed": {"type": "integer", "minimum": 0},
                    "indexed_chunks_observed": {"type": "integer", "minimum": 0},
                },
            },
            "doctor_snapshot": {
                "type": "object",
                "additionalProperties": True,
                "properties": {
                    "path": {"type": "string"},
                    "status": {"type": "string"},
                    "observed_probe_count": {"type": "integer", "minimum": 0},
                    "observed_probes": {"type": "array", "items": {"type": "string"}},
                },
            },
            "coverage_summary": {
                "type": "object",
                "additionalProperties": False,
                "properties": {
                    "surfaces_total": {"type": "integer", "minimum": 0},
                    "coverage_avg": {"type": "number", "minimum": 0, "maximum": 10},
                    "below_7_count": {"type": "integer", "minimum": 0},
                    "claimed_use_no_doctor_probe_count": {"type": "integer", "minimum": 0},
                },
            },
            "surfaces": {
                "type": "array",
                "minItems": 1,
                "items": {"$ref": "#/$defs/surface"},
            },
        },
        "$defs": {
            "evidence_ref": {
                "type": "object",
                "additionalProperties": False,
                "required": ["path"],
                "properties": {
                    "path": {"type": "string", "minLength": 1},
                    "line": {"type": "integer", "minimum": 1},
                    "what_it_proves": {"type": "string"},
                    "what_it_asserts": {"type": "string"},
                },
            },
            "surface": {
                "type": "object",
                "additionalProperties": False,
                "required": ["name", "decision", "coverage_score"],
                "properties": {
                    "name": {"type": "string", "enum": sorted(KNOWN_NTM_SURFACES)},
                    "aliases": {"type": "array", "items": {"type": "string", "minLength": 1}},
                    "decision": {"enum": ["USE", "WRAP", "ISSUE", "EXCLUDED"]},
                    "inventory_row": {"type": "integer", "minimum": 1},
                    "inventory_decision": {"type": "string"},
                    "description": {"type": "string"},
                    "wrapper_script": {"type": "string", "minLength": 1},
                    "why_keep_evidence": {"type": "string"},
                    "deletion_tripwire": {"type": "string", "minLength": 1},
                    "receipt": {"type": "string", "minLength": 1},
                    "exclusion_receipt": {"type": "string", "minLength": 1},
                    "why_excluded": {"type": "string", "minLength": 1},
                    "issue_url": {"type": "string", "pattern": "^https://github[.]com/Dicklesworthstone/ntm/issues/[0-9]+$"},
                    "jeff_issue": {"type": ["integer", "string"]},
                    "issue": {"type": ["integer", "string"]},
                    "issue_number": {"type": ["integer", "string"]},
                    "pending_file_note": {"type": "string", "minLength": 1},
                    "tracking_bead": {"type": "string", "minLength": 1},
                    "upstream_tracking_bead": {"type": "string", "minLength": 1},
                    "bead_id": {"type": "string", "minLength": 1},
                    "no_script_use_receipt": {"type": "string", "minLength": 1},
                    "callsites": {"type": "array", "items": ref},
                    "tests": {"type": "array", "items": ref},
                    "doctor_probes": {"type": "array", "items": ref},
                    "coverage_score": {"type": "number", "minimum": 0, "maximum": 10},
                    "gap": {"type": ["string", "null"]},
                },
                "allOf": [
                    {
                        "if": {"properties": {"decision": {"const": "WRAP"}}, "required": ["decision"]},
                        "then": {"required": ["wrapper_script", "deletion_tripwire"]},
                    },
                    {
                        "if": {"properties": {"decision": {"const": "EXCLUDED"}}, "required": ["decision"]},
                        "then": {"anyOf": [{"required": ["receipt"]}, {"required": ["exclusion_receipt"]}, {"required": ["why_excluded"]}]},
                    },
                ],
            },
        },
    }


def validate_schema_shape(data):
    try:
        from jsonschema import Draft202012Validator
        from jsonschema.exceptions import SchemaError
    except ModuleNotFoundError as exc:
        return {
            "status": "unverified",
            "validator": "jsonschema",
            "errors": [{"code": "jsonschema_missing", "detail": str(exc)}],
        }
    schema = matrix_schema()
    try:
        Draft202012Validator.check_schema(schema)
    except SchemaError as exc:
        return {
            "status": "fail",
            "validator": "Draft202012Validator",
            "errors": [{"code": "schema_invalid", "detail": exc.message}],
        }
    validator = Draft202012Validator(schema)
    errors = []
    for err in sorted(validator.iter_errors(data), key=lambda item: list(item.path)):
        errors.append({
            "code": "schema_validation_error",
            "path": "/".join(str(part) for part in err.path),
            "detail": err.message,
        })
    return {
        "status": "pass" if not errors else "fail",
        "validator": "Draft202012Validator",
        "errors": errors,
    }


def has_any(row, *names):
    return any(row.get(name) for name in names)


def validate_matrix_semantics(data):
    errors = []
    rows = data.get("surfaces") or []
    seen = set()
    for index, row in enumerate(rows):
        if not isinstance(row, dict):
            continue
        name = row.get("name")
        decision = str(row.get("decision") or "").upper()
        prefix = f"surfaces/{index}"
        if name in seen:
            errors.append({"code": "duplicate_surface_name", "path": prefix, "surface": name})
        seen.add(name)
        if name not in KNOWN_NTM_SURFACES:
            errors.append({"code": "unknown_surface_name", "path": f"{prefix}/name", "surface": name})
        if decision == "USE" and not row.get("callsites") and not row.get("no_script_use_receipt"):
            errors.append({"code": "use_missing_callsites_or_no_script_use_receipt", "path": prefix, "surface": name})
        if decision == "WRAP" and not row.get("deletion_tripwire"):
            errors.append({"code": "wrap_missing_deletion_tripwire", "path": prefix, "surface": name})
        if decision == "ISSUE" and not has_any(row, "issue_url", "pending_file_note"):
            errors.append({"code": "issue_missing_url_or_pending_file_note", "path": prefix, "surface": name})
        if decision == "EXCLUDED" and not has_any(row, "receipt", "exclusion_receipt", "why_excluded"):
            errors.append({"code": "excluded_missing_receipt", "path": prefix, "surface": name})
    scores = [float(row.get("coverage_score")) for row in rows if isinstance(row, dict) and isinstance(row.get("coverage_score"), (int, float))]
    if scores:
        measured_avg = round(sum(scores) / len(scores), 2)
        declared_avg = (data.get("coverage_summary") or {}).get("coverage_avg")
        if isinstance(declared_avg, (int, float)) and abs(round(float(declared_avg), 2) - measured_avg) > 0.01:
            errors.append({
                "code": "coverage_avg_mismatch",
                "path": "coverage_summary/coverage_avg",
                "declared": declared_avg,
                "measured": measured_avg,
            })
        declared_below = (data.get("coverage_summary") or {}).get("below_7_count")
        measured_below = sum(1 for score in scores if score < 7)
        if isinstance(declared_below, int) and declared_below != measured_below:
            errors.append({
                "code": "below_7_count_mismatch",
                "path": "coverage_summary/below_7_count",
                "declared": declared_below,
                "measured": measured_below,
            })
    return {"status": "pass" if not errors else "fail", "errors": errors}


def validate_matrix_contract(data):
    schema_result = validate_schema_shape(data)
    semantic_result = validate_matrix_semantics(data)
    statuses = {schema_result["status"], semantic_result["status"]}
    if "fail" in statuses:
        status = "fail"
    elif "unverified" in statuses:
        status = "unverified"
    else:
        status = "pass"
    return {
        "schema_version": MATRIX_SCHEMA_VERSION,
        "status": status,
        "schema": schema_result,
        "semantic": semantic_result,
    }


def run(cmd, cwd, timeout):
    try:
        proc = subprocess.run(cmd, cwd=str(cwd), text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout)
        return {"cmd": cmd, "exit_code": proc.returncode, "stdout": proc.stdout[-2000:], "stderr": proc.stderr[-2000:]}
    except subprocess.TimeoutExpired as exc:
        return {"cmd": cmd, "exit_code": 124, "stdout": (exc.stdout or "")[-2000:], "stderr": (exc.stderr or "")[-2000:], "timeout": True}
    except FileNotFoundError:
        return {"cmd": cmd, "exit_code": 127, "stderr": "command_not_found"}


def aliases(row):
    vals = [row.get("name")]
    vals.extend(row.get("aliases") or [])
    return [str(v) for v in vals if v]


def grep_callsites(repo, row):
    patterns = []
    for alias in aliases(row):
        patterns.extend([fr"\bntm\s+{re.escape(alias)}\b", fr"\bntm-{re.escape(alias)}\b"])
    dirs = [repo / ".flywheel/scripts", repo / "tests", repo / ".flywheel/tests"]
    hits = []
    for base in dirs:
        if not base.exists():
            continue
        for path in base.rglob("*"):
            if not path.is_file() or path.suffix in {".png", ".jpg", ".webp", ".db"}:
                continue
            try:
                text = path.read_text(encoding="utf-8", errors="ignore")
            except OSError:
                continue
            for lineno, line in enumerate(text.splitlines(), 1):
                if any(re.search(p, line) for p in patterns):
                    hits.append({"path": str(path.relative_to(repo)), "line": lineno})
                    if len(hits) >= 25:
                        return hits
    return hits


def existing_paths(repo, rows):
    found = []
    missing = []
    for item in rows:
        rel = item.get("path") if isinstance(item, dict) else str(item)
        if not rel:
            continue
        path = repo / rel
        (found if path.exists() else missing).append(rel)
    return found, missing


def runnable_tests(repo, row):
    seen = []
    for item in row.get("tests") or []:
        rel = item.get("path") if isinstance(item, dict) else str(item)
        if rel and rel.endswith(".sh") and rel not in seen and (repo / rel).is_file():
            seen.append(rel)
    return seen


def run_tests(repo, row, mode, timeout):
    tests = runnable_tests(repo, row)
    if not tests:
        return {"mode": mode, "status": "UNVERIFIED", "reason": "no_runnable_shell_tests", "results": []}
    if mode == "never":
        return {"mode": mode, "status": "UNVERIFIED", "reason": "test_execution_disabled", "results": [{"path": p, "status": "UNVERIFIED"} for p in tests]}
    results = []
    for rel in tests:
        result = run(["bash", rel], repo, timeout)
        results.append({"path": rel, "exit_code": result["exit_code"], "status": "PASS" if result["exit_code"] == 0 else "FAIL", "stderr": result.get("stderr", "")})
    status = "PASS" if all(r["status"] == "PASS" for r in results) else "FAIL"
    return {"mode": mode, "status": status, "results": results}


def issue_probe(repo, row, gh_bin, br_bin, timeout):
    issue = row.get("jeff_issue") or row.get("issue") or row.get("issue_number") or row.get("issue_url")
    bead = row.get("tracking_bead") or row.get("upstream_tracking_bead") or row.get("bead_id")
    out = {"issue": issue, "tracking_bead": bead, "issue_status": "UNVERIFIED", "bead_status": "UNVERIFIED"}
    if issue:
        issue_arg = str(issue).rstrip("/").split("/")[-1]
        gh = run([gh_bin, "issue", "view", issue_arg, "--json", "state", "-q", ".state"], repo, timeout)
        out["issue_status"] = "PASS" if gh["exit_code"] == 0 and (gh["stdout"].strip().upper() in {"OPEN", "CLOSED"}) else "UNVERIFIED"
        out["issue_state"] = gh["stdout"].strip() if gh["stdout"].strip() else None
    if bead:
        br = run([br_bin, "show", str(bead)], repo, timeout)
        text = f"{br.get('stdout','')}\n{br.get('stderr','')}".lower()
        out["bead_status"] = "PASS" if br["exit_code"] == 0 and any(word in text for word in ("open", "closed", "blocked")) else "FAIL"
    return out


def eval_row(repo, row, args):
    decision = str(row.get("decision") or "UNKNOWN").upper()
    result = {"name": row.get("name"), "decision": decision, "coverage_score": row.get("coverage_score"), "status": "UNVERIFIED", "reasons": []}
    test_result = run_tests(repo, row, args.run_tests, args.test_timeout) if decision in {"USE", "WRAP"} else None
    if decision == "USE":
        hits = grep_callsites(repo, row)
        result["grep_callsite_count"] = len(hits)
        result["grep_callsites_sample"] = hits[:5]
        if not hits:
            result["status"] = "FAIL"
            result["reasons"].append("use_surface_has_no_grep_callsite")
        elif test_result and test_result["status"] == "FAIL":
            result["status"] = "FAIL"
            result["reasons"].append("named_test_failed")
        elif test_result and test_result["status"] == "PASS":
            result["status"] = "PASS"
        else:
            result["status"] = "UNVERIFIED"
            result["reasons"].append(test_result.get("reason", "tests_unverified") if test_result else "tests_unverified")
        result["tests"] = test_result
    elif decision == "WRAP":
        wrapper = row.get("wrapper_script")
        result["wrapper_script"] = wrapper
        result["wrapper_exists"] = bool(wrapper and (repo / wrapper).is_file())
        found_tests, missing_tests = existing_paths(repo, row.get("tests") or [])
        result["fixture_tests_found"] = found_tests
        result["fixture_tests_missing"] = missing_tests
        if not result["wrapper_exists"]:
            result["status"] = "FAIL"
            result["reasons"].append("wrapper_script_missing")
        elif not found_tests:
            result["status"] = "FAIL"
            result["reasons"].append("wrapper_fixture_missing")
        elif test_result and test_result["status"] == "FAIL":
            result["status"] = "FAIL"
            result["reasons"].append("wrapper_fixture_failed")
        elif test_result and test_result["status"] == "PASS":
            result["status"] = "PASS"
        else:
            result["status"] = "UNVERIFIED"
            result["reasons"].append(test_result.get("reason", "fixture_unverified") if test_result else "fixture_unverified")
        result["tests"] = test_result
    elif decision == "ISSUE":
        probe = issue_probe(repo, row, args.gh_bin, args.br_bin, args.test_timeout)
        result["issue_probe"] = probe
        if probe["issue_status"] == "PASS" and probe["bead_status"] == "PASS":
            result["status"] = "PASS"
        elif probe["bead_status"] == "FAIL":
            result["status"] = "FAIL"
            result["reasons"].append("upstream_tracking_bead_missing")
        else:
            result["status"] = "UNVERIFIED"
            result["reasons"].append("issue_or_tracking_bead_unverified")
    elif decision == "EXCLUDED":
        receipt = row.get("receipt") or row.get("exclusion_receipt") or row.get("why_excluded")
        result["receipt_present"] = bool(receipt)
        result["status"] = "PASS" if receipt else "FAIL"
        if not receipt:
            result["reasons"].append("exclusion_receipt_missing")
    else:
        result["status"] = "FAIL"
        result["reasons"].append("unknown_decision")
    return result


def evaluate(args):
    matrix = load_matrix(args.matrix)
    matrix_validation = validate_matrix_contract(matrix)
    rows = [eval_row(args.repo, row, args) for row in matrix["surfaces"]]
    counts = {key: sum(1 for row in rows if row["status"] == key) for key in ("PASS", "FAIL", "UNVERIFIED")}
    decision_counts = {}
    for row in rows:
        decision_counts[row["decision"]] = decision_counts.get(row["decision"], 0) + 1
    coverage_values = [float(row.get("coverage_score")) for row in rows if isinstance(row.get("coverage_score"), (int, float))]
    coverage_avg = round(sum(coverage_values) / len(coverage_values), 2) if coverage_values else None
    status = "fail" if counts["FAIL"] else ("warn" if counts["UNVERIFIED"] else "pass")
    payload = {
        "schema_version": "ntm-surface-validation-driver.v1",
        "status": status,
        "strict": args.strict,
        "checked_at": args.now or utc_now(),
        "repo": str(args.repo),
        "matrix": str(args.matrix),
        "surfaces_total": len(rows),
        "decision_counts": decision_counts,
        "status_counts": counts,
        "ntm_surface_coverage_avg": coverage_avg,
        "coverage_source_avg": matrix.get("coverage_summary", {}).get("coverage_avg"),
        "matrix_validation": matrix_validation,
        "run_tests": args.run_tests,
        "ledger_path": str(args.ledger),
        "ledger_written": False,
        "surfaces": rows if args.max_surfaces < 1 else rows[: args.max_surfaces],
    }
    if not args.dry_run:
        args.ledger.parent.mkdir(parents=True, exist_ok=True)
        payload["ledger_written"] = True
        with args.ledger.open("a", encoding="utf-8") as fh:
            fh.write(json.dumps(payload, sort_keys=True, separators=(",", ":")) + "\n")
    return payload


def static_payload(kind):
    base = {"schema_version": "ntm-surface-validation-driver.v1", "name": "ntm-surface-validation-driver", "status": "ok"}
    if kind == "info":
        base.update({
            "subcommands": ["doctor", "health", "validate", "audit", "repair", "why", "schema", "quickstart"],
            "doctor_fields": ["ntm_surface_coverage_avg", "status_counts", "decision_counts"],
            "json": True,
            "dry_run": True,
            "apply": "ledger append only",
            "default_matrix": str(MATRIX_DEFAULT),
            "default_ledger": str(LEDGER_DEFAULT),
        })
    elif kind == "schema":
        base.update({
            "required": ["schema_version", "status", "surfaces_total", "status_counts", "ntm_surface_coverage_avg", "surfaces"],
            "status_values": ["pass", "warn", "fail"],
            "matrix_schema_version": MATRIX_SCHEMA_VERSION,
            "matrix_schema": matrix_schema(),
        })
    elif kind == "examples":
        base.update({"examples": [
            "ntm-surface-validation-driver.sh --json",
            "ntm-surface-validation-driver.sh --dry-run --json",
            "ntm-surface-validation-driver.sh --strict --run-tests always --json",
            "ntm-surface-validation-driver.sh doctor --json",
        ]})
    elif kind == "repair":
        base.update({"repair_mode": "dry_run", "mutation_performed": False, "planned_actions": ["backfill matrix probes", "rerun validate --json", "inspect FAIL and UNVERIFIED rows"]})
    elif kind == "why":
        base.update({"explanations": {"overview": "Turns 07-VALIDATION-MATRIX.yaml into a repeatable NTM surface regression receipt.", "UNVERIFIED": "A surface has enough static metadata to track but lacks an executable proof in this run.", "FAIL": "A surface violates the decision-specific invariant."}})
    elif kind == "quickstart":
        base.update({"steps": ["run --info --json", "run --dry-run --json", "inspect status_counts", "use --strict in CI once FAIL rows are backfilled"]})
    return base


parser = argparse.ArgumentParser()
parser.add_argument("command", nargs="?", default="validate", choices=["doctor", "health", "validate", "audit", "repair", "why", "schema", "quickstart"])
parser.add_argument("--repo", type=Path, default=ROOT)
parser.add_argument("--matrix", type=Path, default=MATRIX_DEFAULT)
parser.add_argument("--ledger", type=Path, default=LEDGER_DEFAULT)
parser.add_argument("--json", action="store_true")
parser.add_argument("--dry-run", action="store_true")
parser.add_argument("--apply", action="store_true")
parser.add_argument("--strict", action="store_true")
parser.add_argument("--run-tests", choices=["auto", "always", "never"], default=os.environ.get("NTM_SURFACE_VALIDATION_RUN_TESTS", "never"))
parser.add_argument("--test-timeout", type=int, default=int(os.environ.get("NTM_SURFACE_VALIDATION_TEST_TIMEOUT", "8")))
parser.add_argument("--max-surfaces", type=int, default=0, help="Limit emitted surface rows; 0 emits all rows")
parser.add_argument("--gh-bin", default=os.environ.get("GH_BIN", "gh"))
parser.add_argument("--br-bin", default=os.environ.get("BR_BIN", "br"))
parser.add_argument("--now")
parser.add_argument("--info", action="store_true")
parser.add_argument("--schema", action="store_true")
parser.add_argument("--examples", action="store_true")
args = parser.parse_args(sys.argv[4:])

if args.info:
    args.command = "info"
if args.schema:
    args.command = "schema"
if args.examples:
    args.command = "examples"

if args.run_tests == "auto":
    args.run_tests = "always" if args.matrix != MATRIX_DEFAULT else "never"

if args.command in {"info", "schema", "examples", "repair", "why", "quickstart"}:
    emit(static_payload(args.command), True)
    raise SystemExit(0)

try:
    payload = evaluate(args)
except Exception as exc:
    emit({"schema_version": "ntm-surface-validation-driver.v1", "status": "fail", "reason": type(exc).__name__, "detail": str(exc)}, True)
    raise SystemExit(2)

if args.command == "audit":
    payload["audit"] = {"failures": payload["status_counts"]["FAIL"], "unverified": payload["status_counts"]["UNVERIFIED"], "coverage_field": "ntm_surface_coverage_avg"}
emit(payload, args.json)
raise SystemExit(1 if args.strict and payload["status"] == "fail" else 0)
PY
