#!/usr/bin/env bash
set -euo pipefail

tmp_callback=""
cleanup() {
  if [[ -n "$tmp_callback" ]]; then
    rm -f "$tmp_callback"
  fi
}
trap cleanup EXIT

args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --callback-stdin)
      tmp_callback="$(mktemp "${TMPDIR:-/tmp}/orch-callback-artifacts.XXXXXX")"
      cat >"$tmp_callback"
      args+=(--callback-file "$tmp_callback")
      shift
      ;;
    *)
      args+=("$1")
      shift
      ;;
  esac
done

python3 - "${args[@]}" <<'PY'
import argparse
import json
import os
import re
import shlex
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

VERSION = "orchestrator-callback-artifact-validator.v1.0.0"
SCHEMA_VERSION = "orchestrator-callback-artifact-decision/v1"
LEDGER = Path(os.environ.get("ORCH_CALLBACK_ARTIFACT_LEDGER", str(Path.home() / ".local/state/flywheel/orchestrator-callback-artifact-validator-ledger.jsonl")))
FIX_OPENER = os.environ.get("ORCH_CALLBACK_ARTIFACT_FIX_BEAD_OPENER", "")
DEFAULT_REPO = Path(__file__).resolve().parents[2] if "__file__" in globals() else Path.cwd()
MINS = {
    "script": int(os.environ.get("ORCH_CALLBACK_ARTIFACT_MIN_SCRIPT_BYTES", "100")),
    "test": int(os.environ.get("ORCH_CALLBACK_ARTIFACT_MIN_TEST_BYTES", "200")),
    "schema": int(os.environ.get("ORCH_CALLBACK_ARTIFACT_MIN_SCHEMA_BYTES", "300")),
    "markdown": int(os.environ.get("ORCH_CALLBACK_ARTIFACT_MIN_MD_BYTES", "500")),
    "json": int(os.environ.get("ORCH_CALLBACK_ARTIFACT_MIN_JSON_BYTES", "2")),
    "file": int(os.environ.get("ORCH_CALLBACK_ARTIFACT_MIN_FILE_BYTES", "1")),
}

def now_iso():
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

def usage():
    print("""usage:
  orchestrator-callback-artifact-validator.sh check --callback-text TEXT --dispatch-file PATH [--repo PATH] [--json]
  orchestrator-callback-artifact-validator.sh check --callback-stdin --dispatch-file PATH [--repo PATH] [--json]
  orchestrator-callback-artifact-validator.sh --info|--help|--examples""")

def examples():
    print("""orchestrator-callback-artifact-validator.sh check --callback-text 'DONE task-a evidence=.flywheel/scripts/a.sh' --dispatch-file /tmp/dispatch.md --json
printf '%s\n' 'DONE task-a evidence=.flywheel/scripts/a.sh,.flywheel/tests/a.sh' | orchestrator-callback-artifact-validator.sh check --callback-stdin --dispatch-file /tmp/dispatch.md --repo /Users/josh/Developer/flywheel --json
ORCH_CALLBACK_ARTIFACT_LEDGER=/tmp/artifact-ledger.jsonl orchestrator-callback-artifact-validator.sh check --callback-text 'DONE task-a evidence=a.sh' --dispatch-file /tmp/dispatch.md --json""")

def info():
    print(json.dumps({
        "name": "orchestrator-callback-artifact-validator.sh",
        "version": VERSION,
        "schema_version": SCHEMA_VERSION,
        "ledger": str(LEDGER),
        "purpose": "validate dispatch Required artifacts paths and shapes before forwarding DONE callbacks to summary",
        "exit_codes": {"0": "PASS", "1": "REFUSE fail-closed", "2": "UNVERIFIABLE fail-open parse error"},
        "min_bytes": MINS,
    }, sort_keys=True))

def fail_usage(msg):
    print(f"ERR: {msg}", file=sys.stderr)
    usage()
    raise SystemExit(2)

