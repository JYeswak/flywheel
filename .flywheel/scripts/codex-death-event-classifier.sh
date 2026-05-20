#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial → passing per bead flywheel-1hshd.15)
# doctor-mode-tier: scaffolded
# codex-death-event-classifier.sh
#
# Reads exit_evidence-<pid>-<ts>.json receipts emitted by
# codex-deathtrap-launcher.sh, classifies each per the H1/H2/H3 hypothesis
# matrix from flywheel-ukm9f, and on H2/H3 files a disposition bead. The
# classifier is data-driven: it polls the evidence dir, never watches a
# running PID. Idempotent via a JSONL ledger keyed on receipt path + sha256.
#
# Hypothesis matrix (per flywheel-ukm9f AG5):
#   H1_silent_clean_exit        codex_exit_code==0 AND stderr_byte_count==0
#   H2_real_error_with_stderr   codex_exit_code!=0 AND stderr_byte_count>0
#   H3_tmux_misreport           codex_exit_code!=0 AND stderr_byte_count==0
#   H4_warn_but_successful      codex_exit_code==0 AND stderr_byte_count>0
#       (not in original 3-hypothesis matrix; surfaced as informational only)
#
# Bead-filing policy (default):
#   - H2 and H3 file beads (real error + suspicious failure path)
#   - H1 records-only (clean exit is non-event)
#   - H4 records-only with warning class
#
# Doctrine: .flywheel/doctrine/codex-death-event-flow.md
# Launchd:  .flywheel/launchd/ai.zeststream.codex-death-classifier.plist
# Sister:   .flywheel/scripts/codex-deathtrap-launcher.sh
# Source bead: flywheel-b2zpg

set -euo pipefail

# ====== BEGIN canonical-cli scaffold (bead flywheel-1hshd.15) ======
# SURGICAL DASH-FLAG SCAFFOLD variant (sister 5ke66.17). Native already owns
# every positional canonical surface (run|doctor|health|repair|validate|
# audit|why|schema|examples|info|completion|help) with substantive impls
# and a dedicated regression suite (.flywheel/tests/test-codex-death-event-
# classifier.sh, 8 assertion groups). Reimplementing those in scaffold would
# be ~250 lines of risk for no domain value.
#
# Scaffold owns ONLY the dash-flag canonical introspection envelopes
# required by AG3 (--info / --schema / --examples / quickstart). Native
# subcommand forms (`info`, `schema`, `examples`) remain untouched for
# back-compat with the regression test.
#
# In-place augmentations to native (below this block):
#   1. doctor --json output gains .checks array (AG3.4 requirement)
#   2. --idempotency-key flag + apply-contract gate on `run --apply` and
#      `repair --apply` (lint L7 requirement)

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="codex-death-event-classifier/v1"

scaffold_emit_info() {
  if ! command -v cli_emit_info >/dev/null; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
      '{schema_version:$sv,command:"info",name:"codex-death-event-classifier.sh",version:"scaffolded-v1",capabilities:["receipt-classifier","hypothesis-matrix-h1-h2-h3-h4","ledger-jsonl","auto-bead-filing","sha256-idempotency"],helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "codex-death-event-classifier.sh" \
    "scaffolded-v1" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "run,doctor,health,repair,validate,audit,why,schema,examples,info,quickstart,completion,help" \
    "CODEX_DEATH_EVIDENCE_DIR,CODEX_DEATH_CLASSIFIER_LEDGER,BR_BIN,HOSTNAME_S" \
    '{"hypotheses":["H1_silent_clean_exit","H2_real_error_with_stderr","H3_tmux_misreport","H4_warn_but_successful"],"exit_codes":{"ok":0,"usage":1,"unreadable":2,"malformed_receipt":3,"refused_apply":3,"br_create_failure":4}}' \
    | jq -c '. + {capabilities:["receipt-classifier","hypothesis-matrix-h1-h2-h3-h4","ledger-jsonl-sha256-idempotency","auto-bead-filing-h2-h3","dry-run-mode","apply-mode-with-idempotency-key"],mutates_state:true,mutation_paths:["ledger-append","br-create-bead"]}'
}

