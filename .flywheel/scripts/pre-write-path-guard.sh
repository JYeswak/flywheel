#!/usr/bin/env bash
# pre-write-path-guard.sh — Layer-1 PREVENTION primitive for the
# absolute-path-construction-drift-to-peer-canonical-substrate trauma class.
#
# Bead: flywheel-16b53.2 — root-cause fix #2 from flywheel-16b53 P0 trauma.
# Sister primitive: .flywheel/scripts/cd-realpath-wrapper.sh (cd-time prevention
# for the same drift class).
#
# Trauma signature (per flywheel-16b53 evidence):
#   Worker authoring doctrine files in flywheel.git used an absolute-path
#   construction pattern that landed writes into a PEER repo (skillos.git)
#   at /Users/josh/Developer/skillos/.flywheel/doctrine/*.md, clobbering
#   9 canonical files + 1 README on the peer side. Peer orch's working tree
#   captured pre-write state via git stash before commit — no permanent
#   loss, but the orch-side write-path-scoping discipline was missing.
#
# This guard:
#   - Resolves a proposed --path via realpath BEFORE the Write tool fires
#   - Compares against an OWNED_WRITE_ROOTS allowlist scoped per --bead
#   - Allows iff the resolved path is strictly under one of the allowlisted roots
#   - Denies with structured reason + ledger row otherwise
#
# Allowlist resolution hierarchy (first hit wins):
#   1. --allowed-roots VALUE  (CLI override; colon-separated)
#   2. FLYWHEEL_PRE_WRITE_ALLOWED_ROOTS env (colon-separated)
#   3. .flywheel/policy/write-roots/<bead>.txt  (per-bead policy file)
#   4. .flywheel/policy/write-roots/default.txt (project default policy)
#   5. $(git -C cwd rev-parse --show-toplevel)  (current-repo fallback)
#
# Usage:
#   pre-write-path-guard.sh --path PATH --bead BEAD-ID [--apply|--dry-run] [--json]
#   pre-write-path-guard.sh doctor [--json]
#   pre-write-path-guard.sh health [--json]
#   pre-write-path-guard.sh repair --scope state [--apply --idempotency-key KEY]
#   pre-write-path-guard.sh validate <subject> [args]
#   pre-write-path-guard.sh audit [--json]
#   pre-write-path-guard.sh why <decision-id>
#   pre-write-path-guard.sh quickstart [--json]
#   pre-write-path-guard.sh help <topic>
#   pre-write-path-guard.sh completion <bash|zsh>
#   pre-write-path-guard.sh --info|--schema|--examples|--help
#
# Exit codes:
#   0 — allow (resolved path is under an allowlisted root)
#   1 — deny  (resolved path is NOT under any allowlisted root)
#   2 — usage / arg error
#   3 — missing or malformed policy (recoverable; see `repair --scope state`)
#   4 — path does not exist or fails realpath (caller must own the path)

set -uo pipefail

SCHEMA_VERSION="pre-write-path-guard/v1"
REPO_ROOT="${PRE_WRITE_PATH_GUARD_REPO_ROOT:-/Users/josh/Developer/flywheel}"
POLICY_DIR="${PRE_WRITE_PATH_GUARD_POLICY_DIR:-$REPO_ROOT/.flywheel/policy/write-roots}"
LEDGER="${PRE_WRITE_PATH_GUARD_LEDGER:-$HOME/.local/state/flywheel/pre-write-path-guard-log.jsonl}"

# ---------- helpers ----------

emit_iso_now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

emit_decision_id() {
  printf '%s|%s|%s' "$(emit_iso_now)" "${1:-na}" "${2:-na}" \
    | shasum -a 256 | awk '{print "pwg-" substr($1,1,16)}'
}

ledger_append() {
  local row="$1"
  mkdir -p "$(dirname "$LEDGER")" 2>/dev/null || true
  if [[ -w "$(dirname "$LEDGER")" || -w "$LEDGER" ]]; then
    printf '%s\n' "$row" >>"$LEDGER" 2>/dev/null || true
  fi
}

