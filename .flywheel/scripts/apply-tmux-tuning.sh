#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial → passing per bead flywheel-1hshd.4)
# apply-tmux-tuning.sh - reversible tmux 3.6a tuning for agent swarms
#
# Bead: flywheel-1q5yv
# Donella analysis: /tmp/2tmux-donella-analysis-2026-05-05.md
# Canonical CLI: doctor / health / repair, validate / audit / why, info/examples/help/completion
# canonical-cli-scoping-allow-large: dispatch requires one self-contained applier matching apply-substrate-tuning.sh shape.

set -euo pipefail

VERSION="apply-tmux-tuning.v1.0.0"
SCHEMA_VERSION="tmux-tuning.v1"
LEDGER_SCHEMA="tmux-tuning.ledger.v1"

TMUX_CFG="${TMUX_TUNING_CONFIG:-$HOME/.tmux.conf}"
LEDGER="${TMUX_TUNING_LEDGER:-$HOME/.local/state/flywheel/tmux-tuning.jsonl}"
TMUX_BIN="${TMUX_TUNING_TMUX_BIN:-tmux}"
JSONL_APPEND_LIB="${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"

BLOCK_BEGIN="# BEGIN apply-tmux-tuning (flywheel-2tmux) ----------------------------------"
BLOCK_END="# END apply-tmux-tuning (flywheel-2tmux) ------------------------------------"
PRECURSOR_BEGIN="# BEGIN apply-substrate-tuning (flywheel-3099j)"

MODE=""
JSON_OUT=0
WATCH=0
DRY_RUN=1
APPLY=0
REPAIR_SCOPE="config"
WHY_KEY=""
SCHEMA_TOPIC=""
# NEW (flywheel-1hshd.4): --idempotency-key for canonical apply contract (L7).
IDEMPOTENCY_KEY=""
HELP_TOPIC="overview"
COMPLETION_SHELL=""
WIDTH=100
NO_COLOR=0
NO_EMOJI=0

usage() {
  cat <<'EOF'
usage:
  apply-tmux-tuning.sh                         # dry-run plan
  apply-tmux-tuning.sh --apply [--json]        # requires APPROVE=yes
  apply-tmux-tuning.sh --revert [--json]       # requires APPROVE=yes
  apply-tmux-tuning.sh doctor [--json]
  apply-tmux-tuning.sh health [--watch] [--json]
  apply-tmux-tuning.sh repair --scope config [--dry-run|--apply] [--json]
  apply-tmux-tuning.sh validate ledger [--json]
  apply-tmux-tuning.sh audit [--json]
  apply-tmux-tuning.sh why <key> [--json]
  apply-tmux-tuning.sh schema config|backup|ledger [--json]
  apply-tmux-tuning.sh --info | --examples | quickstart | help <topic> | completion zsh

Exit codes: 0 ok, 1 domain failure, 2 usage, 4 blocked by gate.
EOF
}

now_iso() { printf '%s\n' "${TMUX_TUNING_NOW:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"; }

sha256_file() {
  if [[ -f "$1" ]]; then shasum -a 256 "$1" | awk '{print $1}'; else printf 'absent\n'; fi
}

sha256_stdin() { shasum -a 256 | awk '{print $1}'; }

emit() {
  local payload="$1" text="${2:-}" rc="${3:-0}"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    if [[ -n "$text" ]]; then printf '%s\n' "$text"; else printf '%s\n' "$payload" | jq .; fi
  fi
  return "$rc"
}

target_block() {
  cat <<'TMUX'
# BEGIN apply-tmux-tuning (flywheel-2tmux) ----------------------------------
# Sources: Jeff NTM tmux tips, FrankenTUI mux policy, tmux CHANGES 3.5-3.6a.
# Reversible config-only block; do not nest inside flywheel-3099j.
set-option -g set-clipboard external
set-option -g allow-passthrough on
set-option -g extended-keys on
set-option -g assume-paste-time 5
set-option -g repeat-time 250
set-option -g display-panes-time 500
set-option -g bell-action none
set-option -g monitor-bell off
set-option -g renumber-windows on
set-option -g terminal-features "xterm*:clipboard:ccolour:cstyle:focus:title,screen*:title,rxvt*:ignorefkeys,xterm-256color:RGB:clipboard:focus:sixel:hyperlinks:ccolour:cstyle:title:mouse:extkeys"
# END apply-tmux-tuning (flywheel-2tmux) ------------------------------------
TMUX
}