scaffold_emit_schema() {
  local surface="${1:-default}"
  case "$surface" in
    doctor)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"doctor",fields:{schema_version:"string",status:"ok|unprocessed|unreadable",pending:"int",total_receipts:"int",ledger_rows:"int",evidence_dir:"path",ledger:"path",checks:"array of {name,status,detail?}"}}'
      ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"health",fields:{schema_version:"string",status:"ok|unprocessed|unreadable",pending:"int",total_receipts:"int",ledger_rows:"int"}}'
      ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"repair",contract:{requires_idempotency_key_when_apply:true,refusal_exit_code:3,dry_run_default:false,explicit_mode_required:true,modes:["--dry-run","--apply"]},env:{evidence_dir:"CODEX_DEATH_EVIDENCE_DIR",ledger:"CODEX_DEATH_CLASSIFIER_LEDGER"}}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"validate",subjects:["receipt-path","hypothesis","ledger-path"],contract:{rejects_with_rc1:"on schema violation"}}'
      ;;
    ledger-row|default|*)
      local input_schema output_schema
      input_schema='{"type":"object","required":["codex_exit_code","stderr_byte_count"],"properties":{"schema_version":{"type":"string"},"ts":{"type":"string"},"label":{"type":"string"},"host":{"type":"string"},"pid":{"type":"integer"},"codex_exit_code":{"type":["integer","null"]},"stderr_byte_count":{"type":["integer","null"]},"last_stderr_lines":{"type":"array"},"evidence_paths":{"type":"object"}}}'
      output_schema='{"title":"codex-death-classifier ledger row","type":"object","required":["schema_version","classified_at","evidence_path","evidence_sha256","hypothesis","exit_code","stderr_byte_count","host","label","bead_filed","bead_id"],"properties":{"schema_version":{"const":"codex-death-event-classifier.v1"},"classified_at":{"type":"string"},"evidence_path":{"type":"string"},"evidence_sha256":{"type":"string","pattern":"^[0-9a-f]{64}$"},"hypothesis":{"enum":["H1_silent_clean_exit","H2_real_error_with_stderr","H3_tmux_misreport","H4_warn_but_successful","unclassifiable"]},"exit_code":{"type":["integer","null"]},"stderr_byte_count":{"type":["integer","null"]},"host":{"type":"string"},"label":{"type":"string"},"bead_filed":{"type":"boolean"},"bead_id":{"type":["string","null"]},"reason":{"type":"string"}}}'
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --argjson in "$input_schema" --argjson out "$output_schema" \
        '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why","ledger-row"],input_schema:$in,output_schema:$out,note:"Default surface = ledger-row. Native subcommand `schema` returns the bare ledger-row JSON Schema for back-compat."}'
      ;;
  esac
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"run dry-run",invocation:"codex-death-event-classifier.sh run --dry-run --json",purpose:"classify pending receipts without writing ledger or filing beads"}'
)"$'\n'"$(jq -nc '{name:"run apply with idempotency-key",invocation:"codex-death-event-classifier.sh run --apply --idempotency-key cdec-$(date +%Y%m%d) --json",purpose:"classify + write ledger + auto-file H2/H3 beads"}'
)"$'\n'"$(jq -nc '{name:"validate one receipt",invocation:"codex-death-event-classifier.sh validate /path/to/exit_evidence-123-20260511T040000Z.json --json",purpose:"classify a single receipt without ledger write"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"codex-death-event-classifier.sh doctor --json",purpose:"check substrate health (evidence dir + ledger + named probes)"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"check substrate",command:"codex-death-event-classifier.sh doctor --json"}'
)"$'\n'"$(jq -nc '{step:2,action:"dry-run classification",command:"codex-death-event-classifier.sh run --dry-run --json"}'
)"$'\n'"$(jq -nc '{step:3,action:"apply with idempotency-key",command:"codex-death-event-classifier.sh run --apply --idempotency-key cdec-$(date +%Y%m%d) --json"}'
)"$'\n'"$(jq -nc '{step:4,action:"audit recent",command:"codex-death-event-classifier.sh audit --limit 20 --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,validate,audit"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — process new receipts in $CODEX_DEATH_EVIDENCE_DIR; SHA-256 keyed against $CODEX_DEATH_CLASSIFIER_LEDGER; --apply requires --idempotency-key (rc=3 refusal); H2/H3 receipts auto-file beads via $BR_BIN unless --no-bead-filing\n' ;;
    doctor)   printf 'topic: doctor — substrate probes: jq, shasum, br_bin, evidence_dir_readable, ledger_dir_writable; pending+total_receipts+ledger_rows summary; emits .checks array (canonical AG3.4)\n' ;;
    health)   printf 'topic: health — single status (ok|unprocessed|unreadable) + pending+total_receipts+ledger_rows count\n' ;;
    repair)   printf 'topic: repair --dry-run|--apply [--idempotency-key KEY] — surface H2/H3 candidates with bead_filed=false; --apply requires --idempotency-key (rc=3); manual file via run after fixing root cause (auto-mutation not yet wired)\n' ;;
    validate) printf 'topic: validate <receipt-path> [--json] — classify one receipt without ledger write; rc=3 if receipt malformed\n' ;;
    audit)    printf 'topic: audit [--limit N] [--json] — tail of ledger grouped by hypothesis\n' ;;
    why)      printf 'topic: why <receipt-path> [--json] — verbose classification explanation for one receipt\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate | audit | why | quickstart (SURGICAL DASH-FLAG SCAFFOLD: --info/--schema/--examples/quickstart route to scaffold canonical envelope; native positional subcommands info/schema/examples retain back-compat shape; verbs run/doctor/health/repair/validate/audit/why route to native)\n' ;;
  esac
}

