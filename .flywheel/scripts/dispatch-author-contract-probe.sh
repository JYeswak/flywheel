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

SCAFFOLD_SCHEMA_VERSION="dispatch-author-contract-probe/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/dispatch-author-contract-probe-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: dispatch-author-contract-probe.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "dispatch-author-contract-probe.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "dispatch-author-contract-probe.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"dispatch-author-contract-probe.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"dispatch-author-contract-probe.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"dispatch-author-contract-probe.sh doctor --json"}'
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
            && cli_emit_completion_bash "dispatch-author-contract-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "dispatch-author-contract-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # TODO(canonical-cli-scaffold): probe substrate this script depends on
  # (env vars, paths, external tools) and emit per-check status.
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
VERSION="dispatch-author-skill-routing-contract/v1"
MAX_SKILLS=10
JSON_OUT=0
QUIET=0
MODE=probe
DISPATCH_PATH=""

usage() {
  cat <<'USAGE'
usage: dispatch-author-contract-probe.sh [--json] [--quiet] [--max-skills N] --dispatch PATH
       dispatch-author-contract-probe.sh [--json] [--quiet] [--max-skills N] PATH
       dispatch-author-contract-probe.sh --info|--help|--examples [--json]
USAGE
}

info() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc --arg version "$VERSION" '{
      name:"dispatch-author-contract-probe",
      schema_version:$version,
      canonical_cli_flags:["--info","--help","--examples","--json","--quiet"],
      checks:["deterministic_class_merge","discovery_precedence","required_overlays","secret_value_bans","route_receipts_schema","prompt_budget_within_limit"],
      verdicts:["pass","partial","fail"]
    }'
  else
    printf '%s\n' \
      "name=dispatch-author-contract-probe" \
      "schema=$VERSION" \
      "verbs=--info,--help,--examples,--json,--quiet" \
      "verdicts=pass,partial,fail"
  fi
}

examples() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc '{examples:[
      "dispatch-author-contract-probe.sh --json /tmp/dispatch.md",
      "dispatch-author-contract-probe.sh --dispatch /tmp/dispatch.md --quiet",
      "dispatch-author-contract-probe.sh --max-skills 12 --json /tmp/dispatch.md"
    ]}'
  else
    printf '%s\n' \
      "dispatch-author-contract-probe.sh --json /tmp/dispatch.md" \
      "dispatch-author-contract-probe.sh --dispatch /tmp/dispatch.md --quiet" \
      "dispatch-author-contract-probe.sh --max-skills 12 --json /tmp/dispatch.md"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --max-skills) MAX_SKILLS="${2:?--max-skills requires N}"; shift 2 ;;
    --max-skills=*) MAX_SKILLS="${1#*=}"; shift ;;
    --dispatch|--file) DISPATCH_PATH="${2:?--dispatch requires PATH}"; shift 2 ;;
    --dispatch=*|--file=*) DISPATCH_PATH="${1#*=}"; shift ;;
    --info) MODE=info; shift ;;
    --examples) MODE=examples; shift ;;
    --help|-h) usage; exit 0 ;;
    --*) printf 'ERR unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    *) DISPATCH_PATH="$1"; shift ;;
  esac
done

case "$MODE" in
  info) info; exit 0 ;;
  examples) examples; exit 0 ;;
esac

[[ "$MAX_SKILLS" =~ ^[0-9]+$ ]] || { printf 'ERR --max-skills must be numeric\n' >&2; exit 2; }
[[ -n "$DISPATCH_PATH" && -r "$DISPATCH_PATH" ]] || { usage >&2; exit 2; }

BODY="$(cat "$DISPATCH_PATH")"
TMP_CHECKS="$(mktemp "${TMPDIR:-/tmp}/dispatch-author-contract-checks.XXXXXX")"
TMP_VIOLATIONS="$(mktemp "${TMPDIR:-/tmp}/dispatch-author-contract-violations.XXXXXX")"
trap 'rm -f "$TMP_CHECKS" "$TMP_VIOLATIONS"' EXIT
: >"$TMP_CHECKS"
: >"$TMP_VIOLATIONS"

has_fixed() { grep -Fqi -- "$1" <<<"$BODY"; }
has_regex() { grep -Eqi -- "$1" <<<"$BODY"; }
check() {
  jq -nc --arg name "$1" --arg status "$2" --arg detail "$3" \
    '{name:$name,status:$status,detail:$detail}' >>"$TMP_CHECKS"
}
violation() {
  jq -nc --arg code "$1" --arg severity "$2" --arg check "$3" \
    --arg detail "$4" --arg recommendation "$5" \
    '{code:$code,severity:$severity,check:$check,detail:$detail,recommendation:$recommendation}' >>"$TMP_VIOLATIONS"
}

if has_fixed "collision_policy=unresolved"; then
  check deterministic_class_merge fail "class collision is marked unresolved"
  violation "class_collision_unresolved" error deterministic_class_merge "collision_policy=unresolved" "run dispatch-skill-router-collision-resolver.sh and preserve its collision receipt"
elif has_fixed "dispatch_class_merge_order" && has_fixed "strictest_invariant_wins=true" && has_fixed "collision_policy=resolved"; then
  check deterministic_class_merge pass "merge order and resolved collision policy present"