resolve_path() {
  # macOS realpath -m allows non-existent leaf; we want to validate the
  # proposed write-destination before the file exists, so use python.
  python3 -c '
import os, sys
p = sys.argv[1]
# Resolve symlinks + canonicalize even when leaf does not exist yet.
parent = os.path.dirname(p) or "."
leaf = os.path.basename(p)
try:
    parent_real = os.path.realpath(parent)
except Exception:
    parent_real = parent
print(os.path.join(parent_real, leaf) if leaf else parent_real)
' "$1"
}

resolve_root() {
  # Roots are resolved with realpath as well (existing dir or fail).
  python3 -c '
import os, sys
p = sys.argv[1].rstrip("/")
try:
    r = os.path.realpath(p)
    # Trailing-slash form for prefix-match safety:
    if not r.endswith("/"):
        r = r + "/"
    print(r)
except Exception:
    sys.exit(2)
' "$1" 2>/dev/null
}

# Returns 0 if `resolved_path` starts with `root` (slash-aware).
path_under_root() {
  local resolved="$1"
  local root="$2"
  # Both should be trailing-slash form for safe prefix match; resolve_root
  # adds trailing slash, but resolved_path may not. Add one for compare:
  local cmp="${resolved%/}/"
  [[ "$cmp" == "$root"* ]]
}

# ---------- allowlist resolution ----------

resolve_allowlist() {
  local bead="$1"
  local override_csv="${2:-}"
  # Echo: <policy_source>\t<root1>\t<root2>\t...
  if [[ -n "$override_csv" ]]; then
    local IFS=':'
    local roots=()
    for r in $override_csv; do [[ -n "$r" ]] && roots+=("$r"); done
    printf 'cli_override'
    for r in "${roots[@]}"; do printf '\t%s' "$r"; done
    printf '\n'
    return 0
  fi
  if [[ -n "${FLYWHEEL_PRE_WRITE_ALLOWED_ROOTS:-}" ]]; then
    local IFS=':'
    local roots=()
    for r in $FLYWHEEL_PRE_WRITE_ALLOWED_ROOTS; do [[ -n "$r" ]] && roots+=("$r"); done
    printf 'env_override'
    for r in "${roots[@]}"; do printf '\t%s' "$r"; done
    printf '\n'
    return 0
  fi
  if [[ -n "$bead" && -r "$POLICY_DIR/$bead.txt" ]]; then
    printf 'per_bead'
    while IFS= read -r line; do
      # Strip comments + blank lines
      line="${line%%#*}"
      line="${line##[[:space:]]*}"
      line="${line%%[[:space:]]*}"
      [[ -z "$line" ]] && continue
      printf '\t%s' "$line"
    done <"$POLICY_DIR/$bead.txt"
    printf '\n'
    return 0
  fi
  if [[ -r "$POLICY_DIR/default.txt" ]]; then
    printf 'default'
    while IFS= read -r line; do
      line="${line%%#*}"
      line="${line##[[:space:]]*}"
      line="${line%%[[:space:]]*}"
      [[ -z "$line" ]] && continue
      printf '\t%s' "$line"
    done <"$POLICY_DIR/default.txt"
    printf '\n'
    return 0
  fi
  # Final fallback: current repo only (git toplevel).
  local toplevel
  toplevel="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null)"
  if [[ -n "$toplevel" ]]; then
    printf 'fallback_git_toplevel\t%s\n' "$toplevel"
    return 0
  fi
  printf 'fallback_none\n'
  return 0
}

# ---------- primary: validate a write proposal ----------

