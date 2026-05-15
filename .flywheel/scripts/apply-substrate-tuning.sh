#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial → passing per bead flywheel-1hshd.3)
# apply-substrate-tuning.sh — wezterm + tmux substrate tuning for codex swarm freeze prevention
#
# Bead: flywheel-3099j (P0 wire-or-explain)
# Doctrine source: ~/.claude/skills/wezterm/references/PERFORMANCE-TUNING.md §"The Agent Swarm Problem"
# Donella analysis: /tmp/3099j-donella-analysis-2026-05-05.md (Winner D3)
#
# Canonical-cli-scoping triad:
#   doctor / health / repair  (substrate scopes)
#   validate / audit / why    (truth scopes)
#   --info / --examples / quickstart / help / completion  (meta scopes)
#
# Default --dry-run; explicit --apply to mutate; --revert restores pre-image.
# All mutations are reversible. Receipts written via fw_jsonl_append_validated.

set -euo pipefail

VERSION="apply-substrate-tuning.v1.0.0"
SCHEMA_VERSION="substrate-tuning.v1"
# shellcheck disable=SC2034 # Kept for compatibility with sourced/operator probes.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

WEZTERM_CFG="${SUBSTRATE_TUNING_WEZTERM:-$HOME/.config/wezterm/wezterm.lua}"
TMUX_CFG="${SUBSTRATE_TUNING_TMUX:-$HOME/.tmux.conf}"
LEDGER="${SUBSTRATE_TUNING_LEDGER:-$HOME/.local/state/flywheel/substrate-tuning.jsonl}"
JSONL_APPEND_LIB="${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"

MODE=""
APPLY=0
DRY_RUN=1
JSON_OUT=0
REPAIR_SCOPE="all"
SCHEMA_TOPIC=""
WHY_KEY=""
COMPLETION_SHELL=""
# NEW (flywheel-1hshd.3): --idempotency-key for canonical apply contract
# (L7 lint rule). Apply-mode refuses with rc=3 when key absent.
IDEMPOTENCY_KEY=""
declare -a SUBSTRATE_TUNING_TEMP_FILES=()

register_temp_file() {
  SUBSTRATE_TUNING_TEMP_FILES+=("$1")
}

cleanup_temp_files() {
  local tmp
  for tmp in "${SUBSTRATE_TUNING_TEMP_FILES[@]}"; do
    [[ -n "$tmp" ]] || continue
    rm -f "$tmp"
  done
  return 0
}

trap cleanup_temp_files EXIT ERR

usage() {
  cat <<'EOF'
usage:
  apply-substrate-tuning.sh --doctor [--json]
  apply-substrate-tuning.sh --health [--json]
  apply-substrate-tuning.sh --repair [--scope all|wezterm|tmux] [--dry-run|--apply] [--json]
  apply-substrate-tuning.sh --apply [--json]            # alias of --repair --apply
  apply-substrate-tuning.sh --dry-run [--json]          # alias of --repair --dry-run
  apply-substrate-tuning.sh --revert [--json]
  apply-substrate-tuning.sh validate [--json]
  apply-substrate-tuning.sh audit [--json]
  apply-substrate-tuning.sh why KEY [--json]
  apply-substrate-tuning.sh schema receipt|tuning [--json]
  apply-substrate-tuning.sh --info | --examples | quickstart | help [TOPIC] | completion bash|zsh

Doctrine: ~/.claude/skills/wezterm/references/PERFORMANCE-TUNING.md
Donella analysis: /tmp/3099j-donella-analysis-2026-05-05.md
EOF
}

now_iso() { printf '%s\n' "${SUBSTRATE_TUNING_NOW:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"; }

sha256() {
  if [[ -f "$1" ]]; then shasum -a 256 "$1" | awk '{print $1}'; else printf 'absent\n'; fi
}

ram_gb() {
  local bytes
  bytes=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
  echo $(( bytes / 1024 / 1024 / 1024 ))
}

wezterm_version_ok() {
  if ! command -v wezterm >/dev/null 2>&1; then echo "no_wezterm"; return 1; fi
  local v
  v=$(wezterm --version 2>/dev/null | awk '{print $2}')
  # Accept dated versions YYYYMMDD-* >= 20230101
  if [[ "$v" =~ ^([0-9]{8}) ]]; then
    local d="${BASH_REMATCH[1]}"
    if (( d >= 20230101 )); then echo "ok"; return 0; fi
  fi
  echo "incompat:$v"
  return 1
}

