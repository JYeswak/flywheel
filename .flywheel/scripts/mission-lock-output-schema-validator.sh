#!/usr/bin/env bash
set -euo pipefail

VERSION="mission-lock-output-schema-validator/v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCHEMA_PATH="$ROOT/.flywheel/validation-schema/v1/mission-lock-output.schema.json"
MISSION_PATH="$ROOT/.flywheel/MISSION.md"
JSON_OUT=0
QUIET=0

for arg in "$@"; do
  [[ "$arg" == "--json" ]] && JSON_OUT=1
done

usage() {
  printf '%s\n' \
    'usage:' \
    '  mission-lock-output-schema-validator.sh [--mission MISSION.md|payload.json] [--schema schema.json] [--json] [--quiet]' \
    '  mission-lock-output-schema-validator.sh doctor|--doctor [--json]' \
    '  mission-lock-output-schema-validator.sh --info|--help|--examples [--json]'
}

examples() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc '{examples:["mission-lock-output-schema-validator.sh doctor --json","mission-lock-output-schema-validator.sh --json","mission-lock-output-schema-validator.sh --mission /tmp/MISSION.md --quiet","mission-lock-output-schema-validator.sh --mission /tmp/output.json --schema .flywheel/validation-schema/v1/mission-lock-output.schema.json --json"]}'
  else
    printf '%s\n' \
      'mission-lock-output-schema-validator.sh doctor --json' \
      'mission-lock-output-schema-validator.sh --json' \
      'mission-lock-output-schema-validator.sh --mission /tmp/MISSION.md --quiet' \
      'mission-lock-output-schema-validator.sh --mission /tmp/output.json --schema .flywheel/validation-schema/v1/mission-lock-output.schema.json --json'
  fi
}

info() {
  jq -nc --arg version "$VERSION" --arg schema "$SCHEMA_PATH" '{name:"mission-lock-output-schema-validator.sh",version:$version,schema:$schema,mutates:false,canonical_cli_flags:["--info","--help","--examples","doctor","--doctor","--json","--quiet"],input_sources:["json","yaml_frontmatter","sidecar_json","key_value_metadata"],doctor_schema:"mission-lock-output-schema-validator.doctor.v1",exit_codes:{"0":"pass","1":"validation_fail","2":"usage_or_schema_error"}}'
}

die_usage() { printf 'ERR: %s\n' "$1" >&2; exit 2; }

doctor() {
  local schema_status mission_status backend_status tmp_status overall
  overall="pass"
  if [[ -r "$SCHEMA_PATH" ]]; then
    schema_status="pass"
  else
    schema_status="fail"
    overall="fail"
  fi
  if [[ -r "$MISSION_PATH" ]]; then
    mission_status="pass"
  else
    mission_status="warn"
    [[ "$overall" == "fail" ]] || overall="warn"
  fi
  if python3 - <<'PY' >/dev/null 2>&1
import jsonschema
PY
  then
    backend_status="pass"
  else
    backend_status="fail"
    overall="fail"
  fi
  if tmp_probe="$(mktemp "${TMPDIR:-/tmp}/mission-lock-output-schema-doctor.XXXXXX" 2>/dev/null)"; then
    rm -f "$tmp_probe"
    tmp_status="pass"
  else
    tmp_status="fail"
    overall="fail"
  fi
  jq -nc \
    --arg status "$overall" \
    --arg version "$VERSION" \
    --arg schema_path "$SCHEMA_PATH" \
    --arg mission_path "$MISSION_PATH" \
    --arg schema_status "$schema_status" \
    --arg mission_status "$mission_status" \
    --arg backend_status "$backend_status" \
    --arg tmp_status "$tmp_status" \
    '{
      schema_version: "mission-lock-output-schema-validator.doctor.v1",
      command: "doctor",
      status: $status,
      mode: "read_only",
      mutates: false,
      version: $version,
      schema_path: $schema_path,
      mission_path: $mission_path,
      checks: [
        {name:"schema_readable", status:$schema_status},
        {name:"mission_input_readable", status:$mission_status},
        {name:"python_jsonschema_available", status:$backend_status},
        {name:"tmp_writable", status:$tmp_status}
      ]
    }'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --mission) [[ $# -ge 2 ]] || die_usage "--mission requires a path"; MISSION_PATH="$2"; shift 2 ;;
    --schema) [[ $# -ge 2 ]] || die_usage "--schema requires a path"; SCHEMA_PATH="$2"; shift 2 ;;
    --info) info; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    --examples) examples; exit 0 ;;
    doctor|--doctor) doctor; exit 0 ;;
    --*) die_usage "unknown argument: $1" ;;
    *) MISSION_PATH="$1"; shift ;;
  esac