def parse_args():
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("command", nargs="?")
    parser.add_argument("--callback-text")
    parser.add_argument("--callback-file")
    parser.add_argument("--dispatch-file")
    parser.add_argument("--repo", default=str(Path.cwd()))
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--help", "-h", action="store_true")
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--examples", action="store_true")
    ns, extra = parser.parse_known_args()
    if extra:
        fail_usage(f"unknown argument: {extra[0]}")
    if ns.help:
        usage(); raise SystemExit(0)
    if ns.info:
        info(); raise SystemExit(0)
    if ns.examples:
        examples(); raise SystemExit(0)
    if ns.command != "check":
        fail_usage("missing command: check")
    if bool(ns.callback_text is not None) == bool(ns.callback_file):
        fail_usage("choose one of --callback-text or --callback-stdin")
    if not ns.dispatch_file:
        fail_usage("missing --dispatch-file")
    return ns

def normalize_path(raw, repo):
    value = raw.strip().strip("`").strip()
    value = re.sub(r"\s+\(.*?\)$", "", value)
    value = value.strip()
    if value.startswith("~"):
        return str(Path(value).expanduser())
    p = Path(value)
    return str(p if p.is_absolute() else repo / p)

def type_for(path, heading):
    lower = f"{path} {heading}".lower()
    if "test" in lower or "/tests/" in lower:
        return "test"
    if lower.endswith(".schema.json") or "schema" in lower:
        return "schema"
    if lower.endswith(".sh") or "script" in lower or "wrapper" in lower or "helper" in lower:
        return "script"
    if lower.endswith(".md") or "incidents" in lower or "close-handler" in lower:
        return "markdown"
    if lower.endswith(".json"):
        return "json"
    return "file"

def expected_shape(kind):
    return {
        "script": "executable bash script; bash -n passes",
        "test": "parseable bash test; bash -n passes",
        "schema": "valid JSON Schema Draft 2020-12",
        "markdown": "markdown document meeting minimum bytes",
        "json": "valid JSON document",
    }.get(kind, "file exists and meets minimum bytes")

def parse_required_artifacts(dispatch_path):
    try:
        text = Path(dispatch_path).read_text(encoding="utf-8", errors="replace")
    except OSError as exc:
        return None, f"dispatch_parse_error:{exc}"
    match = re.search(r"(?ims)^##\s*Required artifacts\s*\n(?P<section>.*?)(?=^##\s|\Z)", text)
    if not match:
        return None, "required_artifacts_section_missing"
    artifacts = []
    blocks = re.split(r"(?m)^###\s+", match.group("section"))
    for block in blocks:
        block = block.strip()
        if not block:
            continue
        heading, _, body = block.partition("\n")
        raw_path = None
        path_match = re.search(r"(?im)^Path:\s*(.+?)\s*$", body)
        if path_match:
            raw_path = path_match.group(1).strip().strip("`")
        elif "INCIDENTS.md" in heading or "INCIDENTS.md" in body:
            raw_path = "INCIDENTS.md"
        if not raw_path:
            continue
        raw_path = re.sub(r"\s+[(-].*$", "", raw_path).strip().strip("`")
        kind = type_for(raw_path, heading)
        artifacts.append({"path": raw_path, "type": kind, "expected_shape": expected_shape(kind), "heading": heading.strip()})
    if not artifacts:
        return None, "required_artifacts_section_missing"
    return artifacts, ""

def parse_callback(text):
    compact = " ".join(text.splitlines()).strip()
    try:
        tokens = shlex.split(compact)
    except ValueError as exc:
        return {"ok": False, "error": "callback_malformed", "detail": str(exc), "raw": text, "task_id": "", "bead": "", "evidence_raw": "", "evidence_paths": []}
    if not tokens or tokens[0] != "DONE":
        return {"ok": False, "error": "callback_malformed", "detail": "callback must start with DONE", "raw": text, "task_id": "", "bead": "", "evidence_raw": "", "evidence_paths": []}
    fields, positionals = {}, []
    for token in tokens[1:]:
        if "=" in token:
            k, v = token.split("=", 1); fields[k] = v
        else:
            positionals.append(token)
    task_id = fields.get("task_id") or (positionals[0] if positionals else "")
    evidence = fields.get("evidence", "")
    pieces = [p.strip().strip("`") for p in re.split(r"[,;]", evidence) if p.strip()]
    return {"ok": True, "error": "", "detail": "", "raw": text, "task_id": task_id, "bead": fields.get("bead", ""), "evidence_raw": evidence, "evidence_paths": pieces}