expected_block_sha() { target_block | sha256_stdin; }

block_present() {
  [[ -f "$TMUX_CFG" ]] && grep -qF "$BLOCK_BEGIN" "$TMUX_CFG"
}

precursor_present() {
  [[ -f "$TMUX_CFG" ]] && grep -qF "$PRECURSOR_BEGIN" "$TMUX_CFG"
}

current_block() {
  [[ -f "$TMUX_CFG" ]] || return 0
  awk -v b="$BLOCK_BEGIN" -v e="$BLOCK_END" '
    index($0,b) { in_block=1 }
    in_block { print }
    index($0,e) { in_block=0 }
  ' "$TMUX_CFG"
}

current_block_sha() {
  if block_present; then current_block | sha256_stdin; else printf 'absent\n'; fi
}

needs_mutation() {
  [[ "$(current_block_sha)" != "$(expected_block_sha)" ]]
}

remove_existing_block_to() {
  local src="$1" dst="$2"
  if [[ ! -f "$src" ]]; then
    : >"$dst"
    return 0
  fi
  awk -v b="$BLOCK_BEGIN" -v e="$BLOCK_END" '
    index($0,b) { skip=1; next }
    index($0,e) { skip=0; next }
    !skip { print }
  ' "$src" >"$dst"
}

candidate_file() {
  local dst="$1"
  remove_existing_block_to "$TMUX_CFG" "$dst"
  printf '\n' >>"$dst"
  target_block >>"$dst"
}

backup_path() {
  local ts="$1"
  printf '%s.bak.tmux-tuning.%s\n' "$TMUX_CFG" "$ts"
}

tmux_version_raw() {
  "$TMUX_BIN" -V 2>/dev/null | awk '{print $2}' || printf 'missing\n'
}

version_compatible_bool() {
  local raw clean major minor
  raw="$(tmux_version_raw)"
  clean="$(printf '%s\n' "$raw" | sed 's/[^0-9.].*$//')"
  major="${clean%%.*}"
  minor="${clean#*.}"
  minor="${minor%%.*}"
  if [[ "$major" =~ ^[0-9]+$ && "$minor" =~ ^[0-9]+$ ]]; then
    if (( major > 3 || (major == 3 && minor >= 5) )); then
      printf 'true\n'
      return 0
    fi
  fi
  printf 'false\n'
  return 1
}

tmux_option_value() {
  local opt="$1" out flag
  for flag in -gqv -gwqv -gsqv; do
    if out="$("$TMUX_BIN" show-options "$flag" "$opt" 2>/dev/null)"; then
      printf '%s\n' "$out"
      return 0
    fi
  done
  printf 'unknown\n'
}

terminal_info_bool() {
  infocmp -x "$1" >/dev/null 2>&1 && printf 'true\n' || printf 'false\n'
}