done

[[ -r "$MISSION_PATH" ]] || die_usage "mission input not readable: $MISSION_PATH"
[[ -r "$SCHEMA_PATH" ]] || die_usage "schema not readable: $SCHEMA_PATH"
TMP="$(mktemp "${TMPDIR:-/tmp}/mission-lock-output-schema.XXXXXX")"
trap 'rm -f "$TMP"' EXIT

set +e
python3 - "$MISSION_PATH" "$SCHEMA_PATH" "$VERSION" >"$TMP" <<'PY'
import json, re, sys
from pathlib import Path

mission_path = Path(sys.argv[1])
schema_path = Path(sys.argv[2])
version = sys.argv[3]

def scalar(value):
    value = value.strip()
    if value == "":
        return ""
    low = value.lower()
    if low in {"true", "false"}:
        return low == "true"
    if low == "null":
        return None
    if value[0] in "[{\"":
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return value
    if re.fullmatch(r"-?[0-9]+", value):
        return int(value)
    if re.fullmatch(r"-?[0-9]+[.][0-9]+", value):
        return float(value)
    return value

def pairs(lines):
    data = {}
    for line in lines:
        match = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):\s*(.*?)\s*$", line)
        if match:
            data[match.group(1)] = scalar(match.group(2))
    return data

def load_payload(path):
    if path.suffix == ".json":
        return json.loads(path.read_text(encoding="utf-8")), "json"
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    if lines and lines[0].strip() == "---":
        for idx in range(1, len(lines)):
            if lines[idx].strip() == "---":
                return pairs(lines[1:idx]), "yaml_frontmatter"
    for cand in (path.with_suffix(path.suffix + ".json"), path.with_suffix(".json")):
        if cand.exists():
            return json.loads(cand.read_text(encoding="utf-8")), f"sidecar_json:{cand}"
    kept = []
    for line in lines:
        if line.startswith("## "):
            break
        if not line.startswith("#"):
            kept.append(line)
    return pairs(kept), "key_value_metadata"

def coded(error):
    path = ".".join(str(part) for part in error.path)
    key = path.replace(".", "_") if path else "root"
    if error.validator == "required":
        match = re.search(r"'([^']+)' is a required property", error.message)
        name = match.group(1) if match else "field"
        return f"missing_{name}", f"{path + '.' if path else ''}{name}"
    if error.validator in {"enum", "pattern", "const"}:
        return f"invalid_{key}", path or "$"
    if error.validator == "minItems":
        return f"empty_{key}", path or "$"
    if error.validator == "type":
        return f"invalid_type_{key}", path or "$"
    return f"schema_{error.validator}_{key}", path or "$"

try:
    from jsonschema import Draft7Validator, FormatChecker
    schema = json.loads(schema_path.read_text(encoding="utf-8"))
    payload, source = load_payload(mission_path)
    Draft7Validator.check_schema(schema)
    validator = Draft7Validator(schema, format_checker=FormatChecker())
    errors = []
    for err in sorted(validator.iter_errors(payload), key=lambda item: list(item.path) + [item.message]):
        code, path = coded(err)
        errors.append({"path": path, "code": code, "detail": err.message})
    print(json.dumps({
        "schema_version": version,
        "status": "pass" if not errors else "fail",
        "valid": not errors,
        "mission_path": str(mission_path),
        "schema_path": str(schema_path),
        "validated_schema_id": schema.get("$id"),
        "extract_source": source,
        "validator_backend": "jsonschema",
        "error_count": len(errors),
        "errors": errors
    }, sort_keys=True))
    sys.exit(0 if not errors else 1)
except Exception as exc:
    print(json.dumps({"schema_version": version, "status": "error", "valid": False, "errors": [{"path": "$", "code": "validator_error", "detail": str(exc)}]}))
    sys.exit(2)
PY
rc=$?
set -e

if [[ "$QUIET" -eq 0 ]]; then
  if [[ "$JSON_OUT" -eq 1 ]]; then
    cat "$TMP"
  else
    jq -r '"status=\(.status) valid=\(.valid) errors=\(.error_count // 0) source=\(.extract_source // "none")"' "$TMP"
  fi
fi
exit "$rc"