def run_bash_parse(path):
    try:
        proc = subprocess.run(["bash", "-n", str(path)], text=True, capture_output=True, timeout=15)
    except Exception as exc:
        return False, [f"bash_parse_error:{exc}"]
    return proc.returncode == 0, ([] if proc.returncode == 0 else [proc.stderr.strip() or "bash_parse_failed"])

def check_schema(path):
    try:
        import jsonschema
        payload = json.loads(Path(path).read_text(encoding="utf-8"))
        if payload.get("$schema") != "https://json-schema.org/draft/2020-12/schema":
            return False, ["schema_not_draft_2020_12"]
        jsonschema.Draft202012Validator.check_schema(payload)
        return True, []
    except Exception as exc:
        return False, [f"schema_invalid:{exc}"]

def check_artifact(artifact, repo):
    resolved = Path(normalize_path(artifact["path"], repo))
    kind = artifact["type"]
    min_bytes = MINS[kind]
    status = {
        **artifact,
        "resolved_path": str(resolved),
        "exists": resolved.is_file(),
        "bytes": 0,
        "min_bytes": min_bytes,
        "shape_ok": False,
        "shape_errors": [],
        "fulfilled": False,
    }
    if not resolved.is_file():
        status["shape_errors"] = ["file_missing"]
        return status
    status["bytes"] = resolved.stat().st_size
    if status["bytes"] < min_bytes:
        status["shape_errors"].append("below_min_bytes")
    if kind == "script":
        if not os.access(resolved, os.X_OK):
            status["shape_errors"].append("not_executable")
        ok, errors = run_bash_parse(resolved)
        if not ok:
            status["shape_errors"].extend(errors)
    elif kind == "test":
        ok, errors = run_bash_parse(resolved)
        if not ok:
            status["shape_errors"].extend(errors)
    elif kind == "schema":
        ok, errors = check_schema(resolved)
        if not ok:
            status["shape_errors"].extend(errors)
    elif kind == "json":
        try:
            json.loads(resolved.read_text(encoding="utf-8"))
        except Exception as exc:
            status["shape_errors"].append(f"json_invalid:{exc}")
    status["shape_ok"] = not status["shape_errors"]
    status["fulfilled"] = status["exists"] and status["bytes"] >= min_bytes and status["shape_ok"]
    return status

def append_ledger(row):
    try:
        LEDGER.parent.mkdir(parents=True, exist_ok=True)
        with LEDGER.open("a", encoding="utf-8") as fh:
            fh.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")
    except OSError:
        pass

def open_fix_bead(repo, callback, dispatch_file, reason, bad_artifacts):
    opener = FIX_OPENER or str(repo / ".flywheel/scripts/orchestrator-callback-artifact-fix-bead.sh")
    if not os.path.exists(opener) or not os.access(opener, os.X_OK):
        return None
    artifact_list = "\n".join(a["path"] for a in bad_artifacts)
    cmd = [opener, "--repo", str(repo), "--task-id", callback.get("task_id") or "unknown", "--bead", callback.get("bead") or "", "--reason", reason, "--dispatch-file", dispatch_file, "--artifact-list", artifact_list, "--json"]
    try:
        proc = subprocess.run(cmd, text=True, capture_output=True, timeout=20)
        payload = json.loads(proc.stdout or "{}")
        return payload.get("fix_bead_id") or "created_unparsed"
    except Exception:
        return "created_unparsed"

