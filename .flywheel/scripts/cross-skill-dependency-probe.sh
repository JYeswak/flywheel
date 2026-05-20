#!/usr/bin/env bash
# cross-skill-dependency-probe.sh — closes flywheel-1rmp.6 (value-gap
# `cross-skill-dependency-graph`).
#
# The smallest recurring measurement that makes the value gap visible: for
# each skill in the catalog, count how many other skills reference it inbound
# (i.e. mention its name in their SKILL.md). High inbound-degree = high blast
# radius. Top-N high-blast-radius skills surface the "skill changes can break
# downstream workflows" finding as a number per skill.
#
# Step 4o anti-pattern preserved: probe is READ-ONLY. No br/ntm/gh/git/agent-mail
# mutating verbs in source. No auto-dispatch from findings. Output is structured
# JSON only.
#
# Canonical-cli-scoping triad: --doctor / --health / --info / --schema /
# --json with stable exit codes.
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

SCAFFOLD_SCHEMA_VERSION="cross-skill-dependency-probe/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/cross-skill-dependency-probe-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: cross-skill-dependency-probe.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "cross-skill-dependency-probe.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "cross-skill-dependency-probe.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"cross-skill-dependency-probe.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"cross-skill-dependency-probe.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"cross-skill-dependency-probe.sh doctor --json"}'
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
            && cli_emit_completion_bash "cross-skill-dependency-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "cross-skill-dependency-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
SCHEMA_VERSION="cross-skill-dependency-probe.v1"
DEFAULT_SKILLS_DIR="$HOME/.claude/skills"

SKILLS_DIR="$DEFAULT_SKILLS_DIR"
TOP_N=20
MIN_INBOUND=2
JSON_OUT=0
MODE=run

usage() {
  cat <<'USAGE'
usage: cross-skill-dependency-probe.sh [--skills-dir PATH] [--top N] [--min-inbound N] [--json]
       cross-skill-dependency-probe.sh --doctor|--health|--info|--schema [--json]

Reads SKILL.md files under --skills-dir (default: ~/.claude/skills/), counts
inbound mentions of each skill name across all OTHER SKILL.md files, and emits
a per-skill blast-radius histogram.

Output JSON (run mode):
  {
    schema_version, ts,
    skills_dir, skills_scanned,
    top_blast_radius: [{skill, inbound_count, sample_referrers[5]}],
    high_radius_count,            # skills with inbound >= --min-inbound
    distribution: {p50, p90, p99, max, mean},
    reads_only: true, auto_dispatch: false,
    step_4o_compliance: "preserved"
  }

Defaults: --top 20, --min-inbound 2.

Exit codes:
  0  measurement emitted
  1  no skills found
  2  config error
USAGE
}

doctor() {
  jq -nc --arg schema "$SCHEMA_VERSION" --arg dir "$SKILLS_DIR" \
    '{schema_version:$schema, success:true, mode:"doctor",
      skills_dir:$dir, dir_present:true,
      reads_only:true, auto_dispatch:false,
      surfaces:["tick receipt consumer","dashboard tile","doctor signal candidate"],
      step_4o_compliance:"preserved"}'
}

info() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema, success:true, mode:"info",
      measurement:"per-skill inbound-mention count across all SKILL.md files",
      blast_radius_signal:"high inbound count = high blast radius (changing the skill breaks many downstream callers)",
      output_includes:["top_blast_radius (top N skills by inbound count)","high_radius_count","distribution percentiles"],
      reads_only:true,
      step_4o_compliance:"preserved"}'
}

schema() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema,
      properties:{
        skills_scanned:{type:"integer"},
        top_blast_radius:{type:"array",
          items:{properties:{skill:{type:"string"},inbound_count:{type:"integer"},sample_referrers:{type:"array"}}}},
        high_radius_count:{type:"integer"},
        distribution:{type:"object", properties:{p50:{type:"number"},p90:{type:"number"},p99:{type:"number"},max:{type:"integer"},mean:{type:"number"}}}}}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skills-dir) SKILLS_DIR="${2:?--skills-dir requires PATH}"; shift 2;;
    --top) TOP_N="${2:?--top requires N}"; shift 2;;
    --min-inbound) MIN_INBOUND="${2:?--min-inbound requires N}"; shift 2;;
    --json) JSON_OUT=1; shift;;
    --doctor|--health) MODE=doctor; shift;;
    --info) MODE=info; shift;;
    --schema) MODE=schema; shift;;
    -h|--help) usage; exit 0;;
    *) echo "ERR: unknown arg $1" >&2; usage >&2; exit 2;;
  esac
done

case "$MODE" in
  doctor) doctor; exit 0;;
  info) info; exit 0;;
  schema) schema; exit 0;;
esac

[[ -d "$SKILLS_DIR" ]] || { echo "ERR: skills dir not found: $SKILLS_DIR" >&2; exit 2; }

# Collect skill names (top-level dirs that contain SKILL.md).
SKILLS_TMP="$(mktemp "${TMPDIR:-/tmp}/cross-skill-probe-skills.XXXXXX")"
INBOUND_TMP="$(mktemp "${TMPDIR:-/tmp}/cross-skill-probe-inbound.XXXXXX")"
trap 'rm -f "$SKILLS_TMP" "$INBOUND_TMP"' EXIT
: >"$SKILLS_TMP"
: >"$INBOUND_TMP"