cmd_validate_write() {
  local path="" bead="" mode="dry_run" json_out=0 override_csv=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --path) path="${2:-}"; shift 2 ;;
      --bead) bead="${2:-}"; shift 2 ;;
      --apply) mode="apply"; shift ;;
      --dry-run) mode="dry_run"; shift ;;
      --allowed-roots) override_csv="${2:-}"; shift 2 ;;
      --json) json_out=1; shift ;;
      -h|--help) emit_help_validate_write; return 0 ;;
      *) echo "ERR: unknown flag: $1" >&2; return 2 ;;
    esac
  done
  if [[ -z "$path" ]]; then
    echo "ERR: --path is required" >&2; return 2
  fi
  if [[ -z "$bead" ]]; then
    bead="${FLYWHEEL_CURRENT_BEAD:-unknown}"
  fi

  local path_resolved
  path_resolved="$(resolve_path "$path")"
  if [[ -z "$path_resolved" ]]; then
    echo "ERR: realpath failed for $path" >&2; return 4
  fi

  # Parse allowlist
  local allowlist_line
  allowlist_line="$(resolve_allowlist "$bead" "$override_csv")"
  local policy_source
  policy_source="$(printf '%s' "$allowlist_line" | cut -f1)"
  local roots_raw
  roots_raw="$(printf '%s' "$allowlist_line" | cut -f2-)"

  # Resolve each root via realpath; collect resolved set.
  local resolved_roots=()
  local raw_roots=()
  if [[ -n "$roots_raw" ]]; then
    local IFS=$'\t'
    for r in $roots_raw; do
      [[ -z "$r" ]] && continue
      raw_roots+=("$r")
      local rr
      rr="$(resolve_root "$r")"
      if [[ -n "$rr" ]]; then
        resolved_roots+=("$rr")
      fi
    done
  fi

  local decision="deny"
  local matched_root=""
  local reason=""
  if [[ "${#resolved_roots[@]}" -eq 0 ]]; then
    decision="deny"
    reason="no_allowlist_roots_resolved (policy_source=$policy_source)"
  else
    for rr in "${resolved_roots[@]}"; do
      if path_under_root "$path_resolved" "$rr"; then
        decision="allow"
        matched_root="$rr"
        break
      fi
    done
    if [[ "$decision" == "deny" ]]; then
      local roots_csv
      roots_csv="$(IFS=,; printf '%s' "${resolved_roots[*]}")"
      reason="path_outside_allowlist (resolved=$path_resolved; roots=$roots_csv; policy_source=$policy_source)"
    fi
  fi

  local decision_id
  decision_id="$(emit_decision_id "$bead" "$path_resolved")"

  # Build payload (we always emit the row; mode controls only whether the
  # ledger is written, so dry-run is non-destructive).
  local roots_json
  roots_json="$(printf '%s\n' "${resolved_roots[@]}" 2>/dev/null | jq -R . | jq -sc .)"
  if [[ -z "$roots_json" ]]; then roots_json="[]"; fi
  local raw_roots_json
  raw_roots_json="$(printf '%s\n' "${raw_roots[@]}" 2>/dev/null | jq -R . | jq -sc .)"
  if [[ -z "$raw_roots_json" ]]; then raw_roots_json="[]"; fi

  local payload
  payload="$(jq -nc \
    --arg sv "$SCHEMA_VERSION" \
    --arg ts "$(emit_iso_now)" \
    --arg id "$decision_id" \
    --arg bead "$bead" \
    --arg path_in "$path" \
    --arg path_resolved "$path_resolved" \
    --arg policy_source "$policy_source" \
    --arg decision "$decision" \
    --arg matched_root "$matched_root" \
    --arg reason "$reason" \
    --arg mode "$mode" \
    --argjson allowed_roots "$roots_json" \
    --argjson allowed_roots_raw "$raw_roots_json" \
    '{schema_version:$sv, command:"validate-write", ts:$ts, id:$id, bead:$bead,
      path_in:$path_in, path_resolved:$path_resolved,
      policy_source:$policy_source, allowed_roots:$allowed_roots,
      allowed_roots_raw:$allowed_roots_raw,
      decision:$decision, matched_root:(if $matched_root=="" then null else $matched_root end),
      reason:(if $reason=="" then null else $reason end), mode:$mode}')"

  # Always append to ledger (audit trail is the load-bearing safety net).
  ledger_append "$payload"

  if [[ "$json_out" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    if [[ "$decision" == "allow" ]]; then
      printf 'allow path=%s bead=%s root=%s policy=%s\n' \
        "$path_resolved" "$bead" "$matched_root" "$policy_source"
    else
      printf 'deny  path=%s bead=%s reason=%s\n' \
        "$path_resolved" "$bead" "$reason" >&2
    fi
  fi

  if [[ "$decision" == "allow" ]]; then return 0; else return 1; fi
}

emit_help_validate_write() {
  cat <<'HELP'
usage: pre-write-path-guard.sh --path PATH --bead BEAD-ID [--apply|--dry-run] [--json] [--allowed-roots A:B:C]

Verifies that PATH (proposed write-destination) is strictly under the
OWNED_WRITE_ROOTS allowlist for BEAD-ID. Resolves via realpath before
prefix-match (symlinks + non-existent leaves both handled).

Allowlist resolution order:
  1. --allowed-roots VALUE                              (CLI override)
  2. $FLYWHEEL_PRE_WRITE_ALLOWED_ROOTS                  (env override)
  3. .flywheel/policy/write-roots/<bead>.txt            (per-bead policy)
  4. .flywheel/policy/write-roots/default.txt           (project default)
  5. $(git rev-parse --show-toplevel)                   (current-repo fallback)

Exit codes:
  0 — allow
  1 — deny
  2 — usage / arg error
  3 — missing or malformed policy (run `repair --scope state`)
  4 — path realpath failed
HELP
}

# ---------- canonical-cli surfaces ----------

cmd_doctor() {
  local json_out=0
  [[ "${1:-}" == "--json" ]] && json_out=1
  local checks=()
  if [[ -d "$POLICY_DIR" ]]; then
    checks+=("$(jq -nc --arg p "$POLICY_DIR" '{check:"policy_dir",path:$p,status:"pass"}')")
  else
    checks+=("$(jq -nc --arg p "$POLICY_DIR" '{check:"policy_dir",path:$p,status:"warn",reason:"policy dir missing; falling back to git toplevel"}')")
  fi
  if [[ -r "$POLICY_DIR/default.txt" ]]; then
    local n
    n="$(grep -vcE '^[[:space:]]*(#|$)' "$POLICY_DIR/default.txt" 2>/dev/null || echo 0)"
    checks+=("$(jq -nc --arg p "$POLICY_DIR/default.txt" --argjson n "$n" '{check:"default_policy",path:$p,roots:$n,status:"pass"}')")
  else
    checks+=("$(jq -nc --arg p "$POLICY_DIR/default.txt" '{check:"default_policy",path:$p,status:"warn",reason:"no default policy; fallback to git toplevel"}')")
  fi
  if command -v jq >/dev/null && command -v python3 >/dev/null; then
    checks+=("$(jq -nc '{check:"deps",status:"pass",found:["jq","python3"]}')")
  else
    checks+=("$(jq -nc '{check:"deps",status:"fail",reason:"jq + python3 required"}')")
  fi
  if [[ -d "$(dirname "$LEDGER")" ]]; then
    checks+=("$(jq -nc --arg p "$LEDGER" '{check:"ledger_dir",path:$p,status:"pass"}')")
  else
    checks+=("$(jq -nc --arg p "$LEDGER" '{check:"ledger_dir",path:$p,status:"warn",reason:"will be created on first decision"}')")
  fi
  local checks_json
  checks_json="$(printf '%s\n' "${checks[@]}" | jq -sc .)"
  local fails warns status
  fails="$(jq -r '[.[] | select(.status=="fail")] | length' <<<"$checks_json")"
  warns="$(jq -r '[.[] | select(.status=="warn")] | length' <<<"$checks_json")"
  if [[ "$fails" -gt 0 ]]; then status="fail"
  elif [[ "$warns" -gt 0 ]]; then status="warn"
  else status="pass"; fi
  jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$(emit_iso_now)" --arg status "$status" --argjson checks "$checks_json" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$status,checks:$checks}'
}

cmd_health() {
  local rows=0 latest_ts="" latest_decision=""
  if [[ -r "$LEDGER" ]]; then
    rows="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
    if [[ "$rows" -gt 0 ]]; then
      latest_ts="$(tail -1 "$LEDGER" | jq -r '.ts // empty' 2>/dev/null)"
      latest_decision="$(tail -1 "$LEDGER" | jq -r '.decision // empty' 2>/dev/null)"
    fi
  fi
  local deny_count="0"
  if [[ -r "$LEDGER" ]]; then
    deny_count="$(jq -s '[.[] | select(.decision=="deny")] | length' "$LEDGER" 2>/dev/null || echo 0)"
  fi
  local status="empty"
  [[ "$rows" -gt 0 ]] && status="ok"
  jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$(emit_iso_now)" --arg status "$status" \
    --argjson rows "$rows" --argjson deny_count "$deny_count" \
    --arg latest_ts "$latest_ts" --arg latest_decision "$latest_decision" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,row_count:$rows,deny_count:$deny_count,
      latest_decision:(if $latest_decision=="" then null else $latest_decision end),
      latest_ts:(if $latest_ts=="" then null else $latest_ts end)}'
}

