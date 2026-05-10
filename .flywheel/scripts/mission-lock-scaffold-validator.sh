#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (TODO markers in stubs need fill-in)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block is APPENDED by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved as `cmd_run` (the new main routes
# default invocation through cmd_run for backward compat). Surface-
# specific logic stays as TODO markers — see grep '# TODO(canonical-cli-scaffold)'.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="mission-lock-scaffold-validator/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/mission-lock-scaffold-validator-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: mission-lock-scaffold-validator.sh [SUBCOMMAND] [OPTIONS]

Backward-compatible run mode: default invocation routes to the original
top-level logic (now exposed as `cmd_run`).

Canonical CLI surfaces:
  doctor [--json]          probe substrate health
  health [--json]          last-run status
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
  validate <subject> [...] validate per-subject contract (TODO: define subjects)
  audit [--json]           recent run history
  why <id>                 explain provenance for a given id (TODO: id semantics)
  quickstart [--json]      operator orientation
  help <topic>             topic help (run | doctor | health | repair | validate)
  completion <shell>       emit bash or zsh completion

Introspection:
  --info --json            version, paths, env vars, dependencies, sha256
  --schema [<surface>]     JSON Schema for output envelopes
  --examples --json        curated workflow examples
  --help / -h              this help
USG
}

scaffold_emit_info() {
  if ! command -v cli_emit_info >/dev/null; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "mission-lock-scaffold-validator.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "mission-lock-scaffold-validator.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"mission-lock-scaffold-validator.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"mission-lock-scaffold-validator.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"mission-lock-scaffold-validator.sh doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-default}"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
    '{schema_version:$sv,command:"schema",surface:$surface,note:"TODO(canonical-cli-scaffold): per-surface schema fill-in"}'
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to cmd_run.\n' ;;
    doctor)   printf 'topic: doctor — TODO(canonical-cli-scaffold): document doctor checks specific to this surface.\n' ;;
    health)   printf 'topic: health — TODO(canonical-cli-scaffold): document health probes specific to this surface.\n' ;;
    repair)   printf 'topic: repair — TODO(canonical-cli-scaffold): document repair scopes + idempotency contract.\n' ;;
    validate) printf 'topic: validate — TODO(canonical-cli-scaffold): document validation subjects + contracts.\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "mission-lock-scaffold-validator" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "mission-lock-scaffold-validator" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # TODO(canonical-cli-scaffold): probe substrate this script depends on
  # (env vars, paths, external tools) and emit per-check status.
  # Canonical pattern (per L4 lint rule — NEVER use `[[ ]] && X || Y`
  # as the last expression of a helper; use if/then/else/fi):
  #   if [[ -d "$ROOT/.flywheel" ]]; then
  #     printf '{"check":"flywheel-dir","status":"pass"}\n'
  #   else
  #     printf '{"check":"flywheel-dir","status":"fail"}\n'
  #   fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:"todo",checks:[],note:"TODO(canonical-cli-scaffold): fill in doctor checks"}'
}

scaffold_cmd_health() {
  # TODO(canonical-cli-scaffold): summarize last-run state from audit log.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:$sv,command:"health",ts:$ts,status:"todo",note:"TODO(canonical-cli-scaffold): fill in health probe from audit log"}'
}

scaffold_cmd_repair() {
  local scope="" mode="dry_run" idem_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help repair; return 0 ;;
      --scope) scope="${2:-}"; shift 2 ;;
      --dry-run) mode="dry_run"; shift ;;
      --apply) mode="apply"; shift ;;
      --idempotency-key) idem_key="${2:-}"; shift 2 ;;
      --idempotency-key=*) idem_key="${1#--idempotency-key=}"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown repair arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    if command -v cli_refuse_apply_without_idem_key >/dev/null; then
      cli_refuse_apply_without_idem_key "$SCAFFOLD_SCHEMA_VERSION" "repair" "$scope"
    else
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:"apply",scope:$scope,reason:"--apply requires --idempotency-key"}'
      exit 3
    fi
  fi
  # TODO(canonical-cli-scaffold): per-scope repair actions go here.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
    '{schema_version:$sv,command:"repair",status:"todo",mode:$mode,scope:$scope,idempotency_key:$idem,note:"TODO(canonical-cli-scaffold): fill in repair scope actions"}'
}

