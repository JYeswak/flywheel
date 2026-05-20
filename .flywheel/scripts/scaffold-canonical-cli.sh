#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
# doctor-mode-tier: scaffolder (bead flywheel-ws02m apply spec
#   .flywheel/audit/flywheel-jloib.0b/apply-spec.md)
#
# scaffold-canonical-cli.sh — parametric scaffolder that takes any P0 surface
# and emits the canonical-cli + doctor-mode upgrade as a unified diff. Wraps
# (does not rewrite) the target's existing dispatch/main as `cmd_run` and
# prepends the canonical surface. TODO markers are bracketed so per-surface
# logic stays operator-fillable.
#
# Compresses ~3.5h of per-surface upgrade work into ~30-60min by handling the
# ~70% boilerplate portion. Surface-specific doctor / health / repair /
# validate / why logic stays as TODO markers for human/agent fill-in.
#
# Boundary:
#   - READ target script + inventory.jsonl + helper-lib (verifies presence)
#   - WRITE only to <target>.bak.scaffold-<UTC> (when --apply) and
#     <target>.scaffolded.tmp (intermediate before diff)
#   - REFUSE on jeff-stack paths (file upstream, don't patch)
#   - REFUSE on targets not in canonical inventory
#   - IDEMPOTENT: target with magic comment `# flywheel-cli-surface: true`
#     returns status=already_scaffolded with zero changes

set -euo pipefail

SCRIPT_VERSION="2026-05-10.1"
SCHEMA_VERSION="scaffold-canonical-cli/v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="${SCAFFOLD_REPO_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd -P)}"
# Normalize REPO_ROOT through pwd -P so env overrides under /tmp -> /private/tmp
# resolve identically to the target path's realpath. Without this, macOS's
# /var -> /private/var symlink causes the prefix-strip in `is_in_inventory`
# to fail and refuse legitimate targets as "uninventoried".
if [[ -d "$REPO_ROOT" ]]; then
  REPO_ROOT="$(cd "$REPO_ROOT" && pwd -P)"
fi
HELPER_LIB="${SCAFFOLD_HELPER_LIB:-$REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
INVENTORY="${SCAFFOLD_INVENTORY:-$REPO_ROOT/.flywheel/audit/flywheel-cli-inventory/inventory.jsonl}"
RUNS_LOG="${SCAFFOLD_RUNS_LOG:-$REPO_ROOT/.flywheel/state/scaffold-runs.jsonl}"
TESTS_DIR="${SCAFFOLD_TESTS_DIR:-$REPO_ROOT/tests}"
JEFF_STACK_PREFIXES_DEFAULT="ntm,beads_rust,frankensqlite,frankenagent,beads-for"

# ---------- helpers ----------

iso_now() { date -u +'%Y-%m-%dT%H:%M:%SZ'; }
err() { printf '%s\n' "$*" >&2; }
require() { command -v "$1" >/dev/null || { err "missing dependency: $1"; exit 64; }; }
require jq
require diff

usage() {
  cat <<'EOF'
usage: scaffold-canonical-cli.sh <script_path> [--dry-run|--apply] [--idempotency-key KEY]
                                 [--inventory PATH] [--helper-lib PATH] [--runs-log PATH]
                                 [--no-test-scaffold] [--allow-uninventoried] [--json]

       scaffold-canonical-cli.sh --info [--json]
       scaffold-canonical-cli.sh --schema [<surface>]
       scaffold-canonical-cli.sh --examples [--json]
       scaffold-canonical-cli.sh --help

Positional:
  <script_path>     target script to scaffold (e.g. .flywheel/scripts/foo.sh)

Modes:
  --dry-run         (default) emit unified diff + JSON receipt, mutate nothing
  --apply           write the scaffolded script in place + backup; requires
                    --idempotency-key KEY

Options:
  --idempotency-key KEY    (required for --apply) opaque token recorded in
                           the scaffold-runs.jsonl receipt for replay safety
  --inventory PATH         override inventory.jsonl path
  --helper-lib PATH        override canonical-cli-helpers.sh path (presence
                           is verified; lib is referenced via $REPO_ROOT)
  --runs-log PATH          override scaffold-runs.jsonl path
  --no-test-scaffold       skip emitting tests/<name>-canonical-cli.sh
  --allow-uninventoried    bypass the "must be in inventory.jsonl" refusal
                           (use only for known-clean fixtures)

Exit codes:
  0  success or already_scaffolded
  1  internal error
  3  --apply without --idempotency-key (canonical refusal)
  64 usage error
  65 IO error (target missing/unreadable, helper lib missing)
  66 refused (target outside canonical inventory or jeff-stack path)
EOF
}

emit_info() {
  jq -nc \
    --arg sv "$SCHEMA_VERSION" \
    --arg version "$SCRIPT_VERSION" \
    --arg name "scaffold-canonical-cli.sh" \
    --arg repo_root "$REPO_ROOT" \
    --arg helper_lib "$HELPER_LIB" \
    --arg inventory "$INVENTORY" \
    --arg runs_log "$RUNS_LOG" \
    --arg tests_dir "$TESTS_DIR" \
    '{
      schema_version: $sv,
      command: "info",
      name: $name,
      version: $version,
      paths: {
        repo_root: $repo_root,
        helper_lib: $helper_lib,
        inventory: $inventory,
        runs_log: $runs_log,
        tests_dir: $tests_dir
      },
      dependencies: ["bash","jq","diff"],
      mutation_requires: "--apply --idempotency-key KEY",
      modes: ["--dry-run","--apply","--info","--schema","--examples"],
      idempotent_when: "target has magic comment # flywheel-cli-surface: true",
      refusal_classes: ["uninventoried_target","jeff_stack_target","missing_helper_lib","apply_without_idempotency_key"]
    }'
}

