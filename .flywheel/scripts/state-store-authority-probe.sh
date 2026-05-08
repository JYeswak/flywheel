#!/usr/bin/env bash
set -euo pipefail

VERSION="state-store-authority-probe/v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
REGISTRY="$ROOT/.flywheel/state-store-authority.json"
LEDGER="${STATE_STORE_AUTHORITY_LEDGER:-$ROOT/.flywheel/state-store-authority-repair.jsonl}"
COMMAND="validate"
JSON_OUT=0
DRY_RUN=1
APPLY=0
WHY_ID=""
SCHEMA_TOPIC="result"

usage() {
  cat <<'EOF'
usage:
  state-store-authority-probe.sh [validate|doctor|health] [--registry PATH] [--root PATH] [--json]
  state-store-authority-probe.sh repair [--dry-run|--apply] [--registry PATH] [--ledger PATH] [--json]
  state-store-authority-probe.sh audit [--ledger PATH] [--json]
  state-store-authority-probe.sh why STORE_ID [--registry PATH] [--json]
  state-store-authority-probe.sh schema result|repair [--json]
  state-store-authority-probe.sh --info|--examples|quickstart|help TOPIC|completion bash|zsh

exit codes: 0=pass, 1=warn/fail/domain issue, 2=usage error
EOF
}

die_usage() {
  printf 'ERR: %s\n' "$1" >&2
  exit 2
}

emit_schema() {
  case "$SCHEMA_TOPIC" in
    result)
      jq -nc '{schema_version:"state-store-authority.result.schema.v1",required:["schema_version","status","store_count","stores","checks"]}'
      ;;
    repair)
      jq -nc '{schema_version:"state-store-authority.repair.schema.v1",required:["schema_version","command","dry_run","append_only_ledgers_never_truncated"]}'
      ;;
    *) die_usage "unknown schema topic: $SCHEMA_TOPIC" ;;
  esac
}

emit_info() {
  jq -nc \
    --arg version "$VERSION" \
    --arg registry "$REGISTRY" \
    --arg ledger "$LEDGER" \
    '{name:"state-store-authority-probe.sh",version:$version,registry:$registry,ledger_path:$ledger,
      canonical_cli_surfaces:["doctor","health","repair","validate","audit","why","schema","--info","--examples","quickstart","help","completion"],
      mutation_default:"dry-run",
      mutation_requires:"repair --apply",
      exit_codes:{"0":"pass","1":"warn or fail","2":"usage error"}}'
}

emit_examples() {
  jq -nc '[
    {name:"validate live contract",command:".flywheel/scripts/state-store-authority-probe.sh validate --json"},
    {name:"repair dry-run receipt",command:".flywheel/scripts/state-store-authority-probe.sh repair --dry-run --json"},
    {name:"append repair receipt",command:".flywheel/scripts/state-store-authority-probe.sh repair --apply --json"},
    {name:"explain a store",command:".flywheel/scripts/state-store-authority-probe.sh why beads --json"}
  ]'
}

quickstart() {
  cat <<'EOF'
Validate state-store authority:
  .flywheel/scripts/state-store-authority-probe.sh validate --json

Plan repair receipt without mutation:
  .flywheel/scripts/state-store-authority-probe.sh repair --dry-run --json

Append repair receipt:
  .flywheel/scripts/state-store-authority-probe.sh repair --apply --json
EOF
}

completion() {
  case "${1:-bash}" in
    bash|zsh|fish)
      printf '%s\n' '# completion: state-store-authority-probe.sh validate doctor health repair audit why schema --registry --root --ledger --dry-run --apply --json --info --examples quickstart help completion'
      ;;
    *) die_usage "unsupported completion shell: ${1:-}" ;;
  esac
}

status_rc() {
  case "$1" in
    pass) return 0 ;;
    warn|fail) return 1 ;;
    *) return 1 ;;
  esac
}