ledger_stats_json() {
  local rows=0 valid=0 invalid=0 line
  if [[ -s "$LEDGER" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      rows=$((rows + 1))
      if jq -e --arg s "$LEDGER_SCHEMA" 'type=="object" and .schema_version==$s' >/dev/null 2>&1 <<<"$line"; then
        valid=$((valid + 1))
      else
        invalid=$((invalid + 1))
      fi
    done <"$LEDGER"
  fi
  jq -nc --argjson rows "$rows" --argjson valid "$valid" --argjson invalid "$invalid" \
    '{rows:$rows,valid:$valid,invalid:$invalid}'
}

append_ledger() {
  local row="$1"
  mkdir -p "$(dirname "$LEDGER")"
  if [[ -r "$JSONL_APPEND_LIB" ]]; then
    # shellcheck source=/dev/null
    source "$JSONL_APPEND_LIB"
    fw_jsonl_append_validated "$LEDGER" "$row"
  else
    printf '%s\n' "$row" >>"$LEDGER"
  fi
}

write_receipt() {
  local action="$1" outcome="$2" pre="$3" post="$4" backup="${5:-}" source_rc="${6:-null}" extra
  extra="${7:-}"
  [[ -n "$extra" ]] || extra='{}'
  local row
  row="$(jq -nc \
    --arg schema_version "$LEDGER_SCHEMA" \
    --arg version "$VERSION" \
    --arg ts "$(now_iso)" \
    --arg action "$action" \
    --arg outcome "$outcome" \
    --arg config "$TMUX_CFG" \
    --arg backup_path "$backup" \
    --arg pre "$pre" \
    --arg post "$post" \
    --arg current "$(current_block_sha)" \
    --arg expected "$(expected_block_sha)" \
    --arg tmux_version "$(tmux_version_raw)" \
    --argjson source_file_exit "$source_rc" \
    --argjson extra "$extra" \
    '{schema_version:$schema_version,version:$version,ts:$ts,action:$action,outcome:$outcome,
      config_path:$config,backup_path:$backup_path,pre_sha256:$pre,post_sha256:$post,
      current_block_sha:$current,expected_block_sha:$expected,tmux_version:$tmux_version,
      source_file_exit:$source_file_exit} + $extra')"
  append_ledger "$row"
  printf '%s\n' "$row"
}

doctor_payload() {
  local stats version_ok drift
  stats="$(ledger_stats_json)"
  version_ok="$(version_compatible_bool || true)"
  if needs_mutation; then drift=true; else drift=false; fi
  jq -nc \
    --arg schema_version "$SCHEMA_VERSION.doctor" \
    --arg version "$VERSION" \
    --arg ts "$(now_iso)" \
    --arg config "$TMUX_CFG" \
    --arg config_sha "$(sha256_file "$TMUX_CFG")" \
    --arg current "$(current_block_sha)" \
    --arg expected "$(expected_block_sha)" \
    --arg tmux_version "$(tmux_version_raw)" \
    --arg history "$(tmux_option_value history-limit)" \
    --arg escape "$(tmux_option_value escape-time)" \
    --arg clipboard "$(tmux_option_value set-clipboard)" \
    --arg terminal "$(tmux_option_value default-terminal)" \
    --arg aggressive "$(tmux_option_value aggressive-resize)" \
    --arg focus "$(tmux_option_value focus-events)" \
    --arg extended "$(tmux_option_value extended-keys)" \
    --arg mouse "$(tmux_option_value mouse)" \
    --arg passthrough "$(tmux_option_value allow-passthrough)" \
    --argjson drift "$drift" \
    --argjson version_ok "$version_ok" \
    --argjson infocmp_tmux "$(terminal_info_bool tmux-256color)" \
    --argjson infocmp_screen "$(terminal_info_bool screen-256color)" \
    --argjson precursor "$(precursor_present && printf true || printf false)" \
    --argjson stats "$stats" \
    '{schema_version:$schema_version,version:$version,ts:$ts,config_path:$config,
      config_sha256:$config_sha,current_block_sha:$current,expected_block_sha:$expected,
      drift:$drift,tmux_version:$tmux_version,version_compatible:$version_ok,
      terminfo:{tmux_256color:$infocmp_tmux,screen_256color:$infocmp_screen},
      existing_3099j_block_present:$precursor,
      ledger_rows_valid:$stats.valid,ledger_rows_invalid:$stats.invalid,
      live_options:{history_limit:$history,escape_time:$escape,set_clipboard:$clipboard,
        default_terminal:$terminal,aggressive_resize:$aggressive,focus_events:$focus,
        extended_keys:$extended,mouse:$mouse,allow_passthrough:$passthrough}}'
}

require_approval() {
  [[ "${APPROVE:-}" == "yes" ]] && return 0
  local payload
  payload="$(jq -nc --arg schema_version "$SCHEMA_VERSION.blocked" \
    '{schema_version:$schema_version,status:"blocked",reason:"APPROVE=yes required for mutation"}')"
  emit "$payload" "blocked: APPROVE=yes required for mutation" 4
}

mode_doctor() {
  local payload
  payload="$(doctor_payload)"
  emit "$payload" "drift=$(jq -r '.drift' <<<"$payload") version_compatible=$(jq -r '.version_compatible' <<<"$payload")"
}