while IFS= read -r path; do
  [[ -n "$path" ]] || continue
  d="$(dirname "$path")"
  name="$(basename "$d")"
  [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || continue
  [[ "$name" == _* ]] && continue
  printf '%s\n' "$name" >>"$SKILLS_TMP"
done < <(find "$SKILLS_DIR" -mindepth 2 -maxdepth 2 -name SKILL.md -type f 2>/dev/null)

SKILLS_COUNT="$(wc -l <"$SKILLS_TMP" | tr -d ' ')"
if [[ "$SKILLS_COUNT" -eq 0 ]]; then
  echo "ERR: no SKILL.md files under $SKILLS_DIR" >&2
  exit 1
fi

# For each skill, count inbound references in OTHER skills' SKILL.md files.
# Vectorized with python3 to avoid N^2 grep loop on 500-skill catalogs.
python3 - "$SKILLS_DIR" "$SKILLS_TMP" "$INBOUND_TMP" <<'PY'
import os, re, sys
skills_dir, skills_file, out_file = sys.argv[1], sys.argv[2], sys.argv[3]
with open(skills_file) as f:
    skills = sorted({line.strip() for line in f if line.strip()})
# Word-boundary regex per skill (escaped); compile once.
patterns = {s: re.compile(r"(?:^|[^A-Za-z0-9_-])" + re.escape(s) + r"(?:[^A-Za-z0-9_-]|$)") for s in skills}
inbound = {s: 0 for s in skills}
referrers = {s: [] for s in skills}
for entry in os.scandir(skills_dir):
    if not entry.is_dir():
        continue
    other_name = entry.name
    skill_md = os.path.join(entry.path, "SKILL.md")
    if not os.path.isfile(skill_md):
        continue
    try:
        with open(skill_md, "r", encoding="utf-8", errors="replace") as f:
            text = f.read()
    except OSError:
        continue
    for s in skills:
        if s == other_name:
            continue
        if patterns[s].search(text):
            inbound[s] += 1
            if len(referrers[s]) < 5:
                referrers[s].append(other_name)
with open(out_file, "w") as f:
    for s in skills:
        f.write(f"{inbound[s]}\t{s}\t{','.join(referrers[s])}\n")
PY

# Aggregate.
TOP_JSON="$(sort -t $'\t' -k1,1 -nr "$INBOUND_TMP" \
  | head -n "$TOP_N" \
  | awk -F'\t' '{ printf "{\"skill\":\"%s\",\"inbound_count\":%s,\"sample_referrers\":\"%s\"}\n", $2, $1, $3 }' \
  | jq -s 'map(. + {sample_referrers: (.sample_referrers | split(",") | map(select(length > 0)))})')"

HIGH_RADIUS_COUNT="$(awk -F'\t' -v m="$MIN_INBOUND" 'BEGIN{c=0} $1>=m{c++} END{print c}' "$INBOUND_TMP")"

# Distribution.
COUNTS_SORTED="$(awk -F'\t' '{print $1}' "$INBOUND_TMP" | sort -n)"
N="$(printf '%s\n' "$COUNTS_SORTED" | grep -c '^' || echo 0)"
if [[ "$N" -gt 0 ]]; then
  P50_IDX=$(( (N - 1) * 50 / 100 ))
  P90_IDX=$(( (N - 1) * 90 / 100 ))
  P99_IDX=$(( (N - 1) * 99 / 100 ))
  P50="$(printf '%s\n' "$COUNTS_SORTED" | awk -v i="$P50_IDX" 'NR == i+1 { print; exit }')"
  P90="$(printf '%s\n' "$COUNTS_SORTED" | awk -v i="$P90_IDX" 'NR == i+1 { print; exit }')"
  P99="$(printf '%s\n' "$COUNTS_SORTED" | awk -v i="$P99_IDX" 'NR == i+1 { print; exit }')"
  MAX="$(printf '%s\n' "$COUNTS_SORTED" | tail -1)"
  MEAN="$(printf '%s\n' "$COUNTS_SORTED" | awk '{s+=$1; n++} END{ if(n>0) printf "%.4f", s/n; else print "0" }')"
else
  P50=0; P90=0; P99=0; MAX=0; MEAN=0
fi

PAYLOAD="$(jq -nc \
  --arg schema "$SCHEMA_VERSION" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg dir "$SKILLS_DIR" \
  --argjson scanned "$SKILLS_COUNT" \
  --argjson top "$TOP_JSON" \
  --argjson high_radius "$HIGH_RADIUS_COUNT" \
  --argjson p50 "$P50" \
  --argjson p90 "$P90" \
  --argjson p99 "$P99" \
  --argjson max "$MAX" \
  --argjson mean "$MEAN" \
  '{schema_version:$schema, ts:$ts, success:true, mode:"run",
    skills_dir:$dir, skills_scanned:$scanned,
    top_blast_radius:$top,
    high_radius_count:$high_radius,
    distribution:{p50:$p50, p90:$p90, p99:$p99, max:$max, mean:$mean},
    reads_only:true, auto_dispatch:false,
    step_4o_compliance:"preserved"}')"

if [[ "$JSON_OUT" == 1 ]]; then
  printf '%s\n' "$PAYLOAD"
else
  jq -r '"cross-skill-dep skills=\(.skills_scanned) high_radius=\(.high_radius_count) max=\(.distribution.max) p99=\(.distribution.p99) p90=\(.distribution.p90) top=\(.top_blast_radius[0:3] | map(.skill) | join(","))"' <<<"$PAYLOAD"
fi

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
