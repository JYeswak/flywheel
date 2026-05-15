#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCHEMA_VERSION="flywheel.trap_rollback_inventory.v1"
VERSION="0.1.0"

usage() {
  cat <<'EOF'
usage: trap-rollback-inventory.sh [scan|doctor|health|validate] [--repo PATH] [--max-without-trap N] [--json]

Read-only inventory for flywheel-3kq. It scans tracked operational shell
scripts, classifies mutating-like files, and counts EXIT/ERR/RETURN trap
coverage. It measures the rollback-adoption gap; it does not claim the gap is
closed.
EOF
}

info() {
  jq -nc \
    --arg schema_version "tool-info/v1" \
    --arg name "trap-rollback-inventory.sh" \
    --arg version "$VERSION" \
    --arg bead "flywheel-3kq.1" \
    '{
      schema_version:$schema_version,
      name:$name,
      version:$version,
      bead:$bead,
      read_only:true,
      mutates_state:false,
      default_command:"scan",
      commands:["scan","doctor","health","validate"],
      capabilities:[
        "scan tracked operational shell scripts",
        "classify mutating-like scripts",
        "count EXIT/ERR/RETURN trap coverage",
        "emit rollback-adoption inventory JSON"
      ]
    }'
}

schema() {
  jq -nc --arg schema_version "$SCHEMA_VERSION" '{
    schema_version:$schema_version,
    required:["schema_version","status","repo","scan_scope","tracked_shell_scripts_scanned","mutating_like_scripts","mutating_like_without_exit_or_err_trap","sample_without_trap"],
    status_values:["pass","warn","fail"]
  }'
}

examples() {
  jq -nc '{
    examples:[
      ".flywheel/scripts/trap-rollback-inventory.sh --json",
      ".flywheel/scripts/trap-rollback-inventory.sh --repo /path/to/repo --max-without-trap 0 --json",
      ".flywheel/scripts/trap-rollback-inventory.sh doctor --json"
    ]
  }'
}