tmux_version_ok() {
  if ! command -v tmux >/dev/null 2>&1; then echo "no_tmux"; return 1; fi
  local v
  v=$(tmux -V 2>/dev/null | awk '{print $2}' | tr -d 'a-zA-Z')
  # Accept tmux >= 3.0
  local major="${v%%.*}"
  if [[ "$major" =~ ^[0-9]+$ ]] && (( major >= 3 )); then echo "ok"; return 0; fi
  echo "incompat:$v"
  return 1
}

# -----------------------------------------------------------------------------
# Target config blocks (D3 winner from Donella)
# -----------------------------------------------------------------------------

WEZTERM_BLOCK_BEGIN="-- BEGIN apply-substrate-tuning (flywheel-3099j) ---------------------------"
WEZTERM_BLOCK_END="-- END apply-substrate-tuning (flywheel-3099j) -----------------------------"

wezterm_target_block() {
  cat <<LUA
$WEZTERM_BLOCK_BEGIN
-- Source: ~/.claude/skills/wezterm/references/PERFORMANCE-TUNING.md (512GB profile)
-- Donella: /tmp/3099j-donella-analysis-2026-05-05.md (winner D3)
-- Prevents codex swarm freeze cascade: parser-buffer fill -> coalesce-lag -> hang.
config.scrollback_lines = 10000000
config.mux_output_parser_buffer_size = 16 * 1024 * 1024
config.mux_output_parser_coalesce_delay_ms = 1
config.ratelimit_mux_line_prefetches_per_second = 1000
config.shape_cache_size = 65536
config.line_state_cache_size = 65536
config.line_quad_cache_size = 65536
config.line_to_ele_shape_cache_size = 65536
config.glyph_cache_image_cache_size = 4096
$WEZTERM_BLOCK_END
LUA
}

TMUX_BLOCK_BEGIN="# BEGIN apply-substrate-tuning (flywheel-3099j) -----------------------------"
TMUX_BLOCK_END="# END apply-substrate-tuning (flywheel-3099j) -------------------------------"

tmux_target_block() {
  cat <<TMUX
$TMUX_BLOCK_BEGIN
# Source: PERFORMANCE-TUNING.md + Donella D3 winner.
# Raise history-limit (consumer side) and tighten status redraw under swarm load.
set-option -g history-limit 100000
set-option -g status-interval 5
set-option -g focus-events on
$TMUX_BLOCK_END
TMUX
}

# -----------------------------------------------------------------------------
# Block presence detection
# -----------------------------------------------------------------------------

wezterm_block_present() {
  [[ -f "$WEZTERM_CFG" ]] && grep -qF -e "$WEZTERM_BLOCK_BEGIN" "$WEZTERM_CFG"
}
tmux_block_present() {
  [[ -f "$TMUX_CFG" ]] && grep -qF -e "$TMUX_BLOCK_BEGIN" "$TMUX_CFG"
}

# -----------------------------------------------------------------------------
# Backup / mutation
# -----------------------------------------------------------------------------

backup_path() {
  # $1=file, $2=ts
  printf '%s.bak.substrate-tuning.%s\n' "$1" "$2"
}

mutate_wezterm() {
  # Inject block before `return config` (wezterm idiom). If pattern absent, append.
  local target="$1"
  local block_file="$2"
  local tmp
  tmp="$(mktemp -t apply-substrate-tuning-wez.XXXXXX)"
  register_temp_file "$tmp"
  if grep -q '^return config' "$target"; then
    awk -v block_file="$block_file" '
      BEGIN { while ((getline line < block_file) > 0) block = block (block?"\n":"") line; close(block_file) }
      /^return config/ && !done { print block; done=1 }
      { print }
    ' "$target" > "$tmp"
  else
    cat "$target" > "$tmp"
    printf '\n' >> "$tmp"
    cat "$block_file" >> "$tmp"
  fi
  mv "$tmp" "$target"
}

mutate_tmux() {
  local target="$1"
  local block_file="$2"
  printf '\n' >> "$target"
  cat "$block_file" >> "$target"
}

