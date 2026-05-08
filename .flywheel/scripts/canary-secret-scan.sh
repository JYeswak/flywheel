#!/usr/bin/env bash
set -euo pipefail

VERSION="canary-secret-scan.v1.0.0"

usage() {
  cat <<'EOF'
usage: canary-secret-scan.sh [--json] [--list-patterns] PATH_OR_GLOB [...]

Scans evidence artifacts for synthetic canary secret values. Findings name the
artifact path and field path/line location, but never echo the matched value.

Exit codes:
  0  no canary leaks found
  1  canary leaks found
  2  usage or scan input error
EOF
}

JSON_OUT=1
LIST_PATTERNS=0
ARGS=()
ARG_COUNT=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --json)
      JSON_OUT=1
      shift
      ;;
    --list-patterns)
      LIST_PATTERNS=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --version)
      printf '%s\n' "$VERSION"
      exit 0
      ;;
    --)
      shift
      ARGS+=("$@")
      ARG_COUNT=$((ARG_COUNT + $#))
      break
      ;;
    -*)
      echo "ERR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      ARGS+=("$1")
      ARG_COUNT=$((ARG_COUNT + 1))
      shift
      ;;
  esac
done

if [ "$LIST_PATTERNS" -eq 0 ] && [ "$ARG_COUNT" -eq 0 ]; then
  echo "ERR: at least one path or glob is required" >&2
  usage >&2
  exit 2
fi

set +u
python3 - "$VERSION" "$LIST_PATTERNS" "${ARGS[@]}" <<'PY'
import glob
import json
import os
import re
import sys
from pathlib import Path

version = sys.argv[1]
list_patterns = sys.argv[2] == "1"
inputs = sys.argv[3:]

patterns = [
    ("aws_access_key_id_canary", re.compile(r"CANARY_TEST_AKIA[A-Z0-9]{16}")),
    ("agent_mail_registration_token_canary", re.compile(r"CANARY_TEST_AGENTMAIL_REG_[A-Za-z0-9_-]{24,}")),
    ("bearer_token_canary", re.compile(r"CANARY_TEST_BEARER_[A-Za-z0-9._-]{24,}")),
    ("github_pat_canary", re.compile(r"CANARY_TEST_GITHUB_PAT_[A-Za-z0-9_]{24,}")),
    ("openai_key_canary", re.compile(r"CANARY_TEST_OPENAI_SK_[A-Za-z0-9_-]{24,}")),
    ("env_secret_canary", re.compile(r"CANARY_TEST_ENV_SECRET_[A-Za-z0-9_-]{24,}")),
]

if list_patterns:
    print(json.dumps({
        "schema_version": "canary-secret-scan/v1",
        "version": version,
        "patterns": [name for name, _ in patterns],
        "synthetic_only": True,
    }, sort_keys=True))
    sys.exit(0)

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
    try:
        return data.decode("utf-8"), None
    except UnicodeDecodeError:
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

def finding(path, pattern_name, *, field_path=None, line=None, column=None):
    item = {
        "path": str(path),
        "pattern": pattern_name,
        "redaction": f"[CANARY_REDACTED:{pattern_name}]",
    }
    if field_path is not None:
        item["field_path"] = field_path
    if line is not None:
        item["line"] = line
    if column is not None:
        item["column"] = column
    return item

paths, errors = expand_inputs(inputs)
findings = []
skipped = []

for path in paths:
    text, error = read_text(path)
    if error:
        skipped.append({"path": str(path), "reason": error})
        continue

    parsed = None
    if path.suffix.lower() in {".json", ".jsonl"}:
        if path.suffix.lower() == ".json":
            try:
                parsed = json.loads(text)
            except json.JSONDecodeError:
                parsed = None
        else:
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
            for name, regex in patterns:
                if regex.search(value):
                    findings.append(finding(path, name, field_path=field_path))
        continue

    for line_no, line_text in enumerate(text.splitlines(), start=1):
        for name, regex in patterns:
            match = regex.search(line_text)
            if match:
                findings.append(finding(path, name, line=line_no, column=match.start() + 1))

patterns_matched = sorted({item["pattern"] for item in findings})
paths_matched = sorted({item["path"] for item in findings})
payload = {
    "schema_version": "canary-secret-scan/v1",
    "version": version,
    "leaks_found": len(findings),
    "paths": paths_matched,
    "patterns_matched": patterns_matched,
    "findings": findings,
    "scanned_paths": len(paths),
    "skipped": skipped,
    "errors": errors,
    "synthetic_only": True,
}
print(json.dumps(payload, sort_keys=True))

if errors:
    sys.exit(2)
if findings:
    sys.exit(1)
sys.exit(0)
PY