scaffold_cmd_validate() {
  # TODO(canonical-cli-scaffold): document validation subjects + contracts.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    '{schema_version:$sv,command:"validate",status:"todo",note:"TODO(canonical-cli-scaffold): fill in per-subject validation"}'
}

scaffold_cmd_audit() {
  # TODO(canonical-cli-scaffold): tail audit log; emit recent rows.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" \
    '{schema_version:$sv,command:"audit",audit_log:$log,status:"todo",note:"TODO(canonical-cli-scaffold): fill in audit tail"}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  # TODO(canonical-cli-scaffold): explain why <id> is/isn't in scope.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" \
    '{schema_version:$sv,command:"why",id:$id,status:"todo",note:"TODO(canonical-cli-scaffold): fill in why-id semantics"}'
}

# ---------- scaffolded main dispatcher ----------

# When the scaffolder appends this block, it expects the target's original
# top-level main is renamed to `cmd_run` (or the original final
# `main "$@"` line is replaced with this dispatcher). Default invocation
# falls through to the original logic for backward compat.
scaffold_main() {
  if [[ $# -eq 0 ]]; then
    scaffold_usage; exit 0
  fi
  case "$1" in
    -h|--help)    scaffold_usage; exit 0 ;;
    --info)       shift; scaffold_emit_info "$@"; exit 0 ;;
    --schema)     shift; scaffold_emit_schema "${1:-default}"; exit 0 ;;
    --examples)   shift; scaffold_emit_examples "$@"; exit 0 ;;
    doctor)       shift; scaffold_cmd_doctor "$@"; exit $? ;;
    health)       shift; scaffold_cmd_health "$@"; exit $? ;;
    repair)       shift; scaffold_cmd_repair "$@"; exit $? ;;
    validate)     shift; scaffold_cmd_validate "$@"; exit $? ;;
    audit)        shift; scaffold_cmd_audit "$@"; exit $? ;;
    why)          shift; scaffold_cmd_why "$@"; exit $? ;;
    quickstart)   shift; scaffold_emit_quickstart "$@"; exit 0 ;;
    help)         shift; scaffold_emit_topic_help "${1:-}"; exit 0 ;;
    completion)   shift; scaffold_emit_completion "${1:-bash}"; exit $? ;;
    *)
      printf 'ERR: unknown canonical subcommand: %s\n' "$1" >&2
      scaffold_usage >&2
      exit 64 ;;
  esac
}

# Early-dispatch intercept: if argv[0] looks like a canonical subcommand
# or introspection flag, run the canonical surface and exit BEFORE the
# target's original arg parser sees the args. Works for both `main "$@"`
# style and inline `while [[ $# -gt 0 ]]` style targets.
_scaffold_is_canonical_arg() {
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --info|--schema|--examples) return 0 ;;
    -h|--help) return 0 ;;
    help)
      # Intercept `help <topic>` and `help --help`; bare `help` could be
      # a legacy subcommand of the target so it falls through.
      case "${2:-}" in run|doctor|health|repair|validate|audit|why|-h|--help) return 0 ;; esac
      return 1 ;;
    *) return 1 ;;
  esac
}