scan() {
  local repo="$1" max_without_trap="$2"
  python3 - "$repo" "$max_without_trap" "$SCHEMA_VERSION" <<'PY'
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
max_without_trap_arg = sys.argv[2]
schema_version = sys.argv[3]

try:
    raw = subprocess.check_output(["git", "-C", str(repo), "ls-files", "-z"], text=False)
except subprocess.CalledProcessError as exc:
    print(json.dumps({
        "schema_version": schema_version,
        "status": "fail",
        "repo": str(repo),
        "reason": "git_ls_files_failed",
        "returncode": exc.returncode,
    }))
    sys.exit(2)

mutating_re = re.compile(
    r"(^|\s)(rm|mv|cp|chmod|chown|mkdir|touch|tee|install|launchctl|osascript)\b"
    r"|>\s*[^&]|>>\s*[^&]"
    r"|\b(git\s+(add|commit|push|reset|clean|checkout|switch)|br\s+(create|update|close|sync)|ntm\s+send|wezterm\s+cli\s+send-text)\b"
    r"|\b(--apply|--write|--force)\b",
    re.M,
)
trap_re = re.compile(r"(^|\n)\s*trap\b[^\n]*(EXIT|ERR|RETURN)\b")
declared_read_only_re = re.compile(
    r"read_only\s*[:=]\s*true.*mutates_state\s*[:=]\s*false"
    r"|mutates_state\s*[:=]\s*false.*read_only\s*[:=]\s*true",
    re.S,
)
devnull_redir_re = re.compile(r"(?:[0-9]?>|[0-9]?>>|&>)\s*/dev/null\b")

tracked_shell = []
mutating = []
with_trap = []
without_trap = []
declared_read_only_excluded = []

operational_prefixes = (
    ".flywheel/scripts/",
    ".flywheel/hooks/",
    ".flywheel/lib/",
    "scripts/",
)
non_operational_prefixes = (
    ".flywheel/PLANS/",
    ".flywheel/audit/",
    ".flywheel/evidence/",
    ".flywheel/extraction/",
    ".flywheel/fixtures/",
    ".flywheel/receipts/",
    ".flywheel/reports/",
    "tests/",
)

def in_scan_scope(rel: str) -> bool:
    if rel.startswith(non_operational_prefixes):
        return False
    return rel.startswith(operational_prefixes)

for rel_raw in raw.split(b"\0"):
    if not rel_raw:
        continue
    rel = rel_raw.decode("utf-8", "replace")
    path = repo / rel
    if not path.is_file():
        continue
    if not in_scan_scope(rel):
        continue
    try:
        first = path.open("rb").read(256)
    except OSError:
        continue
    is_shell = rel.endswith(".sh") or first.startswith((b"#!/usr/bin/env bash", b"#!/bin/bash", b"#!/bin/sh", b"#!/usr/bin/env sh", b"#!/usr/bin/env zsh", b"#!/bin/zsh"))
    if not is_shell:
        continue
    tracked_shell.append(rel)
    try:
        text = path.read_text(errors="replace")
    except OSError:
        text = ""
    if declared_read_only_re.search(text):
        declared_read_only_excluded.append(rel)
        continue
    mutation_text = devnull_redir_re.sub("", text)
    if mutating_re.search(mutation_text):
        mutating.append(rel)
        if trap_re.search(text):
            with_trap.append(rel)
        else:
            without_trap.append(rel)

max_without_trap = None if max_without_trap_arg == "" else int(max_without_trap_arg)
status = "pass"
if without_trap:
    status = "warn"
if max_without_trap is not None and len(without_trap) > max_without_trap:
    status = "fail"

payload = {
    "schema_version": schema_version,
    "status": status,
    "repo": str(repo),
    "scan_scope": "tracked_operational_shell",
    "excluded_non_operational_prefixes": list(non_operational_prefixes),
    "scanned_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "tracked_shell_scripts_scanned": len(tracked_shell),
    "mutating_like_scripts": len(mutating),
    "mutating_like_with_exit_or_err_trap": len(with_trap),
    "mutating_like_without_exit_or_err_trap": len(without_trap),
    "declared_read_only_excluded_count": len(declared_read_only_excluded),
    "declared_read_only_excluded_sample": declared_read_only_excluded[:25],
    "coverage_pct": round((100.0 * len(with_trap) / len(mutating)), 2) if mutating else 100.0,
    "sample_without_trap": without_trap[:25],
    "max_without_trap": max_without_trap,
    "claim": "inventory_only_not_adoption_complete",
}
print(json.dumps(payload, indent=2))
sys.exit(1 if status == "fail" else 0)
PY
}

command="scan"
repo="$ROOT"
max_without_trap=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    scan|doctor|health|validate) command="$1"; shift ;;
    --repo) repo="$2"; shift 2 ;;
    --max-without-trap) max_without_trap="$2"; shift 2 ;;
    --json|--compact) shift ;;
    --info) info; exit 0 ;;
    --schema) schema; exit 0 ;;
    --examples) examples; exit 0 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

case "$command" in
  scan) scan "$repo" "$max_without_trap" ;;
  validate) scan "$repo" "$max_without_trap" >/dev/null ;;
  doctor|health)
    if command -v git >/dev/null && git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 && command -v python3 >/dev/null && command -v jq >/dev/null; then
      jq -nc --arg schema_version "$SCHEMA_VERSION" --arg command "$command" --arg repo "$repo" '{schema_version:$schema_version,command:$command,status:"pass",repo:$repo,checks:["git","python3","jq"]}'
    else
      jq -nc --arg schema_version "$SCHEMA_VERSION" --arg command "$command" --arg repo "$repo" '{schema_version:$schema_version,command:$command,status:"fail",repo:$repo}'
      exit 1
    fi
    ;;
esac