remove_block() {
  local target="$1" begin="$2" end="$3"
  local tmp
  tmp="$(mktemp -t apply-substrate-tuning-rm.XXXXXX)"
  register_temp_file "$tmp"
  awk -v b="$begin" -v e="$end" '
    index($0, b) { skip=1; next }
    index($0, e) { skip=0; next }
    !skip
  ' "$target" > "$tmp"
  mv "$tmp" "$target"
}

# -----------------------------------------------------------------------------
# Receipt
# -----------------------------------------------------------------------------

write_receipt() {
  # args: action outcome wez_pre wez_post tmux_pre tmux_post extra_json
  local action="$1" outcome="$2"
  local wpre="$3" wpost="$4" tpre="$5" tpost="$6"
  local extra="${7-}"
  [[ -z "$extra" ]] && extra='{}'
  local row
  row=$(jq -nc \
    --arg sv "$SCHEMA_VERSION" \
    --arg ver "$VERSION" \
    --arg ts "$(now_iso)" \
    --arg action "$action" \
    --arg outcome "$outcome" \
    --arg wpre "$wpre" --arg wpost "$wpost" \
    --arg tpre "$tpre" --arg tpost "$tpost" \
    --arg wcfg "$WEZTERM_CFG" --arg tcfg "$TMUX_CFG" \
    --argjson ram "$(ram_gb)" \
    --argjson extra "$extra" \
    '{schema_version:$sv, version:$ver, ts:$ts, action:$action, outcome:$outcome,
      wezterm_cfg:$wcfg, tmux_cfg:$tcfg,
      wezterm_pre_sha256:$wpre, wezterm_post_sha256:$wpost,
      tmux_pre_sha256:$tpre, tmux_post_sha256:$tpost,
      ram_gb:$ram, profile:"512gb"} + $extra')
  mkdir -p "$(dirname "$LEDGER")"
  if [[ -r "$JSONL_APPEND_LIB" ]]; then
    # shellcheck source=/dev/null
    source "$JSONL_APPEND_LIB"
    fw_jsonl_append_validated "$LEDGER" "$row" || {
      printf 'receipt-append-failed\n' >&2
      return 2
    }
  else
    printf '%s\n' "$row" >> "$LEDGER"
  fi
  printf '%s\n' "$row"
}

# -----------------------------------------------------------------------------
# Modes
# -----------------------------------------------------------------------------

mode_doctor() {
  local wezv tmxv
  wezv=$(wezterm_version_ok || true)
  tmxv=$(tmux_version_ok || true)
  local wpresent="false" tpresent="false"
  wezterm_block_present && wpresent="true"
  tmux_block_present && tpresent="true"
  local out
  out=$(jq -nc \
    --arg sv "$SCHEMA_VERSION" --arg ver "$VERSION" \
    --arg ts "$(now_iso)" \
    --arg wezv "$wezv" --arg tmxv "$tmxv" \
    --arg wsha "$(sha256 "$WEZTERM_CFG")" \
    --arg tsha "$(sha256 "$TMUX_CFG")" \
    --argjson wpres "$wpresent" --argjson tpres "$tpresent" \
    --argjson ram "$(ram_gb)" \
    '{schema_version:$sv, version:$ver, ts:$ts, scope:"doctor",
      wezterm_version_check:$wezv, tmux_version_check:$tmxv,
      wezterm_sha256:$wsha, tmux_sha256:$tsha,
      wezterm_block_present:$wpres, tmux_block_present:$tpres,
      ram_gb:$ram, target_profile:"512gb",
      drift: ((($wpres|not) or ($tpres|not)))}')
  if [[ "$JSON_OUT" == "1" ]]; then
    printf '%s\n' "$out"
  else
    printf '%s\n' "$out" | jq .
  fi
}

mode_health() { mode_doctor; }