if [[ $# -gt 0 ]] && _scaffold_is_canonical_arg "$@"; then
  scaffold_main "$@"
  exit $?
fi
# ====== END canonical-cli scaffold ======
VERSION="mission-lock-scaffold-validator/v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MISSION_PATH="$ROOT/.flywheel/MISSION.md"
JSON_OUT=0
QUIET=0
COMMAND="validate"
for arg in "$@"; do [[ "$arg" == "--json" ]] && JSON_OUT=1; done

usage() {
  printf '%s\n' \
    'usage:' \
    '  mission-lock-scaffold-validator.sh [validate|doctor|health|audit|schema] [--mission MISSION.md] [--json] [--quiet]' \
    '  mission-lock-scaffold-validator.sh --info|--help|--examples [--json]'
}

examples() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc '{examples:["mission-lock-scaffold-validator.sh --json","mission-lock-scaffold-validator.sh validate --mission .flywheel/MISSION.md --json","mission-lock-scaffold-validator.sh schema --json"]}'
  else
    printf '%s\n' 'mission-lock-scaffold-validator.sh --json' 'mission-lock-scaffold-validator.sh validate --mission .flywheel/MISSION.md --json' 'mission-lock-scaffold-validator.sh schema --json'
  fi
}

info() {
  jq -nc --arg version "$VERSION" '{name:"mission-lock-scaffold-validator.sh",version:$version,mutates:false,canonical_cli_flags:["--info","--help","--examples","--json","--quiet"],canonical_cli_verbs:["validate","doctor","health","audit","schema"],exit_codes:{"0":"ready_or_incomplete","1":"blocked","2":"usage"}}'
}

schema_payload() {
  jq -nc --arg version "$VERSION" '{schema_version:$version,required_sections:["Mission Source","North-Star Outcome","Primary Beneficiary","Explicit Non-Goals","Safety And Privacy Boundaries","Evidence That Would Change The Mission","Owner-Review Cadence","Lock Receipt","Negative invariants (security)"],section_hash_algorithm:"sha256 normalized section body after removing section-hash comments, trimming blank edges, joining with LF, and appending one LF",section_hash_comment:"<!-- section_hash: <section title> sha256:<64 hex> -->",substrate_inventory_section:"Substrate inventory"}'
}

die_usage() { printf 'ERR: %s\n' "$1" >&2; exit 2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    validate|doctor|health|audit|schema) COMMAND="$1"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --mission) [[ $# -ge 2 ]] || die_usage "--mission requires a path"; MISSION_PATH="$2"; shift 2 ;;
    --info) info; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    --examples) examples; exit 0 ;;
    --*) die_usage "unknown argument: $1" ;;
    *) MISSION_PATH="$1"; shift ;;
  esac
done

if [[ "$COMMAND" == "schema" ]]; then schema_payload; exit 0; fi
[[ -r "$MISSION_PATH" ]] || die_usage "mission file not readable: $MISSION_PATH"
TMP="$(mktemp "${TMPDIR:-/tmp}/mission-lock-scaffold.XXXXXX")"
trap 'rm -f "$TMP"' EXIT

python3 - "$MISSION_PATH" "$ROOT" "$VERSION" "$COMMAND" >"$TMP" <<'PY'
import datetime as D, hashlib, json, re, sys
from pathlib import Path

mission = Path(sys.argv[1]).resolve()
root = Path(sys.argv[2]).resolve()
version, command = sys.argv[3], sys.argv[4]
text = mission.read_text(encoding="utf-8")
lines = text.splitlines()
required = ["Mission Source","North-Star Outcome","Primary Beneficiary","Explicit Non-Goals","Safety And Privacy Boundaries","Evidence That Would Change The Mission","Owner-Review Cadence","Lock Receipt","Negative invariants (security)"]

def norm(title):
    return re.sub(r"\s+", " ", title.strip()).lower()

sections, current = {}, None
for line in lines:
    m = re.match(r"^##\s+(.+?)\s*$", line)
    if m:
        current = m.group(1).strip()
        sections.setdefault(norm(current), {"title": current, "body": []})
    elif current is not None:
        sections[norm(current)]["body"].append(line)

def body(title):
    return list(sections.get(norm(title), {}).get("body", []))

def section_hash(title):
    kept = [line.rstrip() for line in body(title) if not re.search(r"<!--\s*section[_-]hash:", line, re.I)]
    while kept and kept[0] == "":
        kept.pop(0)
    while kept and kept[-1] == "":
        kept.pop()
    return hashlib.sha256(("\n".join(kept) + "\n").encode()).hexdigest()

missing_sections = [title for title in required if norm(title) not in sections]
hash_entries = re.findall(r"<!--\s*section[_-]hash:\s*(.+?)\s+(?:sha256:)?([0-9a-fA-F]{64})\s*-->", text, re.I)
hash_mismatches = []
for title, observed in hash_entries:
    title = title.strip()
    if norm(title) not in sections:
        hash_mismatches.append({"section": title, "reason": "missing_section"})
    else:
        expected = section_hash(title)
        if expected.lower() != observed.lower():
            hash_mismatches.append({"section": title, "expected": f"sha256:{expected}", "observed": f"sha256:{observed.lower()}"})