scaffold_main() {
  if [[ $# -eq 0 ]]; then printf 'See: codex-death-event-classifier.sh help\n'; exit 0; fi
  case "$1" in
    --info)     shift; scaffold_emit_info "$@"; exit 0 ;;
    --schema)
      shift
      local surface="${1:-default}"
      [[ "$surface" == "--json" ]] && surface="default"
      scaffold_emit_schema "$surface"; exit 0 ;;
    --examples) shift; scaffold_emit_examples "$@"; exit 0 ;;
    quickstart) shift; scaffold_emit_quickstart "$@"; exit 0 ;;
    help)       shift; scaffold_emit_topic_help "${1:-}"; exit 0 ;;
    *)
      printf 'ERR: scaffold_main called with non-canonical arg: %s\n' "$1" >&2
      exit 64 ;;
  esac
}

# SURGICAL DASH-FLAG match — only intercept dash-flag canonical envelopes
# and scaffold-owned `quickstart` + `help <topic>`. All native positional
# subcommands fall through unchanged.
_scaffold_is_canonical_arg() {
  case "${1:-}" in
    --info|--schema|--examples) return 0 ;;
    quickstart) return 0 ;;
    help)
      case "${2:-}" in run|doctor|health|repair|validate|audit|why|quickstart|-h|--help) return 0 ;; esac
      return 1 ;;
    *) return 1 ;;
  esac
}