mode_health_once() {
  local payload status
  payload="$(doctor_payload)"
  status="green"
  if [[ "$(jq -r '.version_compatible' <<<"$payload")" != "true" ]]; then status="red"; fi
  if [[ "$(jq -r '.drift' <<<"$payload")" == "true" ]]; then status="yellow"; fi
  payload="$(jq -c --arg status "$status" '. + {status:$status}' <<<"$payload")"
  emit "$payload" "tmux-tuning health=$status drift=$(jq -r '.drift' <<<"$payload")"
}

mode_health() {
  if [[ "$WATCH" -eq 0 ]]; then mode_health_once; return; fi
  while true; do mode_health_once; sleep "${TMUX_TUNING_WATCH_INTERVAL:-5}"; done
}

mode_repair() {
  local pre post ts backup="" candidate parse_log parse_rc source_log source_rc payload extra mutation
  pre="$(sha256_file "$TMUX_CFG")"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    if needs_mutation; then mutation=true; else mutation=false; fi
    extra="$(jq -nc --argjson mutation "$mutation" '{dry_run:true,would_write:$mutation,would_call_external:false,planned_actions:["backup config if mutation needed","write expected block","tmux source-file config"]}')"
    payload="$(write_receipt "dry-run" "planned" "$pre" "$pre" "" null "$extra")"
    emit "$payload" "dry-run: would_write=$mutation"
    return 0
  fi

  require_approval || return $?
  if [[ "$(version_compatible_bool || true)" != "true" ]]; then
    extra="$(jq -nc '{reason:"tmux version must be >=3.5"}')"
    payload="$(write_receipt "apply" "refuse" "$pre" "$pre" "" null "$extra")"
    emit "$payload" "refuse: tmux version must be >=3.5" 4
    return 4
  fi

  mutation=false
  ts="$(now_iso)"
  if needs_mutation; then
    mutation=true
    if [[ -f "$TMUX_CFG" ]]; then
      backup="$(backup_path "$ts")"
      [[ -e "$backup" ]] && backup="${backup}.$$"
      cp -p "$TMUX_CFG" "$backup"
    else
      mkdir -p "$(dirname "$TMUX_CFG")"
      : >"$TMUX_CFG"
    fi
    candidate="$(mktemp -t apply-tmux-tuning.XXXXXX)"
    candidate_file "$candidate"
    parse_log="$("$TMUX_BIN" source-file -n "$candidate" 2>&1)" || {
      parse_rc=$?
      rm -f "$candidate"
      extra="$(jq -nc --arg parse_log "$parse_log" --argjson parse_exit "$parse_rc" '{parse_exit:$parse_exit,parse_log:$parse_log}')"
      payload="$(write_receipt "apply" "parse-failed" "$pre" "$pre" "$backup" null "$extra")"
      emit "$payload" "apply failed: candidate parse failed" 1
      return 1
    }
    mv "$candidate" "$TMUX_CFG"
  fi

  source_log="$("$TMUX_BIN" source-file "$TMUX_CFG" 2>&1)" || {
    source_rc=$?
    post="$(sha256_file "$TMUX_CFG")"
    extra="$(jq -nc --arg source_log "$source_log" --argjson mutation "$mutation" '{mutated:$mutation,source_log:$source_log}')"
    payload="$(write_receipt "apply" "source-failed" "$pre" "$post" "$backup" "$source_rc" "$extra")"
    emit "$payload" "apply failed: tmux source-file rc=$source_rc" 1
    return 1
  }
  source_rc=0
  post="$(sha256_file "$TMUX_CFG")"
  extra="$(jq -nc --argjson mutation "$mutation" --arg source_log "$source_log" --arg scope "$REPAIR_SCOPE" '{mutated:$mutation,scope:$scope,source_log:$source_log}')"
  payload="$(write_receipt "apply" "ok" "$pre" "$post" "$backup" "$source_rc" "$extra")"
  emit "$payload" "apply ok: mutated=$mutation source_file_exit=0"
}