emit_schema() {
  local surface="${1:-default}"
  jq -nc \
    --arg sv "$SCHEMA_VERSION" \
    --arg surface "$surface" \
    '{
      schema_version: $sv,
      command: "schema",
      surface: $surface,
      receipt_keys: ["ts","target","mode","idempotency_key","before_lines","after_lines","lines_added_by_scaffolder","todo_count","test_scaffolded","status","helper_lib_sha","scaffolder_sha"],
      dry_run_envelope_keys: ["schema_version","command","status","mode","target","unified_diff_path","todo_count","before_lines","after_lines","scaffold_lines_added","test_scaffolded","reason","receipt"],
      already_scaffolded_keys: ["schema_version","command","status","mode","target","reason"],
      refusal_keys: ["schema_version","command","status","reason","target"]
    }'
}

emit_examples() {
  jq -nc \
    --arg sv "$SCHEMA_VERSION" \
    '{
      schema_version: $sv,
      command: "examples",
      examples: [
        {name:"dry-run scaffold",
         invocation:"scaffold-canonical-cli.sh .flywheel/scripts/callback-fix-bead-opener.sh --dry-run --json",
         purpose:"see the diff + JSON receipt without mutating the target"},
        {name:"apply with idempotency key",
         invocation:"scaffold-canonical-cli.sh .flywheel/scripts/callback-fix-bead-opener.sh --apply --idempotency-key=$(date -u +%Y%m%dT%H%M%SZ)-bead-XXX --json",
         purpose:"write the scaffolded script + backup; record receipt to scaffold-runs.jsonl"},
        {name:"re-run on already-scaffolded target",
         invocation:"scaffold-canonical-cli.sh .flywheel/scripts/daily-report-enabled-repos.sh --dry-run --json",
         purpose:"returns status=already_scaffolded with zero changes (idempotent)"},
        {name:"info envelope",
         invocation:"scaffold-canonical-cli.sh --info --json",
         purpose:"version, paths, dependencies, refusal classes"}
      ]
    }'
}

# ---------- refusal helpers ----------

refuse_envelope() {
  local reason="$1" target="$2"
  jq -nc \
    --arg sv "$SCHEMA_VERSION" \
    --arg reason "$reason" \
    --arg target "$target" \
    '{schema_version:$sv,command:"scaffold",status:"refused",reason:$reason,target:$target}'
}

# ---------- inventory checks ----------

is_in_inventory() {
  local target="$1"
  [[ -s "$INVENTORY" ]] || return 1
  # Match by .path field; targets are stored relative to repo root
  local rel="${target#"$REPO_ROOT"/}"
  jq -e --arg p "$rel" 'select(.path == $p)' "$INVENTORY" >/dev/null 2>&1
}

is_jeff_stack_path() {
  local target="$1"
  local rel="${target#"$REPO_ROOT"/}"
  IFS=',' read -r -a prefixes <<< "${SCAFFOLD_JEFF_STACK_PREFIXES:-$JEFF_STACK_PREFIXES_DEFAULT}"
  for p in "${prefixes[@]}"; do
    [[ -z "$p" ]] && continue
    if [[ "$rel" == *"/$p/"* ]] || [[ "$rel" == "$p/"* ]]; then
      return 0
    fi
  done
  return 1
}

# ---------- idempotency check ----------

is_already_scaffolded() {
  local target="$1"
  grep -q '^# flywheel-cli-surface: true' "$target" 2>/dev/null
}

# ---------- shebang guard (flywheel-e4lfb) ----------

# is_non_bash_shebang <target> — return 0 (true) when the target's
# shebang names a non-bash interpreter. Catches Python/Perl/Node/Ruby
# scripts that carry a misleading .sh extension. The bash scaffold
# corrupts these because it appends bash-syntax boilerplate.
#
# Recognized bash variants: bash, sh (POSIX shell), env bash.
# Returns 1 (false) when shebang is missing or names a bash variant.
is_non_bash_shebang() {
  local target="$1"
  local shebang
  shebang="$(head -1 "$target" 2>/dev/null)"
  case "$shebang" in
    "#!"*bash|"#!"*bash" "*|"#!"*"/sh"|"#!"*"/sh "*|"#!/usr/bin/env bash"*|"#!/usr/bin/env sh"*)
      return 1 ;;
    "#!"*)
      return 0 ;;
    *)
      return 1 ;;
  esac
}

# Echo the recognized interpreter name for diagnostic output.
detect_shebang_interpreter() {
  local target="$1"
  local shebang
  shebang="$(head -1 "$target" 2>/dev/null)"
  case "$shebang" in
    *python3*) echo "python3" ;;
    *python*)  echo "python" ;;
    *perl*)    echo "perl" ;;
    *node*)    echo "node" ;;
    *ruby*)    echo "ruby" ;;
    *)         echo "${shebang#"#!"}" ;;
  esac
}

# ---------- verb-collision detection (flywheel-sacan) ----------
#
# When the target has its own case-statement handling canonical verbs
# (validate|why|doctor|health|repair|audit), the scaffold's intercept
# would hijack those verbs. The fix is a flag-based bypass: scan argv
# for per-target flags, and if any are present, defer to cmd_run.
#
# Surfaced by 1fk5f.3 (dispatch-trigger-gated-precheck) and 1fk5f.6
# (ntm-coordinator-shadow) where I hand-edited the intercept post-scaffold.
# This makes the fix automatic at scaffold time.

# Returns the list of canonical verbs the target's case-statement already
# handles (newline-separated). Empty if no collision.
detect_colliding_verbs() {
  local target="$1"
  # Match `^<whitespace>VERB)` in the target source (case-arm pattern).
  # Strip whitespace + trailing paren. Filter to canonical verbs.
  local verb canonical=("validate" "why" "doctor" "health" "repair" "audit" "quickstart")
  local found=()
  for verb in "${canonical[@]}"; do
    if grep -qE "^[[:space:]]*${verb}\)" "$target" 2>/dev/null; then
      found+=("$verb")
    fi
  done
  printf '%s\n' "${found[@]}"
}