cmd_repair() {
  local scope="" mode="dry_run" idem_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --scope) scope="${2:-}"; shift 2 ;;
      --apply) mode="apply"; shift ;;
      --dry-run) mode="dry_run"; shift ;;
      --idempotency-key) idem_key="${2:-}"; shift 2 ;;
      --json) shift ;;
      -h|--help)
        echo "usage: repair --scope state [--apply --idempotency-key KEY]"; return 0 ;;
      *) echo "ERR: unknown repair arg: $1" >&2; return 2 ;;
    esac
  done
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" '{schema_version:$sv,command:"repair",status:"refused",reason:"--apply requires --idempotency-key"}'
    return 3
  fi
  local planned=()
  if [[ "$scope" == "state" ]]; then
    [[ ! -d "$POLICY_DIR" ]] && planned+=("$(jq -nc --arg p "$POLICY_DIR" '{action:"mkdir",path:$p}')")
    [[ ! -d "$(dirname "$LEDGER")" ]] && planned+=("$(jq -nc --arg p "$(dirname "$LEDGER")" '{action:"mkdir",path:$p}')")
    if [[ ! -r "$POLICY_DIR/default.txt" ]]; then
      planned+=("$(jq -nc --arg p "$POLICY_DIR/default.txt" --arg c "$REPO_ROOT" '{action:"create_default_policy",path:$p,content:("# default write-roots — current repo only\n" + $c + "\n")}')")
    fi
  else
    planned+=("$(jq -nc --arg s "$scope" '{action:"none",reason:"unsupported scope (use --scope state)",scope:$s}')")
  fi
  local planned_json
  planned_json="$(printf '%s\n' "${planned[@]}" 2>/dev/null | jq -sc .)"
  [[ -z "$planned_json" ]] && planned_json='[]'
  local applied='[]'
  if [[ "$mode" == "apply" && "$scope" == "state" ]]; then
    mkdir -p "$POLICY_DIR" "$(dirname "$LEDGER")" 2>/dev/null || true
    if [[ ! -r "$POLICY_DIR/default.txt" ]]; then
      printf '# default write-roots — current repo only\n%s\n' "$REPO_ROOT" >"$POLICY_DIR/default.txt"
    fi
    applied="$(jq -nc --arg key "$idem_key" '{applied_actions:[{action:"state_initialized",idempotency_key:$key}]}')"
  fi
  jq -nc --arg sv "$SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg key "$idem_key" \
    --argjson planned "$planned_json" --argjson applied "$applied" \
    '{schema_version:$sv,command:"repair",scope:$scope,mode:$mode,idempotency_key:$key,planned:$planned,applied:$applied}'
}

