#!/usr/bin/env bash
set -euo pipefail

VERSION="security-posture-probe.v1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
CORPUS="$REPO_ROOT/.flywheel/security/v1/secret-patterns.json"

usage() {
  cat <<'EOF'
usage: security-posture-probe.sh [--json] [--details] [--schema|--info|--examples|--why|--doctor|--health|--validate|--audit|--repair] [PATH_OR_GLOB ...]

Scans synthetic fixtures and evidence artifacts for canary secret patterns.
Default scan output reports counts and classes only. It never emits matched
values or token fragments.

Exit codes:
  0  metadata emitted, no findings, or read-only health passed
  1  findings present or repair refused
  2  usage, corpus, or input error
EOF
}

MODE="scan"
JSON_OUT=0
DETAILS=0
ARGS=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --details) DETAILS=1; shift ;;
    --schema) MODE="schema"; shift ;;
    --info) MODE="info"; shift ;;
    --examples) MODE="examples"; shift ;;
    --why) MODE="why"; shift ;;
    --doctor) MODE="doctor"; shift ;;
    --health) MODE="health"; shift ;;
    --validate) MODE="validate"; shift ;;
    --audit) MODE="audit"; shift ;;
    --repair) MODE="repair"; shift ;;
    --help|-h) usage; exit 0 ;;
    --version) printf '%s\n' "$VERSION"; exit 0 ;;
    --) shift; ARGS+=("$@"); break ;;
    -*) printf 'ERR: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

if [ "$MODE" = "scan" ] && [ "${#ARGS[@]}" -eq 0 ]; then
  printf 'ERR: at least one path or glob is required for scan mode\n' >&2
  usage >&2
  exit 2
fi

python3 - "$VERSION" "$MODE" "$JSON_OUT" "$DETAILS" "$CORPUS" "${ARGS[@]}" <<'PY'
import glob
import json
import os
import re
import sys
from collections import Counter
from pathlib import Path

version, mode = sys.argv[1], sys.argv[2]
json_out = sys.argv[3] == "1"
details = sys.argv[4] == "1"
corpus_path = Path(sys.argv[5])
inputs = sys.argv[6:]

def emit(payload, rc=0):
    if json_out or mode != "scan":
        print(json.dumps(payload, sort_keys=True))
    else:
        status = payload.get("status", "ok")
        count = payload.get("findings_count", 0)
        classes = ",".join(payload.get("classes", [])) or "none"
        print(f"status={status} findings_count={count} classes={classes}")
    raise SystemExit(rc)

def load_corpus():
    try:
        with corpus_path.open(encoding="utf-8") as fh:
            corpus = json.load(fh)
    except FileNotFoundError:
        emit({"schema_version": "security-posture-probe/v1", "status": "error", "error": "corpus_missing", "corpus_path": str(corpus_path)}, 2)
    except json.JSONDecodeError as exc:
        emit({"schema_version": "security-posture-probe/v1", "status": "error", "error": "corpus_invalid_json", "message": str(exc)}, 2)
    patterns = corpus.get("patterns", [])
    errors = []
    compiled = []
    seen = set()
    for idx, item in enumerate(patterns):
        pattern_id = item.get("id")
        klass = item.get("class")
        regex = item.get("regex")
        if not pattern_id or not klass or not regex:
            errors.append({"index": idx, "error": "missing_required_field"})
            continue
        if pattern_id in seen:
            errors.append({"id": pattern_id, "error": "duplicate_id"})
            continue
        seen.add(pattern_id)
        try:
            compiled.append((pattern_id, klass, item.get("severity", "unknown"), re.compile(regex)))
        except re.error as exc:
            errors.append({"id": pattern_id, "error": "invalid_regex", "message": str(exc)})
    return corpus, compiled, errors

corpus, patterns, corpus_errors = load_corpus()

schema = {
    "type": "object",
    "required": ["schema_version", "status", "synthetic_only", "patterns_count", "findings_count", "classes", "counts_by_class"],
    "properties": {
        "schema_version": {"const": "security-posture-probe/v1"},
        "status": {"enum": ["pass", "fail", "warn", "error", "refused"]},
        "synthetic_only": {"const": True},
        "patterns_count": {"type": "integer", "minimum": 0},
        "findings_count": {"type": "integer", "minimum": 0},
        "classes": {"type": "array", "items": {"type": "string"}},
        "counts_by_class": {"type": "object"},
        "secret_values_emitted": {"const": False}
    }
}

if mode == "schema":
    emit({"schema_version": "security-posture-probe.schema/v1", "schema": schema, "exit_codes": {"0": "ok", "1": "findings_or_refused", "2": "usage_or_input_error"}})

if mode == "info":
    emit({
        "schema_version": "security-posture-probe.info/v1",
        "name": "security-posture-probe.sh",
        "version": version,
        "corpus_path": str(corpus_path),
        "patterns_count": len(patterns),
        "synthetic_only": bool(corpus.get("synthetic_only")),
        "canonical_cli_surfaces": ["--schema", "--info", "--examples", "--why", "--doctor", "--health", "--validate", "--audit", "--repair", "--json"],
        "secret_values_emitted": False,
    }, 0 if not corpus_errors else 2)