first="${1:-}"
case "$first" in
  validate|doctor|health|repair|audit|why|schema|quickstart|help|completion)
    COMMAND="$first"
    shift
    ;;
  --info|--examples|-h|--help|"")
    ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) [[ $# -ge 2 ]] || die_usage "--root requires PATH"; ROOT="$(cd "$2" && pwd -P)"; REGISTRY="$ROOT/.flywheel/state-store-authority.json"; shift 2 ;;
    --root=*) ROOT="$(cd "${1#*=}" && pwd -P)"; REGISTRY="$ROOT/.flywheel/state-store-authority.json"; shift ;;
    --registry) [[ $# -ge 2 ]] || die_usage "--registry requires PATH"; REGISTRY="$2"; shift 2 ;;
    --registry=*) REGISTRY="${1#*=}"; shift ;;
    --ledger) [[ $# -ge 2 ]] || die_usage "--ledger requires PATH"; LEDGER="$2"; shift 2 ;;
    --ledger=*) LEDGER="${1#*=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --dry-run) DRY_RUN=1; APPLY=0; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --info) emit_info; exit 0 ;;
    --examples) emit_examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    --no-color|--quiet) shift ;;
    --width) [[ $# -ge 2 ]] || die_usage "--width requires N"; shift 2 ;;
    --width=*) shift ;;
    --*) die_usage "unknown argument: $1" ;;
    *)
      if [[ "$COMMAND" == "why" && -z "$WHY_ID" ]]; then
        WHY_ID="$1"
        shift
      elif [[ "$COMMAND" == "schema" ]]; then
        SCHEMA_TOPIC="$1"
        shift
      else
        die_usage "unexpected argument: $1"
      fi
      ;;
  esac
done

case "$COMMAND" in
  quickstart) quickstart; exit 0 ;;
  help) usage; exit 0 ;;
  completion) completion "${WHY_ID:-bash}"; exit 0 ;;
  schema) emit_schema; exit 0 ;;
  audit)
    if [[ "$JSON_OUT" -eq 1 ]]; then
      if [[ -f "$LEDGER" ]]; then jq -s -c --arg ledger "$LEDGER" '{schema_version:"state-store-authority.audit.v1",ledger_path:$ledger,rows:(.[-20:] // [])}' "$LEDGER"; else jq -nc --arg ledger "$LEDGER" '{schema_version:"state-store-authority.audit.v1",ledger_path:$ledger,rows:[]}'; fi
    else
      [[ -f "$LEDGER" ]] && tail -n 20 "$LEDGER" || printf 'audit: no ledger found at %s\n' "$LEDGER"
    fi
    exit 0
    ;;
esac

[[ -r "$REGISTRY" ]] || die_usage "registry not readable: $REGISTRY"

result="$(
  python3 - "$REGISTRY" "$ROOT" "$VERSION" "$COMMAND" "$WHY_ID" <<'PY'
import json, os, sys
from datetime import datetime, timezone
from pathlib import Path

registry_path = Path(sys.argv[1]).expanduser()
root = Path(sys.argv[2]).expanduser()
version = sys.argv[3]
command = sys.argv[4]
why_id = sys.argv[5]

def expand(path):
    if not path:
        return None
    raw = str(path)
    if raw.startswith("~/"):
        return str(Path(raw).expanduser())
    if raw.startswith("/"):
        return raw
    return str(root / raw)

def mtime(path):
    try:
        return Path(path).stat().st_mtime
    except OSError:
        return None

data = json.loads(registry_path.read_text())
stores = data.get("stores", [])
rows = []
checks = []
rank = {"pass": 0, "warn": 1, "fail": 2}
overall = "pass"

def add_check(store_id, name, status, detail):
    global overall
    checks.append({"store_id": store_id, "check": name, "status": status, "detail": detail})
    if rank[status] > rank[overall]:
        overall = status

if command == "why":
    match = next((s for s in stores if s.get("id") == why_id), None)
    print(json.dumps({
        "schema_version": "state-store-authority.why.v1",
        "command": "why",
        "store_id": why_id,
        "match": match,
    }, sort_keys=True, separators=(",", ":")))
    raise SystemExit(0 if match else 1)