mode_revert() {
  local pre post backup source_log source_rc payload extra
  require_approval || return $?
  backup="$(ls -1t "${TMUX_CFG}".bak.tmux-tuning.* 2>/dev/null | head -n1 || true)"
  if [[ -z "$backup" ]]; then
    payload="$(jq -nc --arg schema_version "$SCHEMA_VERSION.revert" '{schema_version:$schema_version,status:"noop",reason:"no_backup_found"}')"
    emit "$payload" "revert noop: no backup found" 1
    return 1
  fi
  pre="$(sha256_file "$TMUX_CFG")"
  cp -p "$backup" "$TMUX_CFG"
  source_log="$("$TMUX_BIN" source-file "$TMUX_CFG" 2>&1)" || {
    source_rc=$?
    post="$(sha256_file "$TMUX_CFG")"
    extra="$(jq -nc --arg restored_from "$backup" --arg source_log "$source_log" '{restored_from:$restored_from,source_log:$source_log}')"
    payload="$(write_receipt "revert" "source-failed" "$pre" "$post" "$backup" "$source_rc" "$extra")"
    emit "$payload" "revert restored bytes but source-file failed" 1
    return 1
  }
  source_rc=0
  post="$(sha256_file "$TMUX_CFG")"
  extra="$(jq -nc --arg restored_from "$backup" --arg source_log "$source_log" '{restored_from:$restored_from,source_log:$source_log}')"
  payload="$(write_receipt "revert" "ok" "$pre" "$post" "$backup" "$source_rc" "$extra")"
  emit "$payload" "revert ok: restored_from=$backup"
}

mode_validate() {
  local stats payload
  stats="$(ledger_stats_json)"
  payload="$(jq -nc --arg schema_version "$SCHEMA_VERSION.validate" --arg ledger "$LEDGER" --argjson stats "$stats" \
    '{schema_version:$schema_version,ledger_path:$ledger,rows:$stats.rows,valid:$stats.valid,invalid:$stats.invalid,
      ledger_rows_valid:$stats.valid,ledger_rows_invalid:$stats.invalid}')"
  emit "$payload" "ledger valid=$(jq -r '.valid' <<<"$payload") invalid=$(jq -r '.invalid' <<<"$payload")"
}

mode_audit() {
  local payload
  if [[ ! -s "$LEDGER" ]]; then
    payload="$(jq -nc --arg schema_version "$SCHEMA_VERSION.audit" '{schema_version:$schema_version,rows:0,recent:[]}')"
  else
    payload="$(jq -s -c --arg schema_version "$SCHEMA_VERSION.audit" '{schema_version:$schema_version,rows:length,recent:.[-10:]}' "$LEDGER")"
  fi
  emit "$payload" "audit rows=$(jq -r '.rows' <<<"$payload")"
}

mode_why() {
  local payload text
  case "$WHY_KEY" in
    allow-passthrough)
      text="allow-passthrough on: enables tmux DCS passthrough for OSC 52 wrappers; Jeff corpus frankentui clipboard.rs lines 291-297."
      ;;
    set-clipboard)
      text="set-clipboard external: prevents tmux from owning clipboard while allowing external terminal clipboard flow; forbidden value is on."
      ;;
    terminal-features)
      text="terminal-features: aligns tmux advertisement with current xterm-256color client features and upstream tmux 3.6 OSC52/device-attribute improvements."
      ;;
    extended-keys)
      text="extended-keys on: tmux 3.5 revamped extended key support; current tmux is 3.6a."
      ;;
    history-limit)
      text="history-limit preserved at 100000 from 3099j; Jeff corpus recommends larger-than-default history but 250k is deferred pending RAM measurement."
      ;;
    aggressive-resize)
      text="aggressive-resize stays off: NTM uses pane shape and pane metadata; geometry churn is not worth the space gain."
      ;;
    *)
      text="unknown key: $WHY_KEY"
      ;;
  esac
  payload="$(jq -nc --arg schema_version "$SCHEMA_VERSION.why" --arg key "$WHY_KEY" --arg explanation "$text" '{schema_version:$schema_version,key:$key,explanation:$explanation}')"
  emit "$payload" "$text"
}