if mode == "examples":
    emit({
        "schema_version": "security-posture-probe.examples/v1",
        "examples": [
            "security-posture-probe.sh --schema --json",
            "security-posture-probe.sh --info --json",
            "security-posture-probe.sh --json tests/fixtures/canary-secret-scan/leaky",
            "security-posture-probe.sh --details --json tests/fixtures/canary-secret-scan/leaky",
            "security-posture-probe.sh --validate --json tests/fixtures/canary-secret-scan/clean"
        ]
    })

if mode == "why":
    emit({
        "schema_version": "security-posture-probe.why/v1",
        "reason": "Agent security posture needs a synthetic-only scanner that proves class/count detection without printing or storing secret values.",
        "out_of_scope": ["live secret scanning", "secret value printing", "token rotation"],
        "secret_values_emitted": False,
    })

if mode == "repair":
    emit({
        "schema_version": "security-posture-probe.repair/v1",
        "status": "refused",
        "read_only": True,
        "reason": "Security posture probe is read-only; remediation must be handled by explicit follow-up beads.",
        "secret_values_emitted": False,
    }, 1)

def expand_inputs(values):
    paths = []
    errors = []
    for value in values:
        expanded = os.path.expanduser(value)
        matches = glob.glob(expanded, recursive=True)
        if not matches and Path(expanded).exists():
            matches = [expanded]
        if not matches:
            errors.append({"input": value, "error": "path_or_glob_not_found"})
            continue
        for match in matches:
            p = Path(match)
            if p.is_dir():
                for child in p.rglob("*"):
                    if child.is_file() and ".git" not in child.parts:
                        paths.append(child)
            elif p.is_file():
                paths.append(p)
            else:
                errors.append({"input": value, "path": str(p), "error": "not_file_or_directory"})
    unique = []
    seen = set()
    for p in paths:
        key = str(p)
        if key not in seen:
            unique.append(p)
            seen.add(key)
    return unique, errors

def read_text(path):
    data = path.read_bytes()
    if b"\x00" in data:
        return None, "binary_skipped"
    return data.decode("utf-8", errors="replace"), None

def json_paths(obj, prefix="$"):
    if isinstance(obj, dict):
        for key, value in obj.items():
            safe = str(key).replace("\\", "\\\\").replace('"', '\\"')
            yield from json_paths(value, f'{prefix}["{safe}"]')
    elif isinstance(obj, list):
        for idx, value in enumerate(obj):
            yield from json_paths(value, f"{prefix}[{idx}]")
    elif isinstance(obj, str):
        yield prefix, obj

def scan_paths(values):
    paths, input_errors = expand_inputs(values)
    skipped = []
    findings = []
    for path in paths:
        text, error = read_text(path)
        if error:
            skipped.append({"path": str(path), "reason": error})
            continue
        parsed = None
        suffix = path.suffix.lower()
        if suffix == ".json":
            try:
                parsed = json.loads(text)
            except json.JSONDecodeError:
                parsed = None
        elif suffix == ".jsonl":
            rows = []
            ok = True
            for raw in text.splitlines():
                if not raw.strip():
                    continue
                try:
                    rows.append(json.loads(raw))
                except json.JSONDecodeError:
                    ok = False
                    break
            if ok:
                parsed = rows
        if parsed is not None:
            for field_path, value in json_paths(parsed):
                for pattern_id, klass, severity, regex in patterns:
                    if regex.search(value):
                        findings.append({"path": str(path), "class": klass, "pattern_id": pattern_id, "severity": severity, "field_path": field_path, "redaction": f"[REDACTED:{klass}]"})
            continue
        for line_no, line_text in enumerate(text.splitlines(), start=1):
            for pattern_id, klass, severity, regex in patterns:
                match = regex.search(line_text)
                if match:
                    findings.append({"path": str(path), "class": klass, "pattern_id": pattern_id, "severity": severity, "line": line_no, "redaction": f"[REDACTED:{klass}]"})
    return paths, input_errors, skipped, findings

if mode in {"doctor", "health"} and not inputs:
    status = "pass" if not corpus_errors and len(patterns) >= 15 else "fail"
    emit({
        "schema_version": f"security-posture-probe.{mode}/v1",
        "status": status,
        "corpus_path": str(corpus_path),
        "patterns_count": len(patterns),
        "corpus_errors": corpus_errors,
        "synthetic_only": bool(corpus.get("synthetic_only")),
        "secret_values_emitted": False,
    }, 0 if status == "pass" else 1)

if mode in {"validate", "audit", "doctor", "health"} and not inputs:
    inputs = []

paths, input_errors, skipped, findings = scan_paths(inputs)
counts = Counter(item["class"] for item in findings)
classes = sorted(counts)
payload = {
    "schema_version": "security-posture-probe/v1",
    "mode": mode,
    "status": "fail" if findings or input_errors or corpus_errors else "pass",
    "synthetic_only": bool(corpus.get("synthetic_only")),
    "patterns_count": len(patterns),
    "findings_count": len(findings),
    "classes": classes,
    "counts_by_class": dict(sorted(counts.items())),
    "scanned_paths": len(paths),
    "skipped": skipped,
    "errors": input_errors + corpus_errors,
    "secret_values_emitted": False,
}
if details:
    payload["findings"] = findings

if input_errors or corpus_errors:
    emit(payload, 2)
emit(payload, 1 if findings else 0)
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