if [[ $# -gt 0 ]] && _scaffold_is_canonical_arg "$@"; then
  scaffold_main "$@"
  exit $?
fi
# ====== END canonical-cli scaffold ======

VERSION="codex-death-event-classifier.v1"
EVIDENCE_DIR="${CODEX_DEATH_EVIDENCE_DIR:-$HOME/.local/state/flywheel/codex-death-evidence}"
LEDGER="${CODEX_DEATH_CLASSIFIER_LEDGER:-$HOME/.local/state/flywheel/codex-death-classifier-ledger.jsonl}"
BR_BIN="${BR_BIN:-br}"
HOSTNAME_S="${HOSTNAME_S:-$(hostname -s 2>/dev/null || echo unknown)}"

usage() {
  cat <<EOF
$VERSION - classify codex-deathtrap exit_evidence receipts per H1/H2/H3

USAGE
  codex-death-event-classifier.sh <command> [flags]

COMMANDS
  run                                 Process new receipts (default).
  doctor [--json]                     Operator view of evidence dir + ledger.
  health [--json]                     Single status: ok | unprocessed | unreadable.
  repair --dry-run|--apply [--json]   Re-attempt failed bead-fills (no auto delete).
  validate <receipt-path> [--json]    Classify one receipt without ledger write.
  audit [--limit N] [--json]          Tail of ledger, summary by hypothesis.
  why <receipt-path> [--json]         Verbose explanation for one receipt.
  schema                              JSON output schema for one ledger row.
  examples                            Minimal example commands.
  info                                Surface name, hypotheses, paths.
  completion                          Bash completion text.
  help                                This message.

FLAGS
  --evidence-dir PATH                 Override evidence dir.
  --ledger PATH                       Override ledger path.
  --br-bin PATH                       Override br binary.
  --dry-run                           Classify without filing beads or writing ledger.
  --apply                             Write ledger and file beads (default for run).
  --json                              Emit JSON output.
  --no-bead-filing                    Classify + ledger but skip br create.

EXIT CODES
  0  ok
  1  bad args / usage
  2  evidence dir or ledger unreadable
  3  malformed receipt encountered
  4  br_create failure during apply
EOF
}

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }

info() {
  jq -nc --arg v "$VERSION" --arg dir "$EVIDENCE_DIR" --arg ledger "$LEDGER" \
    '{command:"codex-death-event-classifier",version:$v,evidence_dir:$dir,ledger:$ledger,
      hypotheses:[
        {id:"H1_silent_clean_exit",rule:"exit_code==0 AND stderr_byte_count==0",files_bead:false},
        {id:"H2_real_error_with_stderr",rule:"exit_code!=0 AND stderr_byte_count>0",files_bead:true,priority:"P1"},
        {id:"H3_tmux_misreport",rule:"exit_code!=0 AND stderr_byte_count==0",files_bead:true,priority:"P2"},
        {id:"H4_warn_but_successful",rule:"exit_code==0 AND stderr_byte_count>0",files_bead:false}
      ]}'
}
examples() {
  cat <<EOF
EXAMPLES:
  codex-death-event-classifier.sh run --json
  codex-death-event-classifier.sh validate /Users/josh/.local/state/flywheel/codex-death-evidence/exit_evidence-1234-20260510T010000Z.json --json
  codex-death-event-classifier.sh doctor --json
  codex-death-event-classifier.sh audit --limit 20 --json
EOF
}
schema() {
  cat <<'EOF'
{"title":"codex-death-classifier ledger row","type":"object","required":["schema_version","classified_at","evidence_path","evidence_sha256","hypothesis","exit_code","stderr_byte_count","host","label","bead_filed","bead_id"],"properties":{"schema_version":{"const":"codex-death-event-classifier.v1"},"classified_at":{"type":"string"},"evidence_path":{"type":"string"},"evidence_sha256":{"type":"string","pattern":"^[0-9a-f]{64}$"},"hypothesis":{"enum":["H1_silent_clean_exit","H2_real_error_with_stderr","H3_tmux_misreport","H4_warn_but_successful","unclassifiable"]},"exit_code":{"type":["integer","null"]},"stderr_byte_count":{"type":["integer","null"]},"host":{"type":"string"},"label":{"type":"string"},"bead_filed":{"type":"boolean"},"bead_id":{"type":["string","null"]},"reason":{"type":"string"}}}
EOF
}
completion() { printf '%s\n' 'complete -W "run doctor health repair validate audit why schema examples info completion help --evidence-dir --ledger --br-bin --dry-run --apply --json --no-bead-filing --limit" codex-death-event-classifier.sh'; }

# --- argument parsing ---
COMMAND=""
JSON_OUT=0
DRY_RUN=0
APPLY=0
APPLY_EXPLICITLY_REQUESTED=0
NO_BEAD_FILING=0
LIMIT=10
TARGET_PATH=""
# NEW (flywheel-1hshd.15): canonical apply-contract gate (lint L7).
IDEMPOTENCY_KEY=""

if [[ $# -eq 0 ]]; then COMMAND="run"; fi
case "${1:-}" in
  -h|--help|help) usage; exit 0 ;;
  schema) schema; exit 0 ;;
  examples|--examples) examples; exit 0 ;;
  info|--info) info; exit 0 ;;
  completion) completion; exit 0 ;;
esac

if [[ -z "$COMMAND" ]]; then
  COMMAND="$1"; shift