mode_repair() {
  local wezv tmxv
  wezv=$(wezterm_version_ok) || { printf '{"outcome":"refuse","reason":"%s"}\n' "$wezv" >&2; return 1; }
  tmxv=$(tmux_version_ok) || { printf '{"outcome":"refuse","reason":"%s"}\n' "$tmxv" >&2; return 1; }

  local ts; ts=$(now_iso)
  local wpre tpre wpost tpost
  wpre=$(sha256 "$WEZTERM_CFG"); tpre=$(sha256 "$TMUX_CFG")

  if [[ "$DRY_RUN" == "1" ]]; then
    local diff_w diff_t
    if [[ -f "$WEZTERM_CFG" ]] && ! wezterm_block_present; then
      diff_w=$(wezterm_target_block | wc -l | tr -d ' ')
    else diff_w=0; fi
    if [[ -f "$TMUX_CFG" ]] && ! tmux_block_present; then
      diff_t=$(tmux_target_block | wc -l | tr -d ' ')
    else diff_t=0; fi
    write_receipt "dry-run" "noop" "$wpre" "$wpre" "$tpre" "$tpre" \
      "$(jq -nc --argjson dw "$diff_w" --argjson dt "$diff_t" '{wezterm_lines_to_add:$dw, tmux_lines_to_add:$dt}')" \
      | { if [[ "$JSON_OUT" == "1" ]]; then cat; else jq .; fi; }
    return 0
  fi

  # APPLY path — backup first (skip if block already present to preserve pre-image)
  local wbak="" tbak=""
  if [[ "$REPAIR_SCOPE" == "all" || "$REPAIR_SCOPE" == "wezterm" ]] && [[ -f "$WEZTERM_CFG" ]] && ! wezterm_block_present; then
    wbak=$(backup_path "$WEZTERM_CFG" "$ts")
    # If a backup with this exact timestamp already exists, suffix with PID to avoid clobber
    [[ -e "$wbak" ]] && wbak="${wbak}.$$"
    cp -p "$WEZTERM_CFG" "$wbak"
  fi
  if [[ "$REPAIR_SCOPE" == "all" || "$REPAIR_SCOPE" == "tmux" ]] && [[ -f "$TMUX_CFG" ]] && ! tmux_block_present; then
    tbak=$(backup_path "$TMUX_CFG" "$ts")
    [[ -e "$tbak" ]] && tbak="${tbak}.$$"
    cp -p "$TMUX_CFG" "$tbak"
  fi

  local wblk tblk
  wblk=$(mktemp -t apply-substrate-tuning-wezblk.XXXXXX)
  tblk=$(mktemp -t apply-substrate-tuning-tmxblk.XXXXXX)
  register_temp_file "$wblk"
  register_temp_file "$tblk"
  wezterm_target_block > "$wblk"
  tmux_target_block > "$tblk"

  if [[ "$REPAIR_SCOPE" == "all" || "$REPAIR_SCOPE" == "wezterm" ]]; then
    if ! wezterm_block_present; then
      mutate_wezterm "$WEZTERM_CFG" "$wblk"
    fi
  fi
  if [[ "$REPAIR_SCOPE" == "all" || "$REPAIR_SCOPE" == "tmux" ]]; then
    if ! tmux_block_present; then
      mutate_tmux "$TMUX_CFG" "$tblk"
    fi
  fi
  rm -f "$wblk" "$tblk"

  wpost=$(sha256 "$WEZTERM_CFG"); tpost=$(sha256 "$TMUX_CFG")
  write_receipt "apply" "ok" "$wpre" "$wpost" "$tpre" "$tpost" \
    "$(jq -nc --arg wb "$wbak" --arg tb "$tbak" --arg sc "$REPAIR_SCOPE" \
      '{wezterm_backup:$wb, tmux_backup:$tb, scope:$sc}')" \
    | { if [[ "$JSON_OUT" == "1" ]]; then cat; else jq .; fi; }
}