def emit(row, json_out, rc):
    append_ledger(row)
    if json_out:
        print(json.dumps(row, sort_keys=True, separators=(",", ":")))
    else:
        print(f"decision={row['decision']} reason={row['reason']} total_artifacts={row['total_artifacts']} fulfilled_count={row['fulfilled_count']}")
    raise SystemExit(rc)

def decision_reason(statuses, evidence_missing):
    if any(not s["exists"] for s in statuses):
        return "artifact_missing"
    if any(s["bytes"] < s["min_bytes"] for s in statuses):
        return "artifact_subthreshold"
    if any(not s["shape_ok"] for s in statuses):
        return "artifact_malformed"
    if evidence_missing:
        return "evidence_artifact_mismatch"
    return "pass"

def main():
    ns = parse_args()
    repo = Path(ns.repo).expanduser().resolve()
    callback_text = ns.callback_text if ns.callback_text is not None else Path(ns.callback_file).read_text(encoding="utf-8", errors="replace")
    callback = parse_callback(callback_text)
    if not callback["ok"]:
        row = base_row(repo, ns.dispatch_file, callback, [], "UNVERIFIABLE", callback["error"], 2)
        emit(row, ns.json, 2)
    artifacts, parse_error = parse_required_artifacts(ns.dispatch_file)
    if artifacts is None:
        row = base_row(repo, ns.dispatch_file, callback, [], "UNVERIFIABLE", parse_error.split(":", 1)[0], 2)
        row["warnings"] = [parse_error]
        emit(row, ns.json, 2)
    statuses = [check_artifact(a, repo) for a in artifacts]
    required_norm = {normalize_path(a["path"], repo): a["path"] for a in artifacts}
    evidence_norm = {normalize_path(p, repo): p for p in callback["evidence_paths"]}
    missing_evidence = [required_norm[p] for p in sorted(required_norm) if p not in evidence_norm]
    extra_evidence = [evidence_norm[p] for p in sorted(evidence_norm) if p not in required_norm]
    reason = decision_reason(statuses, missing_evidence)
    decision, rc = ("PASS", 0) if reason == "pass" else ("REFUSE", 1)
    row = base_row(repo, ns.dispatch_file, callback, statuses, decision, reason, rc)
    row["missing_artifacts"] = [s["path"] for s in statuses if not s["exists"]]
    row["malformed_artifacts"] = [s["path"] for s in statuses if s["exists"] and not s["shape_ok"] and s["bytes"] >= s["min_bytes"]]
    row["subthreshold_artifacts"] = [s["path"] for s in statuses if s["exists"] and s["bytes"] < s["min_bytes"]]
    row["evidence_missing_artifacts"] = missing_evidence
    row["evidence_extra_paths"] = extra_evidence
    if decision == "REFUSE":
        bad = [s for s in statuses if not s["fulfilled"]]
        if reason == "evidence_artifact_mismatch":
            bad = [{"path": p} for p in missing_evidence]
        row["fix_bead_id"] = open_fix_bead(repo, callback, ns.dispatch_file, reason, bad)
    emit(row, ns.json, rc)

def base_row(repo, dispatch_file, callback, statuses, decision, reason, exit_code):
    return {
        "schema_version": SCHEMA_VERSION,
        "version": VERSION,
        "ts": now_iso(),
        "repo_path": str(repo),
        "dispatch_file": dispatch_file,
        "callback": callback,
        "artifact_status": statuses,
        "total_artifacts": len(statuses),
        "fulfilled_count": sum(1 for s in statuses if s.get("fulfilled")),
        "missing_artifacts": [],
        "malformed_artifacts": [],
        "subthreshold_artifacts": [],
        "evidence_missing_artifacts": [],
        "evidence_extra_paths": [],
        "decision": decision,
        "reason": reason,
        "exit_code": exit_code,
        "fix_bead_id": None,
        "ledger_path": str(LEDGER),
        "warnings": [],
    }

if __name__ == "__main__":
    main()
PY