fi
case "$COMMAND" in
  run|doctor|health|repair|validate|audit|why) ;;
  *) usage >&2; die "unknown command: $COMMAND" 1 ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence-dir) EVIDENCE_DIR="$2"; shift 2 ;;
    --ledger) LEDGER="$2"; shift 2 ;;
    --br-bin) BR_BIN="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --apply) APPLY=1; APPLY_EXPLICITLY_REQUESTED=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --no-bead-filing) NO_BEAD_FILING=1; shift ;;
    --limit) LIMIT="$2"; shift 2 ;;
    --idempotency-key) IDEMPOTENCY_KEY="${2:?--idempotency-key requires KEY}"; shift 2 ;;
    --idempotency-key=*) IDEMPOTENCY_KEY="${1#--idempotency-key=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) die "unknown flag: $1" 1 ;;
    *) [[ -z "$TARGET_PATH" ]] && TARGET_PATH="$1" || die "unexpected positional arg: $1" 1; shift ;;
  esac
done

# `run` defaults to apply unless --dry-run is set.
if [[ "$COMMAND" == "run" && "$DRY_RUN" -eq 0 ]]; then APPLY=1; fi

# NEW (flywheel-1hshd.15): canonical apply-contract gate. Enforce
# --idempotency-key only when --apply is EXPLICITLY requested (back-compat:
# default `run` mode without explicit --apply continues to operate).
if [[ "$APPLY_EXPLICITLY_REQUESTED" -eq 1 && -z "$IDEMPOTENCY_KEY" ]]; then
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc --arg sv "$VERSION" --arg cmd "$COMMAND" \
      '{schema_version:$sv,command:$cmd,status:"refused",mode:"apply",reason:"--apply requires --idempotency-key KEY (canonical apply contract)",exit_code:3}'
  else
    printf 'ERR: %s --apply requires --idempotency-key KEY (canonical apply contract; rc=3)\n' "$COMMAND" >&2
  fi
  exit 3
fi

mkdir -p "$EVIDENCE_DIR" "$(dirname "$LEDGER")" 2>/dev/null || true
[[ -d "$EVIDENCE_DIR" ]] || die "evidence dir unreadable: $EVIDENCE_DIR" 2