mode_revert() {
  # Find newest backups
  local wbak tbak
  # shellcheck disable=SC2012 # Backup names are generated by this script and timestamp-sortable.
  wbak=$(ls -1t "${WEZTERM_CFG}".bak.substrate-tuning.* 2>/dev/null | head -n1 || true)
  # shellcheck disable=SC2012 # Backup names are generated by this script and timestamp-sortable.
  tbak=$(ls -1t "${TMUX_CFG}".bak.substrate-tuning.* 2>/dev/null | head -n1 || true)
  if [[ -z "$wbak" && -z "$tbak" ]]; then
    printf '{"outcome":"noop","reason":"no_backups_found"}\n' >&2
    return 1
  fi
  local wpre tpre wpost tpost
  wpre=$(sha256 "$WEZTERM_CFG"); tpre=$(sha256 "$TMUX_CFG")
  if [[ -n "$wbak" && "$REPAIR_SCOPE" =~ ^(all|wezterm)$ ]]; then
    cp -p "$wbak" "$WEZTERM_CFG"
  fi
  if [[ -n "$tbak" && "$REPAIR_SCOPE" =~ ^(all|tmux)$ ]]; then
    cp -p "$tbak" "$TMUX_CFG"
  fi
  # Defensive: if backup didn't have the block (shouldn't), strip leftover blocks too.
  if wezterm_block_present; then remove_block "$WEZTERM_CFG" "$WEZTERM_BLOCK_BEGIN" "$WEZTERM_BLOCK_END"; fi
  if tmux_block_present; then remove_block "$TMUX_CFG" "$TMUX_BLOCK_BEGIN" "$TMUX_BLOCK_END"; fi
  wpost=$(sha256 "$WEZTERM_CFG"); tpost=$(sha256 "$TMUX_CFG")
  write_receipt "revert" "ok" "$wpre" "$wpost" "$tpre" "$tpost" \
    "$(jq -nc --arg wb "$wbak" --arg tb "$tbak" '{wezterm_restored_from:$wb, tmux_restored_from:$tb}')" \
    | { if [[ "$JSON_OUT" == "1" ]]; then cat; else jq .; fi; }
}

mode_validate() {
  # validate ledger schema
  if [[ ! -s "$LEDGER" ]]; then
    printf '{"outcome":"empty","ledger":"%s"}\n' "$LEDGER"
    return 0
  fi
  local rows ok bad
  rows=$(wc -l < "$LEDGER" | tr -d ' ')
  ok=0; bad=0
  while IFS= read -r line; do
    if jq -e --arg sv "$SCHEMA_VERSION" 'select(type=="object") | .schema_version == $sv' >/dev/null 2>&1 <<<"$line"; then
      ok=$((ok+1))
    else
      bad=$((bad+1))
    fi
  done < "$LEDGER"
  jq -nc --argjson rows "$rows" --argjson ok "$ok" --argjson bad "$bad" \
    '{rows:$rows, valid:$ok, invalid:$bad, schema_version:"substrate-tuning.v1"}'
}

mode_audit() {
  # Summarize ledger by action
  if [[ ! -s "$LEDGER" ]]; then
    printf '{"outcome":"empty"}\n'; return 0
  fi
  jq -s 'group_by(.action) | map({action: .[0].action, count: length, last_ts: (max_by(.ts).ts)})' "$LEDGER"
}

mode_why() {
  case "$WHY_KEY" in
    scrollback_lines)
      echo "scrollback_lines=10000000: 512GB RAM tier per PERFORMANCE-TUNING.md; cargo build can produce 10K+ lines and agent debug needs full history. Memory math: ~6 bytes/line * 10M * 24 panes ~= 1.4GB.";;
    mux_output_parser_buffer_size)
      echo "16MB parser buffer: 24-pane swarm at 1000+ lines/sec saturates 128KB default; root cause of cascade in PERFORMANCE-TUNING.md §The Failure Cascade.";;
    mux_output_parser_coalesce_delay_ms)
      echo "1ms coalesce: default 3ms accumulates 3sec lag at 1000 chunks/sec. Agent swarm prefers minimum lag over batching.";;
    ratelimit_mux_line_prefetches_per_second)
      echo "1000 prefetches/sec: default 50/sec means 200sec to scroll 10K lines. Agent debug requires fast scrollback.";;
    history-limit)
      echo "tmux history-limit 100000: doubled from 50000; tmux pane history is consumer-side counterpart to wezterm scrollback.";;
    status-interval)
      echo "status-interval=5 (default 15): faster status redraw improves perceived liveness under swarm load; minor CPU cost.";;
    focus-events)
      echo "focus-events on: ensures codex prompt focus events propagate through tmux to wezterm so frozen-pane detector can read accurate cursor state.";;
    *) echo "unknown key: $WHY_KEY (try: scrollback_lines mux_output_parser_buffer_size mux_output_parser_coalesce_delay_ms ratelimit_mux_line_prefetches_per_second history-limit status-interval focus-events)";;
  esac
}