else
  check deterministic_class_merge fail "missing merge order, resolved collision policy, or strictest-invariant marker"
  violation "deterministic_class_merge_missing" error deterministic_class_merge "required class-merge markers are missing" "add dispatch_class_merge_order, collision_policy=resolved, and strictest_invariant_wins=true"
fi

expected_precedence="exact:get_skill > local:SKILL.md-readable > semantic:socraticode > external:npx-skills-find-installable-only > fallback:rg-filesystem"
if has_fixed "$expected_precedence"; then
  check discovery_precedence pass "canonical precedence order present"
else
  check discovery_precedence fail "canonical precedence order missing or reversed"
  violation "discovery_precedence_invalid" error discovery_precedence "source precedence is not canonical" "use exact/local before semantic, external install-only, then rg fallback"
fi

missing_overlays=()
for token in canonical-cli-scoping readme-writing de-slopify simplify socraticode agent-mail agent-monitoring cost-attribution search-tool-routing-doctrine; do
  has_fixed "$token" || missing_overlays+=("$token")
done
if ((${#missing_overlays[@]} == 0)); then
  check required_overlays pass "universal and cross-cutting overlays represented"
else
  check required_overlays fail "missing required overlays"
  violation "required_overlay_missing" error required_overlays "one or more required overlay tokens are absent" "represent every universal and cross-cutting overlay with applied, alias, skip, or not-applicable receipt"
fi

secret_regex='(sk-ant-[A-Za-z0-9_-]{12,}|sk-[A-Za-z0-9_-]{20,}|xai-[A-Za-z0-9_-]{12,}|gh[pousr]_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|AIza[A-Za-z0-9_-]{35}|Bearer[[:space:]]+[A-Za-z0-9._-]{20,}|registration_token[=:][A-Za-z0-9._-]{16,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|eyJ[A-Za-z0-9_-]{20,})'
if ! has_fixed "secret_values_allowed=false"; then
  check secret_value_bans fail "secret_values_allowed=false marker missing"
  violation "secret_value_ban_missing" error secret_value_bans "packet does not declare secret values forbidden" "add secret_values_allowed=false"
elif has_regex "$secret_regex"; then
  check secret_value_bans fail "secret-shaped literal detected"
  violation "secret_value_literal_present" error secret_value_bans "packet contains a forbidden secret-shaped value" "replace literal values with secret class, key name, vault path, or redacted evidence"
else
  check secret_value_bans pass "secret-value ban present and no secret-shaped literal detected"
fi

missing_receipt=()
for token in route_receipt_schema_version skill_routing "skill_receipts[]" receipt_identity_key skill source action_taken policy_version evidence alias_of not_applicable_reason idempotency_key replay_detection_hash transaction_boundary receipt_completeness; do
  has_fixed "$token" || missing_receipt+=("$token")
done
if ((${#missing_receipt[@]} == 0)); then
  check route_receipts_schema pass "route receipt fields present"
else
  check route_receipts_schema fail "route receipt schema fields missing"
  violation "route_receipt_schema_malformed" error route_receipts_schema "one or more route receipt fields are absent" "include dispatch-author-route-receipt/v1 and Wave 1 dispatch-receipt identity fields"
fi

skill_count="$(awk -F: 'tolower($1)=="selected_skill_count"{gsub(/[[:space:]]/,"",$2); print $2}' "$DISPATCH_PATH" | tail -n 1)"
[[ "$skill_count" =~ ^[0-9]+$ ]] || skill_count=0
if ! has_fixed "prompt_budget_policy"; then
  check prompt_budget_within_limit fail "prompt budget policy missing"
  violation "prompt_budget_policy_missing" error prompt_budget_within_limit "packet lacks prompt budget policy" "add names-plus-one-line-why policy and excerpt cap"
elif (( skill_count > MAX_SKILLS )); then
  check prompt_budget_within_limit fail "selected skill count exceeds budget"
  violation "prompt_budget_exceeded" warn prompt_budget_within_limit "selected skill count exceeds max-skills" "prune secondary excerpts to paths and keep only risk-bearing excerpts"
else
  check prompt_budget_within_limit pass "prompt budget policy present and skill count within limit"
fi

checks_json="$(jq -s 'map({(.name): {status:.status, detail:.detail}}) | add' "$TMP_CHECKS")"
violations_json="$(jq -s '.' "$TMP_VIOLATIONS")"
if jq -e 'any(.[]; .severity == "error")' >/dev/null <<<"$violations_json"; then
  verdict=fail
elif jq -e 'any(.[]; .severity == "warn")' >/dev/null <<<"$violations_json"; then
  verdict=partial
else
  verdict=pass
fi

payload="$(jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg path "$DISPATCH_PATH" --arg schema "$VERSION" --arg verdict "$verdict" \
  --argjson checks "$checks_json" --argjson violations "$violations_json" \
  '{schema_version:$schema,ts:$ts,dispatch_path:$path,checks:$checks,verdict:$verdict,violations:$violations}')"

if [[ "$QUIET" -eq 0 ]]; then
  if [[ "$JSON_OUT" -eq 1 || "$MODE" == probe ]]; then
    printf '%s\n' "$payload"
  else
    jq -r '"verdict=\(.verdict) violations=\(.violations|length)"' <<<"$payload"
  fi
fi

[[ "$verdict" != fail ]]