# Returns the list of canonical introspection flags the target's own
# case-statement already handles (newline-separated). When the target has
# its own `--info`, `--schema`, or `--examples` case-arm, the scaffold's
# intercept at line 552 would hijack it. The flag-collision detection
# lets the scaffold-emit step omit those flags from the intercept so
# the target's handler still runs.
#
# Surfaced by flywheel-wzjo9.1.7 (flywheel-loop wave-2.0a-g) where the
# target had its own `--info` emitting a different envelope shape. The
# verb-collision detection (above) caught the verbs but missed the flags.
#
# Bead: flywheel-efojs
#
# Match policy: the canonical flag must appear in a case-arm context —
# either as a standalone arm pattern (`--info)`) or as one alternative
# in a combined arm (`-h|--info)` or `--info|--json)`). Prose mentions
# (e.g., "Run --info | jq") are NOT case-arms and must not trigger a
# false-positive.
detect_colliding_flags() {
  local target="$1"
  # Canonical introspection flags the scaffold's intercept unconditionally
  # claims. `--help` / `-h` are intentionally EXCLUDED — every target script
  # already handles them with a usage-printer; that's not a semantic conflict
  # because the scaffold's `--help` also prints a usage block. The semantic
  # conflict is METADATA-EMITTERS (`--info`, `--schema`, `--examples`):
  # target emits one shape, scaffold emits a different shape.
  local canonical_flags=("--info" "--schema" "--examples")
  local flag found=()
  for flag in "${canonical_flags[@]}"; do
    # Anchor to case-arm contexts only. Two acceptable shapes:
    #   1) start-of-line / leading whitespace + `--flag` + optional space + `)` or `|`
    #   2) `|--flag` + optional space + `)` or `|`  (mid-arm alternative)
    # The trailing `[)|]` requirement is what discriminates case-arm from prose.
    if grep -qE -- "(^[[:space:]]*${flag}[[:space:]]*[)|]|\\|${flag}[[:space:]]*[)|])" "$target" 2>/dev/null; then
      found+=("$flag")
    fi
  done
  printf '%s\n' "${found[@]}"
}

# Returns the list of per-target --flags found in the target source that
# are NOT in the canonical scaffold flag set (newline-separated). The
# canonical flag set excludes scaffold-introspection flags. The returned
# list is the candidate "bypass flag" list. Returns 0 even when no flags
# are found (do not let `set -e` propagate grep's "no match" rc=1).
detect_per_target_flags() {
  local target="$1"
  local canonical_flags="--apply,--dry-run,--idempotency-key,--info,--schema,--examples,--help,--scope,--json,--rule,--root,--force,--allow-uninventoried,--no-test-scaffold,--inventory,--helper-lib,--runs-log,--tail,--tests-dir,--row-json,--surface,--config,--scan-all"
  local jq_noise="--arg,--argjson,--rawfile,--slurpfile,--null-input"
  local skip="$canonical_flags,$jq_noise"
  local raw flag
  # `|| true` keeps the pipeline rc=0 when grep finds no matches.
  raw="$(grep -ohE -- '--[a-z][a-z0-9-]+' "$target" 2>/dev/null | sort -u || true)"
  while IFS= read -r flag; do
    [[ -z "$flag" ]] && continue
    case ",$skip," in
      *",$flag,"*) continue ;;
    esac
    printf '%s\n' "$flag"
  done <<<"$raw"
  return 0
}

# ---------- scaffolder body ----------