mode_schema() {
  case "$SCHEMA_TOPIC" in
    receipt|tuning)
      jq -nc --arg sv "$SCHEMA_VERSION" '{
        schema_version: $sv,
        fields: {
          schema_version: "string",
          version: "string",
          ts: "ISO-8601 UTC",
          action: "apply|revert|dry-run|doctor",
          outcome: "ok|fail|noop|refuse",
          wezterm_cfg: "path",
          tmux_cfg: "path",
          wezterm_pre_sha256: "sha256 hex or absent",
          wezterm_post_sha256: "sha256 hex or absent",
          tmux_pre_sha256: "sha256 hex or absent",
          tmux_post_sha256: "sha256 hex or absent",
          ram_gb: "int",
          profile: "string"
        }
      }';;
    *) echo "unknown schema topic: $SCHEMA_TOPIC (try: receipt|tuning)"; return 1;;
  esac
}

mode_info() {
  # flywheel-1hshd.3: respect --json (was plain-text-only pre-scaffold).
  # AG3 introspection requires JSON envelope with name/version/subcommands.
  if [[ "$JSON_OUT" == "1" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg ver "$VERSION" --arg name "apply-substrate-tuning.sh" \
      --arg wezterm "$WEZTERM_CFG" --arg tmux "$TMUX_CFG" --arg ledger "$LEDGER" \
      '{
        schema_version: $sv,
        command: "info",
        name: $name,
        version: $ver,
        purpose: "wezterm + tmux substrate tuning for codex swarm freeze prevention",
        targets: { wezterm: $wezterm, tmux: $tmux },
        ledger: $ledger,
        profile: "512GB (Mac Studio)",
        doctrine: "~/.claude/skills/wezterm/references/PERFORMANCE-TUNING.md",
        donella_analysis: "/tmp/3099j-donella-analysis-2026-05-05.md",
        bead: "flywheel-3099j",
        subcommands: ["doctor","health","repair","revert","validate","audit","why","schema","examples","quickstart","help","completion"],
        canonical_flags: ["--info","--schema","--examples","--json","--apply","--dry-run","--revert","--idempotency-key"],
        apply_supported: true,
        dry_run_supported: true,
        revert_supported: true,
        idempotency_key_required_for_apply: true
      }'
    return 0
  fi
  cat <<EOF
$VERSION
Schema: $SCHEMA_VERSION
Targets: $WEZTERM_CFG, $TMUX_CFG
Ledger: $LEDGER
Profile: 512GB (Mac Studio, this machine)
Doctrine: ~/.claude/skills/wezterm/references/PERFORMANCE-TUNING.md
Donella analysis: /tmp/3099j-donella-analysis-2026-05-05.md
Bead: flywheel-3099j
EOF
}

mode_examples() {
  cat <<'EOF'
# 1) Probe drift
apply-substrate-tuning.sh --doctor --json | jq .drift

# 2) Preview changes
apply-substrate-tuning.sh --dry-run

# 3) Apply
apply-substrate-tuning.sh --apply

# 4) Revert latest
apply-substrate-tuning.sh --revert

# 5) Validate ledger
apply-substrate-tuning.sh validate --json

# 6) Why a specific key
apply-substrate-tuning.sh why mux_output_parser_buffer_size
EOF
}

mode_quickstart() {
  cat <<'EOF'
quickstart:
  1. apply-substrate-tuning.sh --doctor --json   # check drift
  2. apply-substrate-tuning.sh --dry-run          # preview
  3. apply-substrate-tuning.sh --apply            # mutate (backups auto-written)
  4. Restart wezterm-mux: pkill -9 -f wezterm-mux; wezterm-mux-server --daemonize
  5. tmux source-file ~/.tmux.conf                # reload tmux
  6. apply-substrate-tuning.sh --revert           # undo if needed
EOF
}

mode_help() {
  case "${1:-overview}" in
    overview|"") usage;;
    apply) echo "--apply mutates configs; auto-writes timestamped backups; writes apply receipt";;
    revert) echo "--revert restores latest backup pair; writes revert receipt";;
    doctor) echo "--doctor reports drift between current configs and target tuning block";;
    *) usage;;
  esac
}

mode_completion() {
  case "$COMPLETION_SHELL" in
    bash)
      cat <<'EOF'
_apply_substrate_tuning() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local opts="--doctor --health --repair --apply --dry-run --revert validate audit why schema --info --examples quickstart help completion --json --scope"
  COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}
complete -F _apply_substrate_tuning apply-substrate-tuning.sh
EOF
      ;;
    zsh)
      cat <<'EOF'