def extract_pointers(section_lines):
    found = []
    for raw in section_lines:
        line = raw.strip()
        if not line or line.startswith(("#", "<!--")):
            continue
        local = re.findall(r"\[[^\]]+\]\(([^)]+)\)", line) + re.findall(r"`([^`]+)`", line)
        if not local:
            value = re.sub(r"^[-*]\s*", "", line)
            value = value.split(":", 1)[1].strip() if ":" in value else value
            if re.search(r"(^/|^\./|^\../|[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)", value):
                local.append(value)
        found.extend(local)
    clean = []
    for pointer in found:
        pointer = pointer.strip().strip("\"'")
        if pointer and pointer.lower() not in {"none", "n/a", "not_applicable"} and not re.match(r"^[a-z]+://", pointer) and not pointer.startswith("sha256:"):
            clean.append(pointer)
    return clean

substrate_body = body("Substrate inventory")
substrate_pointers = extract_pointers(substrate_body) if substrate_body else []
substrate_missing = []
for pointer in substrate_pointers:
    p = Path(pointer).expanduser()
    candidates = [p] if p.is_absolute() else [mission.parent / p, root / p, Path.cwd() / p]
    if not any(candidate.exists() for candidate in candidates):
        substrate_missing.append(pointer)

neg_body = [line.strip() for line in body("Negative invariants (security)") if line.strip() and not line.strip().startswith("<!--")]
blocked_states = []
for raw in lines:
    m = re.match(r"^(?:[-*]\s*)?(blocked[_ -]?readiness|blocked[_ -]?state|readiness)\s*[:=]\s*(.+)$", raw.strip(), re.I)
    if m and re.search(r"(blocked|missing|halt|hold|not_ready)", m.group(2), re.I):
        blocked_states.append(m.group(2).strip())

required_status = "pass" if not missing_sections else "fail"
hash_status = "skip" if not hash_entries else ("pass" if not hash_mismatches else "fail")
substrate_status = "skip" if not substrate_body else ("pass" if substrate_pointers and not substrate_missing else "fail")
negative_status = "pass" if neg_body else "fail"
blockers = [f"missing_required_section:{title}" for title in missing_sections]
blockers += [f"section_hash_mismatch:{item['section']}" for item in hash_mismatches]
blockers += [f"substrate_inventory_unresolved:{item}" for item in substrate_missing]
if substrate_body and not substrate_pointers:
    blockers.append("substrate_inventory_empty")
if negative_status == "fail":
    blockers.append("negative_invariants_empty")
blockers += [f"blocked_readiness:{item}" for item in blocked_states]
verdict = "blocked" if blockers else ("incomplete" if "skip" in {hash_status, substrate_status} else "ready")
lock_match = re.search(r"(?m)^lock_hash:\s*((?:sha256:)?[0-9a-fA-F]{64})\s*$", text)

print(json.dumps({
    "schema_version": version,
    "command": command,
    "ts": D.datetime.now(D.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "mission_md_path": str(mission),
    "checks": {
        "required_sections_present": required_status,
        "section_hashes_match": hash_status,
        "substrate_inventory_resolves": substrate_status,
        "negative_invariants_non_empty": negative_status,
        "blocked_readiness_states": blocked_states
    },
    "verdict": verdict,
    "blockers": blockers,
    "lock_hash_observed": lock_match.group(1) if lock_match else None,
    "details": {
        "required_sections": required,
        "missing_sections": missing_sections,
        "section_hash_mismatches": hash_mismatches,
        "substrate_pointers": substrate_pointers,
        "substrate_unresolved": substrate_missing
    }
}, sort_keys=True))
PY

verdict="$(jq -r '.verdict' "$TMP")"
if [[ "$QUIET" -eq 0 && "$JSON_OUT" -eq 1 ]]; then
  cat "$TMP"
elif [[ "$QUIET" -eq 0 ]]; then
  jq -r '"verdict=\(.verdict) blockers=\(.blockers|length) mission=\(.mission_md_path)"' "$TMP"
fi
[[ "$verdict" != "blocked" ]]