# --- helpers ---
sha256_file() { shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'; }

ledger_has_sha() {
  local sha="$1"
  [[ -r "$LEDGER" ]] || return 1
  grep -F "\"evidence_sha256\":\"$sha\"" "$LEDGER" >/dev/null 2>&1
}

# Classify one receipt JSON. Echoes one ledger-row JSON object on stdout.
classify_one() {
  local receipt="$1" sha
  if [[ ! -r "$receipt" ]]; then
    jq -nc --arg sv "$VERSION" --arg p "$receipt" --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg host "$HOSTNAME_S" \
      '{schema_version:$sv,classified_at:$now,evidence_path:$p,evidence_sha256:"",hypothesis:"unclassifiable",exit_code:null,stderr_byte_count:null,host:$host,label:"",bead_filed:false,bead_id:null,reason:"receipt unreadable"}'
    return 3
  fi
  if ! jq -e . "$receipt" >/dev/null 2>&1; then
    sha="$(sha256_file "$receipt")"
    jq -nc --arg sv "$VERSION" --arg p "$receipt" --arg sha "$sha" --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg host "$HOSTNAME_S" \
      '{schema_version:$sv,classified_at:$now,evidence_path:$p,evidence_sha256:$sha,hypothesis:"unclassifiable",exit_code:null,stderr_byte_count:null,host:$host,label:"",bead_filed:false,bead_id:null,reason:"receipt malformed json"}'
    return 3
  fi
  sha="$(sha256_file "$receipt")"
  jq -c --arg sv "$VERSION" --arg p "$receipt" --arg sha "$sha" --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg host_default "$HOSTNAME_S" \
    '{
      schema_version:$sv,
      classified_at:$now,
      evidence_path:$p,
      evidence_sha256:$sha,
      hypothesis:(
        (.codex_exit_code // null) as $c |
        (.stderr_byte_count // null) as $s |
        if $c == 0 and $s == 0 then "H1_silent_clean_exit"
        elif ($c // 0) != 0 and ($s // 0) > 0 then "H2_real_error_with_stderr"
        elif ($c // 0) != 0 and ($s // 0) == 0 then "H3_tmux_misreport"
        elif $c == 0 and ($s // 0) > 0 then "H4_warn_but_successful"
        else "unclassifiable" end
      ),
      exit_code:(.codex_exit_code // null),
      stderr_byte_count:(.stderr_byte_count // null),
      host:(.host // $host_default),
      label:(.label // ""),
      bead_filed:false,
      bead_id:null,
      reason:(
        (.codex_exit_code // null) as $c |
        (.stderr_byte_count // null) as $s |
        if $c == 0 and $s == 0 then "exit_code 0 + stderr empty -> H1 silent clean exit"
        elif ($c // 0) != 0 and ($s // 0) > 0 then "exit_code \($c) + stderr \($s)B -> H2 real error"
        elif ($c // 0) != 0 and ($s // 0) == 0 then "exit_code \($c) + stderr empty -> H3 tmux misreport class"
        elif $c == 0 and ($s // 0) > 0 then "exit_code 0 + stderr \($s)B -> H4 warn but successful"
        else "exit_code or stderr_byte_count missing/invalid" end
      )
    }' "$receipt"
  return 0
}

file_bead_for_row() {
  # Reads one ledger-row JSON on stdin, returns a (possibly amended) row.
  # Files a br bead for H2/H3 unless --no-bead-filing or --dry-run.
  local row="$1" hypothesis priority title body bead_id raw rc
  hypothesis="$(echo "$row" | jq -r '.hypothesis')"
  case "$hypothesis" in
    H2_real_error_with_stderr) priority="P1" ;;
    H3_tmux_misreport) priority="P2" ;;
    *) echo "$row"; return 0 ;;
  esac
  if [[ "$NO_BEAD_FILING" -eq 1 || "$DRY_RUN" -eq 1 ]]; then
    echo "$row"
    return 0
  fi
  title="[fleet-death-rca] codex worker death classified $hypothesis"
  body="$(echo "$row" | jq -r '"Auto-filed by codex-death-event-classifier.sh.\n\nReceipt: \(.evidence_path)\nSHA-256: \(.evidence_sha256)\nHost: \(.host)\nLabel: \(.label)\nExit code: \(.exit_code)\nStderr bytes: \(.stderr_byte_count)\nHypothesis: \(.hypothesis)\nReason: \(.reason)\n\nAcceptance gates:\n- Inspect receipt and stderr log; confirm classification matches.\n- File upstream bug or local mitigation per ukm9f AG6.\n- Close this bead when disposition lands."')"
  set +e
  raw="$("$BR_BIN" create "$title" --type bug --priority "$priority" --description "$body" --json 2>&1)"
  rc=$?
  set -e
  if [[ "$rc" -ne 0 ]]; then
    echo "$row" | jq -c --arg err "$raw" '. + {bead_filed:false,bead_id:null,reason:(.reason + " | br_create_failed: " + ($err|tostring))}'
    return 4
  fi
  bead_id="$(echo "$raw" | jq -r '.id // .issue.id // empty' 2>/dev/null || true)"
  echo "$row" | jq -c --arg id "$bead_id" '. + {bead_filed:true,bead_id:$id}'
  return 0
}

emit() {
  local payload="$1"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    echo "$payload"
  else
    echo "$payload" | jq -r '"\(.classified_at) \(.hypothesis) exit=\(.exit_code) stderr=\(.stderr_byte_count) bead=\(.bead_id // "-") path=\(.evidence_path)"'
  fi
}

# --- command dispatch ---
case "$COMMAND" in
  run)
    processed=0; new=0; filed=0; errors=0
    declare -a rows=()
    for receipt in "$EVIDENCE_DIR"/exit_evidence-*.json; do
      [[ -e "$receipt" ]] || continue
      processed=$((processed+1))
      sha="$(sha256_file "$receipt")"
      if [[ -n "$sha" ]] && ledger_has_sha "$sha"; then
        continue
      fi
      set +e
      row="$(classify_one "$receipt")"
      rc=$?
      set -e
      if [[ "$rc" -ne 0 ]]; then
        errors=$((errors+1))
      fi
      set +e
      row="$(file_bead_for_row "$row")"
      file_rc=$?
      set -e
      if [[ "$file_rc" -ne 0 ]]; then
        errors=$((errors+1))
      fi
      bead_filed_now="$(echo "$row" | jq -r '.bead_filed')"
      if [[ "$bead_filed_now" == "true" ]]; then filed=$((filed+1)); fi
      new=$((new+1))
      if [[ "$APPLY" -eq 1 ]]; then
        echo "$row" >> "$LEDGER"
      fi
      rows+=("$row")
    done
    if [[ "$JSON_OUT" -eq 1 ]]; then
      printf '%s\n' "${rows[@]}" | jq -s --arg sv "$VERSION" --argjson p "$processed" --argjson n "$new" --argjson f "$filed" --argjson e "$errors" --arg dir "$EVIDENCE_DIR" --arg ledger "$LEDGER" --arg mode "$([[ "$APPLY" -eq 1 ]] && echo apply || echo dry-run)" \
        '{schema_version:$sv,mode:$mode,evidence_dir:$dir,ledger:$ledger,processed:$p,new_classified:$n,beads_filed:$f,errors:$e,rows:.}'
    else
      printf 'classifier mode=%s processed=%d new=%d beads_filed=%d errors=%d ledger=%s\n' \
        "$([[ "$APPLY" -eq 1 ]] && echo apply || echo dry-run)" \
        "$processed" "$new" "$filed" "$errors" "$LEDGER"
    fi
    [[ "$errors" -gt 0 ]] && exit 4
    exit 0
    ;;
  doctor|health)
    pending=0; total=0
    for receipt in "$EVIDENCE_DIR"/exit_evidence-*.json; do
      [[ -e "$receipt" ]] || continue
      total=$((total+1))
      sha="$(sha256_file "$receipt")"
      if [[ -z "$sha" ]] || ! ledger_has_sha "$sha"; then
        pending=$((pending+1))
      fi
    done
    if [[ ! -r "$LEDGER" ]]; then
      ledger_rows=0
    else
      ledger_rows="$(wc -l <"$LEDGER" | tr -d ' ')"
    fi
    if [[ "$total" -eq 0 ]]; then
      health_status="ok"
    elif [[ "$pending" -gt 0 ]]; then
      health_status="unprocessed"
    else
      health_status="ok"
    fi
    if [[ "$COMMAND" == "health" ]]; then
      if [[ "$JSON_OUT" -eq 1 ]]; then
        jq -nc --arg v "$VERSION" --arg s "$health_status" --argjson p "$pending" --argjson t "$total" --argjson l "$ledger_rows" \
          '{schema_version:$v,status:$s,pending:$p,total_receipts:$t,ledger_rows:$l}'
      else
        printf 'health=%s pending=%d total=%d ledger_rows=%d\n' "$health_status" "$pending" "$total" "$ledger_rows"
      fi
      [[ "$health_status" == "ok" ]] && exit 0 || exit 0
    fi
    if [[ "$JSON_OUT" -eq 1 ]]; then
      # NEW (flywheel-1hshd.15): named-probe checks array (AG3.4 requirement).
      jq_status="fail"; shasum_status="fail"; br_bin_status="fail"
      ev_dir_status="fail"; ledger_dir_status="fail"
      command -v jq >/dev/null 2>&1 && jq_status="pass"
      command -v shasum >/dev/null 2>&1 && shasum_status="pass"
      command -v "$BR_BIN" >/dev/null 2>&1 && br_bin_status="pass"
      [[ -d "$EVIDENCE_DIR" && -r "$EVIDENCE_DIR" ]] && ev_dir_status="pass"
      _ledger_dir="$(dirname "$LEDGER")"
      [[ -d "$_ledger_dir" && -w "$_ledger_dir" ]] && ledger_dir_status="pass"
      jq -nc --arg v "$VERSION" --arg s "$health_status" --argjson p "$pending" --argjson t "$total" --argjson l "$ledger_rows" \
        --arg dir "$EVIDENCE_DIR" --arg ledger "$LEDGER" \
        --arg jq_s "$jq_status" --arg sha_s "$shasum_status" --arg br_s "$br_bin_status" \
        --arg ev_s "$ev_dir_status" --arg ld_s "$ledger_dir_status" --arg br_bin "$BR_BIN" --arg ledger_dir "$_ledger_dir" \
        '{schema_version:$v,command:"doctor",status:$s,pending:$p,total_receipts:$t,ledger_rows:$l,evidence_dir:$dir,ledger:$ledger,
          checks:[
            {name:"jq_available",status:$jq_s},
            {name:"shasum_available",status:$sha_s},
            {name:"br_bin_available",status:$br_s,path:$br_bin,detail:"load-bearing — used to file H2/H3 beads"},
            {name:"evidence_dir_readable",status:$ev_s,path:$dir},
            {name:"ledger_dir_writable",status:$ld_s,path:$ledger_dir}
          ]}'
    else
      printf 'doctor: status=%s pending=%d total=%d ledger=%s rows=%d\n' "$health_status" "$pending" "$total" "$LEDGER" "$ledger_rows"
    fi
    exit 0
    ;;
  validate|why)
    [[ -n "$TARGET_PATH" ]] || die "$COMMAND requires <receipt-path>" 1
    set +e
    row="$(classify_one "$TARGET_PATH")"
    rc=$?
    set -e
    if [[ "$JSON_OUT" -eq 1 || "$COMMAND" == "why" ]]; then
      echo "$row"
    else
      emit "$row"
    fi
    exit "$rc"
    ;;
  audit)
    if [[ ! -r "$LEDGER" ]]; then
      if [[ "$JSON_OUT" -eq 1 ]]; then
        jq -nc --arg v "$VERSION" '{schema_version:$v,total:0,by_hypothesis:{},rows:[]}'
      else
        printf 'audit: ledger empty or unreadable\n'
      fi
      exit 0
    fi
    if [[ "$JSON_OUT" -eq 1 ]]; then
      tail -n "$LIMIT" "$LEDGER" | jq -cs --arg v "$VERSION" \
        '{schema_version:$v,total:length,by_hypothesis:(group_by(.hypothesis) | map({key:(.[0].hypothesis), value:length}) | from_entries),rows:.}'
    else
      tail -n "$LIMIT" "$LEDGER" | jq -r '"\(.classified_at) \(.hypothesis) exit=\(.exit_code) stderr=\(.stderr_byte_count) bead=\(.bead_id // "-") path=\(.evidence_path)"'
    fi
    exit 0
    ;;
  repair)
    [[ "$DRY_RUN" -eq 1 || "$APPLY" -eq 1 ]] || die "repair requires --dry-run or --apply" 1
    if [[ ! -r "$LEDGER" ]]; then
      if [[ "$JSON_OUT" -eq 1 ]]; then jq -nc --arg v "$VERSION" '{schema_version:$v,mode:"no-op",reason:"ledger absent",candidates:[]}'; else echo "repair: ledger absent"; fi
      exit 0
    fi
    candidates="$(jq -c 'select(.bead_filed == false and (.hypothesis == "H2_real_error_with_stderr" or .hypothesis == "H3_tmux_misreport"))' "$LEDGER" 2>/dev/null | jq -cs '.' || echo '[]')"
    cand_count="$(jq -r 'length' <<<"$candidates")"
    if [[ "$JSON_OUT" -eq 1 ]]; then
      jq -nc --arg v "$VERSION" --arg mode "$([[ "$APPLY" -eq 1 ]] && echo apply || echo dry-run)" --argjson c "$candidates" --argjson n "$cand_count" \
        '{schema_version:$v,mode:$mode,candidates:$c,candidate_count:$n,mutation_invoked:false,note:"manual file via run after fixing root cause; auto-mutation not yet wired"}'
    else
      printf 'repair: mode=%s candidates=%d (manual file via run)\n' "$([[ "$APPLY" -eq 1 ]] && echo apply || echo dry-run)" "$cand_count"
    fi
    exit 0
    ;;
esac

usage >&2
exit 1

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-03-agent-ergonomics-rubric.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-58-agent-tool-theory-of-mind.md`