mode_schema() {
  local payload
  case "$SCHEMA_TOPIC" in
    config)
      payload="$(jq -nc --arg schema_version "$SCHEMA_VERSION.schema.config" '{schema_version:$schema_version,block_markers:["BEGIN apply-tmux-tuning (flywheel-2tmux)","END apply-tmux-tuning (flywheel-2tmux)"],mutation:"append or replace own block only"}')"
      ;;
    backup)
      payload="$(jq -nc --arg schema_version "$SCHEMA_VERSION.schema.backup" '{schema_version:$schema_version,naming:"~/.tmux.conf.bak.tmux-tuning.<iso-utc>",restore:"cp -p backup config",byte_exact:true}')"
      ;;
    ledger)
      payload="$(jq -nc --arg schema_version "$SCHEMA_VERSION.schema.ledger" --arg row_schema "$LEDGER_SCHEMA" '{schema_version:$schema_version,row_schema:$row_schema,required:["schema_version","version","ts","action","outcome","config_path","pre_sha256","post_sha256","current_block_sha","expected_block_sha"]}')"
      ;;
    *)
      echo "unknown schema topic: $SCHEMA_TOPIC" >&2
      return 2
      ;;
  esac
  emit "$payload"
}

mode_info() {
  # flywheel-1hshd.4: respect --json (was plain-text-only pre-scaffold).
  if [[ "$JSON_OUT" == "1" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg ver "$VERSION" --arg name "apply-tmux-tuning.sh" \
      --arg tmux "$TMUX_CFG" --arg ledger "$LEDGER" --arg bin "$TMUX_BIN" \
      '{
        schema_version: $sv,
        command: "info",
        name: $name,
        version: $ver,
        purpose: "reversible tmux 3.6a tuning for agent swarms",
        config: $tmux,
        ledger: $ledger,
        tmux_bin: $bin,
        donella_analysis: "/tmp/2tmux-donella-analysis-2026-05-05.md",
        bead: "flywheel-1q5yv",
        subcommands: ["doctor","health","repair","revert","validate","audit","why","schema","examples","quickstart","help","completion"],
        canonical_flags: ["--info","--schema","--examples","--json","--apply","--dry-run","--revert","--idempotency-key","--scope","--watch"],
        apply_supported: true,
        dry_run_supported: true,
        revert_supported: true,
        idempotency_key_required_for_apply: true
      }'
    return 0
  fi
  cat <<EOF
$VERSION
schema=$SCHEMA_VERSION
config=$TMUX_CFG
ledger=$LEDGER
tmux_bin=$TMUX_BIN
donella_analysis=/tmp/2tmux-donella-analysis-2026-05-05.md
bead=flywheel-1q5yv
EOF
}

mode_examples() {
  cat <<'EOF'
# Preview without mutation
apply-tmux-tuning.sh --json | jq .

# Apply to live ~/.tmux.conf
APPROVE=yes apply-tmux-tuning.sh --apply --json

# Revert the latest byte-exact backup
APPROVE=yes apply-tmux-tuning.sh --revert --json

# Inspect drift and ledger validity
apply-tmux-tuning.sh doctor --json
apply-tmux-tuning.sh validate ledger --json
apply-tmux-tuning.sh why allow-passthrough
EOF
}

mode_quickstart() {
  cat <<'EOF'
quickstart:
  1. apply-tmux-tuning.sh --json
  2. apply-tmux-tuning.sh doctor --json
  3. APPROVE=yes apply-tmux-tuning.sh --apply --json
  4. apply-tmux-tuning.sh validate ledger --json
  5. APPROVE=yes apply-tmux-tuning.sh --revert --json if needed
EOF
}

mode_help() {
  case "$HELP_TOPIC" in
    overview|"") usage ;;
    apply) echo "apply: requires APPROVE=yes, writes backup, replaces only own block, runs tmux source-file" ;;
    revert) echo "revert: requires APPROVE=yes, restores newest .bak.tmux-tuning backup byte-exactly" ;;
    doctor) echo "doctor: reports drift, block hashes, version compatibility, terminfo, ledger validity" ;;
    knobs) target_block ;;
    *) usage ;;
  esac
}

mode_completion() {
  case "$COMPLETION_SHELL" in
    zsh)
      cat <<'EOF'
#compdef apply-tmux-tuning.sh
_arguments \
  '--apply[apply tuning]' \
  '--revert[restore latest backup]' \
  '--json[JSON output]' \
  '--dry-run[dry-run repair]' \
  '--scope[repair scope]:scope:(config)' \
  '1:command:(doctor health repair validate audit why schema quickstart help completion)' \
  '2:topic:(ledger config backup allow-passthrough set-clipboard terminal-features extended-keys history-limit aggressive-resize overview apply revert doctor knobs zsh)'