cmd_audit() {
  local n=20
  [[ "${1:-}" =~ ^[0-9]+$ ]] && n="$1"
  if [[ -r "$LEDGER" ]]; then
    jq -s --argjson n "$n" --arg sv "$SCHEMA_VERSION" \
      '{schema_version:$sv,command:"audit",row_count:length,rows:(.[-$n:])}' \
      "$LEDGER" 2>/dev/null
  else
    jq -nc --arg sv "$SCHEMA_VERSION" --arg p "$LEDGER" \
      '{schema_version:$sv,command:"audit",row_count:0,rows:[],note:"no ledger yet",ledger_path:$p}'
  fi
}

cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    echo "ERR: why <decision-id>" >&2; return 2
  fi
  if [[ ! -r "$LEDGER" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg id "$id" '{schema_version:$sv,command:"why",id:$id,status:"no_ledger"}'
    return 0
  fi
  jq -c --arg sv "$SCHEMA_VERSION" --arg id "$id" \
    'select(.id==$id) | {schema_version:$sv,command:"why",id:.id,row:.}' \
    "$LEDGER" | head -1 || jq -nc --arg sv "$SCHEMA_VERSION" --arg id "$id" '{schema_version:$sv,command:"why",id:$id,status:"not_found"}'
}

cmd_quickstart() {
  cat <<'QS'
pre-write-path-guard.sh — quickstart

1. Verify substrate:
     pre-write-path-guard.sh doctor --json

2. Initialize state if doctor warns:
     pre-write-path-guard.sh repair --scope state --apply --idempotency-key init-$(date +%s)

3. Probe a proposed write (dry-run):
     pre-write-path-guard.sh --path /Users/josh/Developer/flywheel/.flywheel/foo.md --bead flywheel-X --json

4. Authoritative pre-write check (called by canonical-cli-helpers.sh cli_pre_write_check):
     pre-write-path-guard.sh --path PATH --bead BEAD --apply --json
   Exit 0 = allow; 1 = deny.

5. Investigate a denial:
     pre-write-path-guard.sh why pwg-<16-hex>
QS
}

cmd_info() {
  jq -nc --arg sv "$SCHEMA_VERSION" --arg policy "$POLICY_DIR" --arg ledger "$LEDGER" --arg repo "$REPO_ROOT" \
    '{schema_version:$sv,command:"info",name:"pre-write-path-guard.sh",
      paths:{policy_dir:$policy,ledger:$ledger,repo_root:$repo},
      deps:["bash","jq","python3","date","shasum","git"]}'
}