for store in stores:
    sid = store.get("id", "unknown")
    source = expand(store.get("source_path"))
    source_exists = bool(source and Path(source).exists())
    source_mtime = mtime(source) if source else None
    backup = store.get("backup_path")
    migration = store.get("migration_command")
    integrity = store.get("integrity_probe_command")
    repair = store.get("repair_command")
    contract = store.get("repair_contract") or {}
    dry = contract.get("dry_run_command")
    apply = contract.get("apply_command")
    append_only = contract.get("append_only_ledgers_never_truncated") or []

    add_check(sid, "backup_path_declared", "pass" if backup else "warn", backup or "missing backup_path")
    add_check(sid, "migration_command_declared", "pass" if migration else "warn", migration or "missing migration_command")
    add_check(sid, "integrity_probe_declared", "pass" if integrity else "fail", integrity or "missing integrity_probe_command")
    add_check(sid, "repair_command_declared", "pass" if repair else "fail", repair or "missing repair_command")
    add_check(sid, "repair_contract_dry_run", "pass" if dry else "fail", dry or "missing repair_contract.dry_run_command")
    add_check(sid, "repair_contract_apply", "pass" if apply else "fail", apply or "missing repair_contract.apply_command")
    add_check(sid, "append_only_policy", "pass" if append_only else "fail", append_only or "missing append_only_ledgers_never_truncated")

    probe_status = store.get("integrity_probe_status")
    if probe_status == "fail":
        add_check(sid, "integrity_probe_status", "fail", store.get("integrity_probe_detail") or "declared failed")
    elif probe_status == "warn":
        add_check(sid, "integrity_probe_status", "warn", store.get("integrity_probe_detail") or "declared warning")
    else:
        add_check(sid, "integrity_probe_status", "pass", probe_status or "declared")

    stale = []
    missing_mirror = []
    for mirror in store.get("derived_mirrors") or []:
        mirror_path = expand(mirror.get("path"))
        freshness_source = expand(mirror.get("freshness_source") or store.get("source_path"))
        mirror_mtime = mtime(mirror_path) if mirror_path else None
        fresh_mtime = mtime(freshness_source) if freshness_source else source_mtime
        if mirror_path and not Path(mirror_path).exists() and mirror.get("required", True) is not False:
            missing_mirror.append(mirror.get("path"))
        elif mirror_mtime is not None and fresh_mtime is not None and mirror_mtime < fresh_mtime:
            stale.append(mirror.get("path"))
    if stale:
        add_check(sid, "derived_mirror_freshness", "warn", {"stale_mirrors": stale})
    elif missing_mirror:
        add_check(sid, "derived_mirror_freshness", "warn", {"missing_mirrors": missing_mirror})
    else:
        add_check(sid, "derived_mirror_freshness", "pass", "fresh_or_not_applicable")

    rows.append({
        "id": sid,
        "kind": store.get("kind"),
        "authority": store.get("authority"),
        "source_path": store.get("source_path"),
        "source_exists": source_exists,
        "derived_mirrors": store.get("derived_mirrors") or [],
        "backup_path": backup,
        "migration_command": migration,
        "integrity_probe_command": integrity,
        "repair_command": repair,
        "repair_contract": contract,
    })

print(json.dumps({
    "schema_version": "state-store-authority.result.v1",
    "version": version,
    "command": command,
    "registry_path": str(registry_path),
    "root": str(root),
    "status": overall,
    "store_count": len(stores),
    "stores": rows,
    "checks": checks,
    "summary": {
        "pass": sum(1 for c in checks if c["status"] == "pass"),
        "warn": sum(1 for c in checks if c["status"] == "warn"),
        "fail": sum(1 for c in checks if c["status"] == "fail"),
    },
}, sort_keys=True, separators=(",", ":")))
PY
)"

if [[ "$COMMAND" == "why" ]]; then
  [[ "$JSON_OUT" -eq 1 ]] && printf '%s\n' "$result" || jq -r '"store_id=\(.store_id) match=\(.match != null)"' <<<"$result"
  jq -e '.match != null' >/dev/null <<<"$result"
  exit $?
fi

if [[ "$COMMAND" == "repair" ]]; then
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  dry_bool=false
  apply_bool=false
  [[ "$DRY_RUN" -eq 1 ]] && dry_bool=true
  [[ "$APPLY" -eq 1 ]] && apply_bool=true
  row="$(jq -c --arg ts "$ts" --arg ledger "$LEDGER" --argjson validation "$result" --argjson dry_run "$dry_bool" --argjson apply "$apply_bool" '
    {
      schema_version:"state-store-authority.repair.v1",
      command:"repair",
      ts:$ts,
      dry_run:$dry_run,
      apply:$apply,
      status:(if $apply then "applied" else "planned" end),
      ledger_path:$ledger,
      validation_status:$validation.status,
      append_only_ledgers_never_truncated:true,
      planned_actions:($validation.stores | map({store_id:.id,dry_run_command:.repair_contract.dry_run_command,apply_command:.repair_contract.apply_command,receipt_path:.repair_contract.receipt_path})),
      actual_actions:(if $apply then ["append_state_store_authority_repair_receipt"] else [] end)
    }
  ' <<<"$result")"
  if [[ "$APPLY" -eq 1 ]]; then
    mkdir -p "$(dirname "$LEDGER")"
    printf '%s\n' "$row" >>"$LEDGER"
  fi
  [[ "$JSON_OUT" -eq 1 ]] && printf '%s\n' "$row" || jq -r '"status=\(.status) dry_run=\(.dry_run) validation_status=\(.validation_status)"' <<<"$row"
  exit 0
fi

[[ "$JSON_OUT" -eq 1 ]] && printf '%s\n' "$result" || jq -r '"status=\(.status) stores=\(.store_count) pass=\(.summary.pass) warn=\(.summary.warn) fail=\(.summary.fail)"' <<<"$result"
status="$(jq -r '.status' <<<"$result")"
status_rc "$status"