EOF
      ;;
    bash)
      cat <<'EOF'
_apply_tmux_tuning() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "--apply --revert --json --dry-run --scope doctor health repair validate audit why schema quickstart help completion" -- "$cur") )
}
complete -F _apply_tmux_tuning apply-tmux-tuning.sh
EOF
      ;;
    *) echo "unknown shell: $COMPLETION_SHELL" >&2; return 2 ;;
  esac
}

parse_args() {
  if [[ $# -eq 0 ]]; then MODE="repair"; DRY_RUN=1; return 0; fi
  while [[ $# -gt 0 ]]; do
    case "$1" in
      doctor|health|repair|audit|quickstart) MODE="$1"; shift ;;
      validate) MODE="validate"; shift; [[ "${1:-}" == "ledger" ]] && shift || true ;;
      why) MODE="why"; WHY_KEY="${2:-}"; shift 2 ;;
      schema) MODE="schema"; SCHEMA_TOPIC="${2:-}"; shift 2 ;;
      # NEW (flywheel-1hshd.4): --schema dash-flag form + --idempotency-key.
      # Default topic is "config" (most useful for AG3 --schema --json probe).
      --schema)
        MODE="schema"
        if [[ $# -gt 1 && "${2:-}" != --* ]]; then SCHEMA_TOPIC="$2"; shift 2; else SCHEMA_TOPIC="config"; shift; fi
        ;;
      --schema=*) MODE="schema"; SCHEMA_TOPIC="${1#*=}"; shift ;;
      --idempotency-key) IDEMPOTENCY_KEY="${2:?--idempotency-key requires KEY}"; shift 2 ;;
      --idempotency-key=*) IDEMPOTENCY_KEY="${1#*=}"; shift ;;
      help) MODE="help"; HELP_TOPIC="${2:-overview}"; shift; [[ $# -gt 0 ]] && shift || true ;;
      completion) MODE="completion"; COMPLETION_SHELL="${2:-zsh}"; shift 2 ;;
      --apply) MODE="${MODE:-repair}"; APPLY=1; DRY_RUN=0; shift ;;
      --dry-run) MODE="${MODE:-repair}"; DRY_RUN=1; APPLY=0; shift ;;
      --revert) MODE="revert"; shift ;;
      --scope) REPAIR_SCOPE="${2:-config}"; shift 2 ;;
      --json) JSON_OUT=1; shift ;;
      --watch) WATCH=1; shift ;;
      --info) MODE="info"; shift ;;
      --examples) MODE="examples"; shift ;;
      --no-color) NO_COLOR=1; shift ;;
      --no-emoji) NO_EMOJI=1; shift ;;
      --width) WIDTH="${2:-100}"; shift 2 ;;
      -h|--help) MODE="help"; shift ;;
      *) echo "unknown arg: $1" >&2; usage >&2; return 2 ;;
    esac
  done
  [[ -n "$MODE" ]] || MODE="repair"
}

main() {
  parse_args "$@" || exit $?
  case "$REPAIR_SCOPE" in config|tmux|all) ;; *) echo "unknown scope: $REPAIR_SCOPE" >&2; exit 2 ;; esac
  # NEW (flywheel-1hshd.4): canonical apply contract — --apply on
  # repair/revert MODE requires --idempotency-key (canonical-cli L7).
  if [[ "$APPLY" == "1" && -z "$IDEMPOTENCY_KEY" ]]; then
    case "$MODE" in
      repair|revert)
        printf '{"schema_version":"%s","status":"refused","mode":"apply","reason":"--apply requires --idempotency-key KEY (canonical apply contract)","exit_code":3}\n' "$SCHEMA_VERSION"
        exit 3
        ;;
    esac
  fi
  case "$MODE" in
    doctor) mode_doctor ;;
    health) mode_health ;;
    repair) mode_repair ;;
    revert) mode_revert ;;
    validate) mode_validate ;;
    audit) mode_audit ;;
    why) mode_why ;;
    schema) mode_schema ;;
    info) mode_info ;;
    examples) mode_examples ;;
    quickstart) mode_quickstart ;;
    help) mode_help ;;
    completion) mode_completion ;;
    *) usage; exit 2 ;;
  esac
}

main "$@"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-63-phase-tick-bounded-action.md`