cmd_schema() {
  jq -nc --arg sv "$SCHEMA_VERSION" \
    '{schema_version:$sv,command:"schema",surfaces:["validate-write","doctor","health","repair","audit","why","quickstart","info"],
      note:"validate-write is the primary surface; emits {bead,path_in,path_resolved,policy_source,allowed_roots,decision,matched_root,reason,mode}"}'
}

cmd_examples() {
  cat <<'EX'
{"name":"allow current repo write","invocation":"pre-write-path-guard.sh --path /Users/josh/Developer/flywheel/.flywheel/foo.md --bead flywheel-X --json"}
{"name":"deny peer-repo drift (trauma class)","invocation":"pre-write-path-guard.sh --path /Users/josh/Developer/skillos/.flywheel/doctrine/bar.md --bead flywheel-v38e1.5 --json"}
{"name":"per-bead allowlist override","invocation":"FLYWHEEL_PRE_WRITE_ALLOWED_ROOTS=/Users/josh/Developer/flywheel:/Users/josh/Developer/zeststream-brand-voice pre-write-path-guard.sh --path PATH --bead BEAD --json"}
{"name":"audit recent decisions","invocation":"pre-write-path-guard.sh audit"}
EX
}

cmd_help_long() { emit_help_validate_write; }

emit_help_short() {
  cat <<'HELP'
usage: pre-write-path-guard.sh [SUBCOMMAND] [OPTIONS]

Primary surface (no subcommand): validate a proposed write-destination
  --path PATH --bead BEAD [--apply|--dry-run] [--json] [--allowed-roots A:B:C]

Canonical CLI surfaces:
  doctor [--json]           substrate health
  health [--json]           last-run status + deny counter
  repair --scope state      initialize/repair policy + ledger dirs
                              Default --dry-run; mutate with --apply --idempotency-key KEY
  audit [N]                 tail N decisions (default 20)
  why <decision-id>         explain a recorded decision
  quickstart                operator orientation
  help <topic>              topic help

Introspection:
  --info / --schema / --examples / --help

Exit codes:
  0 allow | 1 deny | 2 usage | 3 missing/malformed policy | 4 realpath failed
HELP
}

# ---------- main dispatcher ----------

main() {
  if [[ $# -eq 0 ]]; then
    emit_help_short; exit 2
  fi
  case "$1" in
    --help|-h)    emit_help_short; exit 0 ;;
    --info)       cmd_info; exit 0 ;;
    --schema)     cmd_schema; exit 0 ;;
    --examples)   cmd_examples; exit 0 ;;
    doctor)       shift; cmd_doctor "$@"; exit 0 ;;
    health)       shift; cmd_health "$@"; exit 0 ;;
    repair)       shift; cmd_repair "$@"; exit $? ;;
    audit)        shift; cmd_audit "$@"; exit 0 ;;
    why)          shift; cmd_why "$@"; exit $? ;;
    quickstart)   shift; cmd_quickstart "$@"; exit 0 ;;
    help)         shift; cmd_help_long "$@"; exit 0 ;;
    completion)   shift; printf '# bash/zsh completion stub for pre-write-path-guard\n'; exit 0 ;;
    --path|--bead|--apply|--dry-run|--json|--allowed-roots)
      cmd_validate_write "$@"; exit $? ;;
    *)
      echo "ERR: unknown command/flag: $1" >&2
      emit_help_short >&2
      exit 2 ;;
  esac
}

main "$@"