#compdef apply-substrate-tuning.sh
_arguments \
  '--doctor[doctor mode]' \
  '--health[health mode]' \
  '--repair[repair mode]' \
  '--apply[mutate]' \
  '--dry-run[preview]' \
  '--revert[restore backup]' \
  '--json[machine-readable output]' \
  '--scope[scope]:scope:(all wezterm tmux)' \
  'validate[validate ledger]' \
  'audit[audit ledger]' \
  'why[explain key]:key:' \
  'schema[print schema]:topic:(receipt tuning)' \
  '--info[version info]' \
  '--examples[usage examples]' \
  'quickstart[quick start]' \
  'help[help]' \
  'completion[completions]:shell:(bash zsh)'
EOF
      ;;
    *) echo "unknown shell: $COMPLETION_SHELL"; return 1;;
  esac
}

# -----------------------------------------------------------------------------
# Arg parsing
# -----------------------------------------------------------------------------

if [[ $# -eq 0 ]]; then usage; exit 0; fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --doctor) MODE="doctor"; shift;;
    --health) MODE="health"; shift;;
    --repair) MODE="repair"; shift;;
    --apply) MODE="${MODE:-repair}"; APPLY=1; DRY_RUN=0; shift;;
    --dry-run) MODE="${MODE:-repair}"; DRY_RUN=1; APPLY=0; shift;;
    --revert) MODE="revert"; shift;;
    --scope) REPAIR_SCOPE="$2"; shift 2;;
    --json) JSON_OUT=1; shift;;
    --info) MODE="info"; shift;;
    --examples) MODE="examples"; shift;;
    quickstart) MODE="quickstart"; shift;;
    help) MODE="help"; shift; HELP_TOPIC="${1:-overview}"; [[ $# -gt 0 ]] && shift || true;;
    completion) MODE="completion"; COMPLETION_SHELL="${2:-bash}"; shift 2 || shift;;
    validate) MODE="validate"; shift;;
    audit) MODE="audit"; shift;;
    why) MODE="why"; WHY_KEY="${2:-}"; shift 2 || shift;;
    schema) MODE="schema"; SCHEMA_TOPIC="${2:-receipt}"; shift 2 || shift;;
    # NEW (flywheel-1hshd.3): --schema dash-flag form for AG3 introspection
    # parity with existing `schema <topic>` positional. Defaults topic to
    # "receipt"; supports --schema=<topic>= form. Note: --schema --json
    # treats "--json" as not-a-topic via the prefix check.
    --schema)
      MODE="schema"
      if [[ $# -gt 1 && "${2:-}" != --* ]]; then SCHEMA_TOPIC="$2"; shift 2; else SCHEMA_TOPIC="receipt"; shift; fi
      ;;
    --schema=*) MODE="schema"; SCHEMA_TOPIC="${1#*=}"; shift;;
    # NEW (flywheel-1hshd.3): --idempotency-key for AG3 apply contract.
    --idempotency-key) IDEMPOTENCY_KEY="${2:?--idempotency-key requires KEY}"; shift 2;;
    --idempotency-key=*) IDEMPOTENCY_KEY="${1#*=}"; shift;;
    -h|--help) usage; exit 0;;
    *) echo "unknown arg: $1" >&2; usage; exit 2;;
  esac
done

# NEW (flywheel-1hshd.3): apply-contract gate. When MODE is repair/revert
# AND --apply was given, --idempotency-key is required (canonical-cli L7 rule
# + AG3 apply contract rc=3). Default --dry-run path is unaffected.
if [[ "$APPLY" == "1" && -z "$IDEMPOTENCY_KEY" ]]; then
  case "$MODE" in
    repair|revert)
      printf '{"schema_version":"%s","status":"refused","mode":"apply","reason":"--apply requires --idempotency-key KEY (canonical apply contract)","exit_code":3}\n' "$SCHEMA_VERSION"
      exit 3
      ;;
  esac
fi

case "$MODE" in
  doctor) mode_doctor;;
  health) mode_health;;
  repair) mode_repair;;
  revert) mode_revert;;
  validate) mode_validate;;
  audit) mode_audit;;
  why) mode_why;;
  schema) mode_schema;;
  info) mode_info;;
  examples) mode_examples;;
  quickstart) mode_quickstart;;
  help) mode_help "${HELP_TOPIC:-overview}";;
  completion) mode_completion;;
  "") usage; exit 0;;
  *) echo "no mode set" >&2; usage; exit 2;;
esac