# emit the canonical-cli block as a single heredoc, with the target name
# and basename interpolated. Writes to stdout. Includes:
#   - magic comment + metadata header
#   - source helper-lib line (with REPO_ROOT auto-resolution)
#   - usage() with canonical structure
#   - emit_info / emit_schema / emit_examples (helper-lib-backed)
#   - emit_topic_help (helper-lib-backed)
#   - cmd_doctor / cmd_health / cmd_repair / cmd_validate / cmd_audit /
#     cmd_why stubs with TODO markers
#   - new main dispatcher that routes default to cmd_run (the wrapped
#     original)
emit_canonical_block() {
  local target_basename="$1"
  local schema_prefix="${target_basename%.sh}"
  # flywheel-sacan: comma-separated list of per-target flags that should
  # cause the scaffold intercept to defer to cmd_run. Empty when no verb
  # collision is detected.
  local bypass_flags="${2:-}"
  # flywheel-efojs: comma-separated list of canonical introspection flags
  # the TARGET already handles (`--info`, `--schema`, `--examples`).
  # When set, those flags are OMITTED from the scaffold intercept so the
  # target's own handler runs instead of the scaffold's metadata emitter.
  local colliding_flags="${3:-}"
  # Pre-compute bypass injection text outside the heredoc so we can
  # interpolate as a single substitution. Nested `${var//pat/repl}` inside
  # the heredoc confuses bash's parser; do it here instead.
  local _bypass_header=""
  local _bypass_loop=""
  if [[ -n "$bypass_flags" ]]; then
    _bypass_header=$'\n#\n# VERB COLLISION BYPASS (flywheel-sacan): the target\'s own argparse\n# already handles canonical verbs (doctor|health|repair|validate|...).\n# When any of the per-target flags below are present in argv, the\n# intercept yields and cmd_run handles the per-bead path unchanged.\n# Per-target bypass flags: '"$bypass_flags"
    local _bypass_pattern="${bypass_flags//,/|}"
    _bypass_loop=$'\n  local _a\n  for _a in "$@"; do\n    case "$_a" in '"$_bypass_pattern"$') return 1 ;; esac\n  done'
  fi
  # flywheel-efojs: build the canonical-introspection case-arm pattern.
  # Default = `--info|--schema|--examples`. When the target has a colliding
  # arm for one of these flags, drop it from the intercept so target's
  # handler runs. The trailing `)` is appended by the heredoc.
  #
  # _intro_flags_line is the FULL `    <arm>) return 0 ;;` line — empty
  # when all three flags collide (case-arm omitted entirely so we never
  # emit `) return 0 ;;` which is a bash syntax error).
  local _intro_flags_arm="--info|--schema|--examples"
  local _intro_flags_line="    --info|--schema|--examples) return 0 ;;"
  local _flag_collision_header=""
  if [[ -n "$colliding_flags" ]]; then
    local _cf
    IFS=',' read -ra _cf_arr <<<"$colliding_flags"
    for _cf in "${_cf_arr[@]}"; do
      # Strip the colliding flag from the alternation. Three positions:
      # `--info|...` (leading), `...|--info|...` (middle), `...|--info` (trailing).
      _intro_flags_arm="${_intro_flags_arm//${_cf}\|/}"
      _intro_flags_arm="${_intro_flags_arm//\|${_cf}/}"
      _intro_flags_arm="${_intro_flags_arm//${_cf}/}"
    done
    if [[ -n "$_intro_flags_arm" ]]; then
      _intro_flags_line="    ${_intro_flags_arm}) return 0 ;;"
    else
      _intro_flags_line=""
    fi
    _flag_collision_header=$'\n#\n# FLAG COLLISION BYPASS (flywheel-efojs): target has its own handler\n# for canonical introspection flag(s) ['"$colliding_flags"$']. The scaffold\n# intercept OMITS those flags so the target\'s handler runs instead of\n# the scaffold\'s metadata emitter. Per flywheel-wzjo9.1.7 worker note.'
  fi
  cat <<EOF

# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (TODO markers in stubs need fill-in)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block is APPENDED by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved as \`cmd_run\` (the new main routes
# default invocation through cmd_run for backward compat). Surface-
# specific logic stays as TODO markers — see grep '# TODO(canonical-cli-scaffold)'.

_SCAFFOLD_REPO_ROOT="\${_SCAFFOLD_REPO_ROOT:-\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="\${_SCAFFOLD_HELPER_LIB:-\$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "\$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "\$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="${schema_prefix}/v1"
SCAFFOLD_AUDIT_LOG="\${SCAFFOLD_AUDIT_LOG:-\$HOME/.local/state/flywheel/${schema_prefix}-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: ${target_basename} [SUBCOMMAND] [OPTIONS]

Backward-compatible run mode: default invocation routes to the original
top-level logic (now exposed as \`cmd_run\`).

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
    jq -nc --arg sv "\$SCAFFOLD_SCHEMA_VERSION" --arg name "${target_basename}" \\
      '{schema_version:\$sv,command:"info",name:\$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \\
    "${target_basename}" \\
    "scaffolded-v0" \\
    "\$SCAFFOLD_SCHEMA_VERSION" \\
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \\
    "SCAFFOLD_AUDIT_LOG" \\
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="\$(jq -nc '{name:"default run",invocation:"${target_basename}",purpose:"backward-compatible original behavior"}'
)"\$'\\n'"\$(jq -nc '{name:"doctor",invocation:"${target_basename} doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "\$SCAFFOLD_SCHEMA_VERSION" "\$jsonl"
  else
    jq -nc --arg sv "\$SCAFFOLD_SCHEMA_VERSION" '{schema_version:\$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="\$(jq -nc '{step:1,action:"probe doctor",command:"${target_basename} doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "\$SCAFFOLD_SCHEMA_VERSION" "\$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "\$SCAFFOLD_SCHEMA_VERSION" '{schema_version:\$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="\${1:-default}"
  jq -nc --arg sv "\$SCAFFOLD_SCHEMA_VERSION" --arg surface "\$surface" \\
    '{schema_version:\$sv,command:"schema",surface:\$surface,note:"TODO(canonical-cli-scaffold): per-surface schema fill-in"}'
}

scaffold_emit_topic_help() {
  local topic="\${1:-}"
  case "\$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to cmd_run.\\n' ;;
    doctor)   printf 'topic: doctor — TODO(canonical-cli-scaffold): document doctor checks specific to this surface.\\n' ;;
    health)   printf 'topic: health — TODO(canonical-cli-scaffold): document health probes specific to this surface.\\n' ;;
    repair)   printf 'topic: repair — TODO(canonical-cli-scaffold): document repair scopes + idempotency contract.\\n' ;;
    validate) printf 'topic: validate — TODO(canonical-cli-scaffold): document validation subjects + contracts.\\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate\\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="\${1:-bash}"
  case "\$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \\
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \\
            && cli_emit_completion_bash "${target_basename%.sh}" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \\
            || printf '# helper lib missing — completion unavailable\\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \\
            && cli_emit_completion_zsh "${target_basename%.sh}" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \\
            || printf '# helper lib missing — completion unavailable\\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\\n' "\$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # TODO(canonical-cli-scaffold): probe substrate this script depends on
  # (env vars, paths, external tools) and emit per-check status.
  # Canonical pattern (per L4 lint rule — NEVER use \`[[ ]] && X || Y\`
  # as the last expression of a helper; use if/then/else/fi):
  #   if [[ -d "\$ROOT/.flywheel" ]]; then
  #     printf '{"check":"flywheel-dir","status":"pass"}\\n'
  #   else
  #     printf '{"check":"flywheel-dir","status":"fail"}\\n'
  #   fi
  jq -nc --arg sv "\$SCAFFOLD_SCHEMA_VERSION" --arg ts "\$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \\
    '{schema_version:\$sv,command:"doctor",ts:\$ts,status:"todo",checks:[],note:"TODO(canonical-cli-scaffold): fill in doctor checks"}'
}

scaffold_cmd_health() {
  # TODO(canonical-cli-scaffold): summarize last-run state from audit log.
  jq -nc --arg sv "\$SCAFFOLD_SCHEMA_VERSION" --arg ts "\$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \\
    '{schema_version:\$sv,command:"health",ts:\$ts,status:"todo",note:"TODO(canonical-cli-scaffold): fill in health probe from audit log"}'
}

scaffold_cmd_repair() {
  local scope="" mode="dry_run" idem_key=""
  while [[ \$# -gt 0 ]]; do
    case "\$1" in
      -h|--help) scaffold_emit_topic_help repair; return 0 ;;
      --scope) scope="\${2:-}"; shift 2 ;;
      --dry-run) mode="dry_run"; shift ;;
      --apply) mode="apply"; shift ;;
      --idempotency-key) idem_key="\${2:-}"; shift 2 ;;
      --idempotency-key=*) idem_key="\${1#--idempotency-key=}"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown repair arg %s\\n' "\$1" >&2; return 64 ;;
    esac
  done
  if [[ "\$mode" == "apply" && -z "\$idem_key" ]]; then
    if command -v cli_refuse_apply_without_idem_key >/dev/null; then
      cli_refuse_apply_without_idem_key "\$SCAFFOLD_SCHEMA_VERSION" "repair" "\$scope"
    else
      jq -nc --arg sv "\$SCAFFOLD_SCHEMA_VERSION" --arg scope "\$scope" \\
        '{schema_version:\$sv,command:"repair",status:"refused",mode:"apply",scope:\$scope,reason:"--apply requires --idempotency-key"}'
      exit 3
    fi
  fi
  # TODO(canonical-cli-scaffold): per-scope repair actions go here.
  jq -nc --arg sv "\$SCAFFOLD_SCHEMA_VERSION" --arg scope "\$scope" --arg mode "\$mode" --arg idem "\$idem_key" \\
    '{schema_version:\$sv,command:"repair",status:"todo",mode:\$mode,scope:\$scope,idempotency_key:\$idem,note:"TODO(canonical-cli-scaffold): fill in repair scope actions"}'
}

scaffold_cmd_validate() {
  # TODO(canonical-cli-scaffold): document validation subjects + contracts.
  jq -nc --arg sv "\$SCAFFOLD_SCHEMA_VERSION" \\
    '{schema_version:\$sv,command:"validate",status:"todo",note:"TODO(canonical-cli-scaffold): fill in per-subject validation"}'
}

scaffold_cmd_audit() {
  # TODO(canonical-cli-scaffold): tail audit log; emit recent rows.
  jq -nc --arg sv "\$SCAFFOLD_SCHEMA_VERSION" --arg log "\$SCAFFOLD_AUDIT_LOG" \\
    '{schema_version:\$sv,command:"audit",audit_log:\$log,status:"todo",note:"TODO(canonical-cli-scaffold): fill in audit tail"}'
}

scaffold_cmd_why() {
  local id="\${1:-}"
  if [[ -z "\$id" ]]; then
    printf 'ERR: why requires <id> argument\\n' >&2; return 64
  fi
  # TODO(canonical-cli-scaffold): explain why <id> is/isn't in scope.
  jq -nc --arg sv "\$SCAFFOLD_SCHEMA_VERSION" --arg id "\$id" \\
    '{schema_version:\$sv,command:"why",id:\$id,status:"todo",note:"TODO(canonical-cli-scaffold): fill in why-id semantics"}'
}

# ---------- scaffolded main dispatcher ----------

# When the scaffolder appends this block, it expects the target's original
# top-level main is renamed to \`cmd_run\` (or the original final
# \`main "\$@"\` line is replaced with this dispatcher). Default invocation
# falls through to the original logic for backward compat.
scaffold_main() {
  if [[ \$# -eq 0 ]]; then
    scaffold_usage; exit 0
  fi
  case "\$1" in
    -h|--help)    scaffold_usage; exit 0 ;;
    --info)       shift; scaffold_emit_info "\$@"; exit 0 ;;
    --schema)     shift; scaffold_emit_schema "\${1:-default}"; exit 0 ;;
    --examples)   shift; scaffold_emit_examples "\$@"; exit 0 ;;
    doctor)       shift; scaffold_cmd_doctor "\$@"; exit \$? ;;
    health)       shift; scaffold_cmd_health "\$@"; exit \$? ;;
    repair)       shift; scaffold_cmd_repair "\$@"; exit \$? ;;
    validate)     shift; scaffold_cmd_validate "\$@"; exit \$? ;;
    audit)        shift; scaffold_cmd_audit "\$@"; exit \$? ;;
    why)          shift; scaffold_cmd_why "\$@"; exit \$? ;;
    quickstart)   shift; scaffold_emit_quickstart "\$@"; exit 0 ;;
    help)         shift; scaffold_emit_topic_help "\${1:-}"; exit 0 ;;
    completion)   shift; scaffold_emit_completion "\${1:-bash}"; exit \$? ;;
    *)
      printf 'ERR: unknown canonical subcommand: %s\\n' "\$1" >&2
      scaffold_usage >&2
      exit 64 ;;
  esac
}

# Early-dispatch intercept: if argv[0] looks like a canonical subcommand
# or introspection flag, run the canonical surface and exit BEFORE the
# target's original arg parser sees the args. Works for both \`main "\$@"\`
# style and inline \`while [[ \$# -gt 0 ]]\` style targets.${_bypass_header}${_flag_collision_header}
_scaffold_is_canonical_arg() {${_bypass_loop}
  case "\${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
${_intro_flags_line}
    -h|--help) return 0 ;;
    help)
      # Intercept \`help <topic>\` and \`help --help\`; bare \`help\` could be
      # a legacy subcommand of the target so it falls through.
      case "\${2:-}" in run|doctor|health|repair|validate|audit|why|-h|--help) return 0 ;; esac
      return 1 ;;
    *) return 1 ;;
  esac
}

if [[ \$# -gt 0 ]] && _scaffold_is_canonical_arg "\$@"; then
  scaffold_main "\$@"
  exit \$?
fi
# ====== END canonical-cli scaffold ======
EOF
}

# emit the test scaffold for tests/<name>-canonical-cli.sh
emit_test_scaffold() {
  local target_basename="$1"
  local target_rel="$2"
  # flywheel-x4e3s bug 1: when target is an absolute path outside REPO_ROOT
  # (e.g., ~/.claude/skills/.flywheel/bin/<binary>), emit a SCRIPT= line
  # without the $ROOT/ prefix to avoid double-slash.
  local script_var_value
  if [[ "$target_rel" = /* ]]; then
    script_var_value="${target_rel}"
  else
    script_var_value="\$ROOT/${target_rel}"
  fi
  cat <<EOF
#!/usr/bin/env bash
# tests/${target_basename%.sh}-canonical-cli.sh
# Canonical-cli surface tests for ${target_rel} (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="${script_var_value}"

pass_count=0
fail_count=0
pass() { pass_count=\$((pass_count + 1)); printf 'PASS %s\n' "\$1"; }
fail() { fail_count=\$((fail_count + 1)); printf 'FAIL %s\n' "\$1" >&2; }

# Test 1: bash -n syntax
if bash -n "\$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info envelope is valid JSON with schema_version
if "\$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version and .command == "info"' >/dev/null; then
  pass "--info emits canonical envelope"
else fail "--info envelope"; fi

# Test 3: --schema returns valid JSON
if "\$SCRIPT" --schema 2>/dev/null | jq -e '.schema_version and .command == "schema"' >/dev/null; then
  pass "--schema emits canonical envelope"
else fail "--schema envelope"; fi

# Test 4: --examples returns valid JSON
if "\$SCRIPT" --examples --json 2>/dev/null | jq -e '.command == "examples"' >/dev/null; then
  pass "--examples emits canonical envelope"
else fail "--examples envelope"; fi

# Test 5: doctor returns valid envelope (even pre-fill-in stub is valid JSON)
if "\$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor"' >/dev/null; then
  pass "doctor emits canonical envelope"
else fail "doctor envelope"; fi

# Test 6: health envelope
if "\$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null; then
  pass "health emits canonical envelope"
else fail "health envelope"; fi

# Test 7: repair --dry-run envelope
if "\$SCRIPT" repair --scope none --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run"' >/dev/null; then
  pass "repair --dry-run emits canonical envelope"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key REFUSES (rc=3)
"\$SCRIPT" repair --scope none --apply --json >/dev/null 2>&1
rc=\$?
if [[ "\$rc" -eq 3 ]]; then
  pass "repair --apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "repair --apply rc=\$rc (expected 3)"
fi

# Test 9: validate envelope
if "\$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate"' >/dev/null; then
  pass "validate emits canonical envelope"
else fail "validate envelope"; fi

# Test 10: audit envelope
if "\$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit"' >/dev/null; then
  pass "audit emits canonical envelope"
else fail "audit envelope"; fi

# Test 11: why with id
if "\$SCRIPT" why some-id 2>/dev/null | jq -e '.command == "why"' >/dev/null; then
  pass "why <id> emits canonical envelope"
else fail "why envelope"; fi

# Test 12: help <topic> returns text (intercepted only with topic arg)
if "\$SCRIPT" help repair 2>/dev/null | grep -q 'topic:'; then
  pass "help repair returns topic header"
else fail "help topic"; fi

# Test 13: quickstart envelope
if "\$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart"' >/dev/null; then
  pass "quickstart emits canonical envelope"
else fail "quickstart envelope"; fi

# TODO(canonical-cli-scaffold): add per-surface assertions here.
# Examples: doctor checks specific data; repair --apply with key
# performs expected mutation; validate enforces a known schema.

if [[ "\$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "\$pass_count" "\$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "\$pass_count"
EOF
}

# ---------- core scaffolder action ----------

scaffold_target() {
  local target="$1" mode="$2" idem_key="$3" no_test="$4" emit_json="$5"
  local target_abs target_rel target_basename
  target_abs="$(cd "$(dirname "$target")" 2>/dev/null && pwd -P)/$(basename "$target")" || {
    err "target not found: $target"; exit 65
  }
  target_rel="${target_abs#"$REPO_ROOT"/}"
  target_basename="$(basename "$target_abs")"

  if [[ ! -r "$target_abs" ]]; then
    err "target not readable: $target_abs"; exit 65
  fi
  if [[ ! -r "$HELPER_LIB" ]]; then
    err "helper lib missing or unreadable: $HELPER_LIB"
    exit 65
  fi

  # Refusal: jeff-stack
  if is_jeff_stack_path "$target_abs"; then
    refuse_envelope "jeff_stack_target" "$target_rel"
    exit 66
  fi

  # Refusal: non-bash shebang (e.g. .sh extension on a Python script).
  # See flywheel-e4lfb — the bash scaffold corrupts non-bash interpreters
  # by appending bash-syntax boilerplate.
  if is_non_bash_shebang "$target_abs"; then
    local interp ext_hint
    interp="$(detect_shebang_interpreter "$target_abs")"
    case "$interp" in
      python*) ext_hint="py" ;;
      perl)    ext_hint="pl" ;;
      node)    ext_hint="js" ;;
      ruby)    ext_hint="rb" ;;
      *)       ext_hint="${interp//[^A-Za-z]/}" ;;
    esac
    err "$target_rel is a $interp script (not bash). Use a $interp-aware scaffolder or rename the file with a .$ext_hint extension."
    jq -nc \
      --arg sv "$SCHEMA_VERSION" \
      --arg reason "non_bash_shebang" \
      --arg target "$target_rel" \
      --arg interpreter "$interp" \
      --arg suggested_extension "$ext_hint" \
      '{schema_version:$sv,command:"scaffold",status:"refused",reason:$reason,target:$target,interpreter:$interpreter,suggested_extension:$suggested_extension}'
    exit 66
  fi

  # Refusal: outside inventory
  if [[ "${ALLOW_UNINVENTORIED:-0}" -ne 1 ]]; then
    if ! is_in_inventory "$target_abs"; then
      refuse_envelope "uninventoried_target" "$target_rel"
      exit 66
    fi
  fi

  # Idempotency
  if is_already_scaffolded "$target_abs"; then
    jq -nc \
      --arg sv "$SCHEMA_VERSION" \
      --arg target "$target_rel" \
      --arg mode "$mode" \
      '{schema_version:$sv,command:"scaffold",status:"already_scaffolded",mode:$mode,target:$target,reason:"target carries # flywheel-cli-surface: true magic comment"}'
    return 0
  fi

  # Build the scaffolded copy in a tmp file
  local before_lines
  before_lines="$(wc -l <"$target_abs" | tr -d ' ')"

  local tmp_dir tmp_new tmp_diff tmp_block
  tmp_dir="$(mktemp -d -t scaffold-canonical-cli.XXXXXX)"
  tmp_new="$tmp_dir/${target_basename}.scaffolded"
  tmp_diff="$tmp_dir/${target_basename}.diff"
  tmp_block="$tmp_dir/${target_basename}.canonical-block"

  # 1a. Verb-collision detection (flywheel-sacan). If the target's own
  #    case-statement already handles canonical verbs, we need a flag-based
  #    bypass so the scaffold intercept defers to cmd_run when per-target
  #    flags are present in argv.
  local colliding_verbs_str bypass_flags_str verb_collision_detected
  colliding_verbs_str="$(detect_colliding_verbs "$target_abs" | tr '\n' ',' | sed 's/,$//')"
  if [[ -n "$colliding_verbs_str" ]]; then
    verb_collision_detected=true
    # Build bypass-flag list from the target's per-target --flags.
    # Heuristic: only emit bypass for flags we actually detect; operator
    # may extend the list manually if a per-target flag is missed.
    bypass_flags_str="$(detect_per_target_flags "$target_abs" | tr '\n' ',' | sed 's/,$//')"
  else
    verb_collision_detected=false
    bypass_flags_str=""
  fi

  # 1a'. Flag-collision detection (flywheel-efojs). The scaffold's intercept
  #     unconditionally claims `--info|--schema|--examples`. If the target
  #     has its OWN handler for any of those flags (e.g., flywheel-loop's
  #     `--info` emitting a different envelope), the scaffold hijacks the
  #     target's handler. Omit colliding flags from the intercept so the
  #     target's handler runs.
  local colliding_flags_str flag_collision_detected
  colliding_flags_str="$(detect_colliding_flags "$target_abs" | tr '\n' ',' | sed 's/,$//')"
  if [[ -n "$colliding_flags_str" ]]; then
    flag_collision_detected=true
  else
    flag_collision_detected=false
  fi

  # 1b. Build the canonical-cli block (used in both top-injection and
  #    the early-dispatch shim). Emits the scaffold block as a heredoc.
  #    When verb collision detected, the emitted intercept includes a
  #    flag-based bypass that defers to cmd_run. When flag collision
  #    detected, the colliding canonical flags are OMITTED from the
  #    intercept's claim-list so the target's handler still runs.
  emit_canonical_block "$target_basename" "$bypass_flags_str" "$colliding_flags_str" > "$tmp_block"

  # 2. Decide injection point. Strategy: inject AFTER the shebang and any
  #    initial `set -*` lines, BEFORE the original script body. The block
  #    defines scaffold_* functions and runs an early-dispatch intercept;
  #    if argv[0] is a canonical subcommand or introspection flag, the
  #    block dispatches there and exits — original logic never runs.
  #    Otherwise the block falls through and the original arg parser
  #    handles the args as before. Works for both `main "$@"` style AND
  #    inline `while [[ $# -gt 0 ]]` style scripts.
  awk -v block_path="$tmp_block" '
    BEGIN {
      injected = 0
      head_done = 0
    }
    {
      if (!injected && head_done == 0) {
        # The "head" is: shebang line + any contiguous comment / set
        # / blank lines that immediately follow. Once we hit a non-
        # comment, non-set, non-blank line, we mark head_done and
        # inject before that line.
        if (NR == 1 && $0 ~ /^#!/) { print; next }
        if ($0 ~ /^[[:space:]]*$/) { print; next }
        if ($0 ~ /^[[:space:]]*#/)  { print; next }
        if ($0 ~ /^[[:space:]]*set[[:space:]]+-/) { print; next }
        head_done = 1
      }
      if (head_done && !injected) {
        # Inject the canonical block here.
        while ((getline line < block_path) > 0) print line
        close(block_path)
        injected = 1
      }
      print
    }
    END {
      if (!injected) {
        # Empty target (only header); still inject at end.
        while ((getline line < block_path) > 0) print line
        close(block_path)
      }
    }
  ' "$target_abs" > "$tmp_new"

  # 3. Compute diff + scaffold metrics
  local after_lines lines_added todo_count
  after_lines="$(wc -l <"$tmp_new" | tr -d ' ')"
  lines_added=$((after_lines - before_lines))
  todo_count="$(grep -c 'TODO(canonical-cli-scaffold)' "$tmp_new" || echo 0)"

  diff -u "$target_abs" "$tmp_new" > "$tmp_diff" || true

  # 4a. Apply gate FIRST: --apply without --idempotency-key must refuse before
  # any side-effect (test scaffolding, backup, mutation). Moved ahead of the
  # test-scaffold block per flywheel-hoqq8 — previously a refused apply still
  # wrote tests/<name>-canonical-cli.sh, polluting the repo with a test
  # pointing at an unscaffolded target.
  local backup_path=""
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    if command -v cli_refuse_apply_without_idem_key >/dev/null 2>&1; then
      # shellcheck source=/dev/null
      source "$HELPER_LIB" 2>/dev/null
      cli_refuse_apply_without_idem_key "$SCHEMA_VERSION" "scaffold" "$target_rel"
    else
      jq -nc --arg sv "$SCHEMA_VERSION" --arg target "$target_rel" \
        '{schema_version:$sv,command:"scaffold",status:"refused",mode:"apply",target:$target,reason:"--apply requires --idempotency-key"}'
      exit 3
    fi
  fi

  # 4b. Optionally scaffold tests (after the apply-gate so refused applies
  # leave no trace; see flywheel-hoqq8 regression test).
  local test_path test_scaffolded=false
  test_path="$TESTS_DIR/${target_basename%.sh}-canonical-cli.sh"
  if [[ "$no_test" -ne 1 ]]; then
    if [[ ! -e "$test_path" ]]; then
      mkdir -p "$TESTS_DIR" 2>/dev/null || true
      if [[ "$mode" == "apply" ]]; then
        emit_test_scaffold "$target_basename" "$target_rel" > "$test_path"
        chmod +x "$test_path"
      else
        # dry-run: stage in tmp_dir
        emit_test_scaffold "$target_basename" "$target_rel" > "$tmp_dir/$(basename "$test_path")"
      fi
      test_scaffolded=true
    fi
  fi

  # 5. Apply (key already validated above)
  if [[ "$mode" == "apply" ]]; then
    # flywheel-x4e3s bug 3: append PID + nanosecond resolution so concurrent
    # scaffolder runs in the same UTC second produce non-colliding backups.
    # Real incident: aav72 wave 2 + hj4ip wave 3 ran in parallel and 8 backups
    # were overwritten 2026-05-10T16:03:18-19Z.
    local _ts_nanosecond _bak_pid _ts_token
    _ts_nanosecond="$(date -u +%Y%m%dT%H%M%S%N 2>/dev/null)"
    if [[ -z "$_ts_nanosecond" || "$_ts_nanosecond" =~ %N ]]; then
      # macOS / BSD date lacks %N; fall back to seconds + bash $RANDOM.
      _ts_nanosecond="$(date -u +%Y%m%dT%H%M%S)$(printf '%09d' "$RANDOM$RANDOM" | tail -c 9)"
    fi
    _bak_pid="$$"
    _ts_token="${_ts_nanosecond}Z-${_bak_pid}"
    backup_path="${target_abs}.bak.scaffold-${_ts_token}"
    cp -p "$target_abs" "$backup_path"
    cp -p "$tmp_new" "$target_abs"
    chmod +x "$target_abs" 2>/dev/null || true
  fi

  # 6. Receipt
  local helper_sha scaffolder_sha receipt
  helper_sha="$(shasum -a 256 "$HELPER_LIB" 2>/dev/null | awk '{print $1}')"
  scaffolder_sha="$(shasum -a 256 "${BASH_SOURCE[0]}" 2>/dev/null | awk '{print $1}')"
  receipt="$(jq -nc \
    --arg ts "$(iso_now)" \
    --arg target "$target_rel" \
    --arg mode "$mode" \
    --arg idem "$idem_key" \
    --arg backup "$backup_path" \
    --arg helper_sha "$helper_sha" \
    --arg scaffolder_sha "$scaffolder_sha" \
    --argjson before_lines "$before_lines" \
    --argjson after_lines "$after_lines" \
    --argjson lines_added "$lines_added" \
    --argjson todo_count "$todo_count" \
    --argjson test_scaffolded "$test_scaffolded" \
    --arg test_path "$test_path" \
    --arg tmp_diff "$tmp_diff" \
    --argjson verb_collision "$verb_collision_detected" \
    --arg colliding_verbs "$colliding_verbs_str" \
    --arg bypass_flags "$bypass_flags_str" \
    --argjson flag_collision "$flag_collision_detected" \
    --arg colliding_flags "$colliding_flags_str" \
    '{
      ts:$ts,
      target:$target,
      mode:$mode,
      idempotency_key:$idem,
      before_lines:$before_lines,
      after_lines:$after_lines,
      lines_added_by_scaffolder:$lines_added,
      todo_count:$todo_count,
      test_scaffolded:$test_scaffolded,
      test_path:$test_path,
      backup_path:$backup,
      unified_diff_path:$tmp_diff,
      helper_lib_sha:$helper_sha,
      scaffolder_sha:$scaffolder_sha,
      verb_collision_detected:$verb_collision,
      colliding_verbs:($colliding_verbs | split(",") | map(select(length > 0))),
      bypass_flags:($bypass_flags | split(",") | map(select(length > 0))),
      flag_collision_detected:$flag_collision,
      colliding_flags:($colliding_flags | split(",") | map(select(length > 0))),
      status: ($mode + "_ok"),
      schema_version:"scaffold-canonical-cli/v1"
    }')"

  # 7. Append to runs log when apply (and dry-run optionally records a "preview" row)
  if [[ "$mode" == "apply" ]]; then
    mkdir -p "$(dirname "$RUNS_LOG")" 2>/dev/null || true
    printf '%s\n' "$receipt" >> "$RUNS_LOG" 2>/dev/null || true
  fi

  # 8. Output envelope
  local envelope
  envelope="$(jq -nc \
    --arg sv "$SCHEMA_VERSION" \
    --arg target "$target_rel" \
    --arg mode "$mode" \
    --arg diff_path "$tmp_diff" \
    --argjson before "$before_lines" \
    --argjson after "$after_lines" \
    --argjson added "$lines_added" \
    --argjson todos "$todo_count" \
    --argjson test_scaffolded "$test_scaffolded" \
    --argjson receipt "$receipt" \
    '{
      schema_version:$sv,
      command:"scaffold",
      status: ($mode + "_ok"),
      mode:$mode,
      target:$target,
      unified_diff_path:$diff_path,
      before_lines:$before,
      after_lines:$after,
      scaffold_lines_added:$added,
      todo_count:$todos,
      test_scaffolded:$test_scaffolded,
      receipt:$receipt
    }')"

  if [[ "$emit_json" -eq 1 ]]; then
    printf '%s\n' "$envelope"
  else
    printf 'mode=%s target=%s before=%s after=%s lines_added=%s todos=%s test_scaffolded=%s diff=%s\n' \
      "$mode" "$target_rel" "$before_lines" "$after_lines" "$lines_added" \
      "$todo_count" "$test_scaffolded" "$tmp_diff"
  fi
}

# ---------- main ----------

main() {
  local target=""
  local mode="dry_run"
  local idem_key=""
  local no_test=0
  local emit_json=0
  local allow_uninv=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)             usage; exit 0 ;;
      --info)
        shift
        if [[ "${1:-}" == "--json" || -z "${1:-}" ]]; then emit_info; exit 0; fi
        err "--info accepts only --json"; exit 64 ;;
      --schema)              shift; emit_schema "${1:-default}"; exit 0 ;;
      --examples)            shift; emit_examples; exit 0 ;;
      --dry-run)             mode="dry_run"; shift ;;
      --apply)               mode="apply"; shift ;;
      --idempotency-key)     idem_key="${2:-}"; shift 2 ;;
      --idempotency-key=*)   idem_key="${1#--idempotency-key=}"; shift ;;
      --inventory)           INVENTORY="${2:-}"; shift 2 ;;
      --helper-lib)          HELPER_LIB="${2:-}"; shift 2 ;;
      --runs-log)            RUNS_LOG="${2:-}"; shift 2 ;;
      --no-test-scaffold)    no_test=1; shift ;;
      --allow-uninventoried) allow_uninv=1; shift ;;
      --json)                emit_json=1; shift ;;
      --*) err "unknown flag: $1"; usage >&2; exit 64 ;;
      *) target="$1"; shift ;;
    esac
  done

  if [[ -z "$target" ]]; then
    err "missing required <script_path>"
    usage >&2
    exit 64
  fi

  ALLOW_UNINVENTORIED="$allow_uninv" \
    scaffold_target "$target" "$mode" "$idem_key" "$no_test" "$emit_json"
}

main "$@"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
