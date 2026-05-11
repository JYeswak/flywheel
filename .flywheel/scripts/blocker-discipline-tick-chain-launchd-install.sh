#!/usr/bin/env bash
# blocker-discipline-tick-chain-launchd-install.sh
# flywheel-cli-surface: true
#
# Installer for the launchd wire-in shipped by flywheel-tlclp. Symlinks the
# canonical plist at .flywheel/launchd/ into ~/Library/LaunchAgents/ and
# bootstraps it under gui/$UID. Idempotent on re-runs; safe to invoke under
# `--apply --idempotency-key <key>`.
#
# Source bead: flywheel-tlclp (P2)
# Sister chain: blocker-discipline-tick-chain.sh (yy9qi)

set -euo pipefail

SCHEMA_VERSION="blocker-discipline-tick-chain-launchd-install/v1"
VERSION="0.1.0"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
HELPER_LIB="${HELPER_LIB:-$REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$HELPER_LIB"
fi

LABEL="${BLOCKER_TICK_CHAIN_LABEL:-ai.zeststream.flywheel-blocker-discipline-tick-chain}"
SOURCE_PLIST="${BLOCKER_TICK_CHAIN_SOURCE_PLIST:-$REPO_ROOT/.flywheel/launchd/$LABEL.plist}"
LAUNCH_AGENTS_DIR="${BLOCKER_TICK_CHAIN_LAUNCH_AGENTS_DIR:-$HOME/Library/LaunchAgents}"
TARGET_PLIST="$LAUNCH_AGENTS_DIR/$LABEL.plist"
DOMAIN="${BLOCKER_TICK_CHAIN_DOMAIN:-gui/$UID}"
LAUNCHCTL="${BLOCKER_TICK_CHAIN_LAUNCHCTL:-launchctl}"
WATCHERS_BIN="${BLOCKER_TICK_CHAIN_WATCHERS_BIN:-$HOME/.local/bin/flywheel-watchers}"
BEAD_ID="${BLOCKER_TICK_CHAIN_BEAD_ID:-flywheel-tlclp}"
AUDIT_LOG="${BLOCKER_TICK_CHAIN_AUDIT_LOG:-$HOME/.local/state/flywheel/blocker-discipline-tick-chain-install-runs.jsonl}"

JSON_OUT=0
APPLY=0
IDEMPOTENCY_KEY=""
MODE=""

usage() {
  cat <<'USG'
usage: blocker-discipline-tick-chain-launchd-install.sh <subcommand> [OPTIONS]

Subcommands:
  doctor [--json]           probe substrate (source plist present, plutil-valid)
  health [--json]           loaded-state probe (launchctl print)
  validate [--json]         compose-tests both source and target plist parse
  apply --idempotency-key K bootstrap LaunchAgent (symlink + launchctl bootstrap)
  unload [--json]           launchctl bootout (idempotent)
  audit [--tail N] [--json] tail install/uninstall audit log

Introspection:
  --info --json             metadata envelope (name, version, capabilities)
  --schema [<surface>]      JSON Schema for envelopes
  --examples --json         curated workflow examples
  --help / -h               this help

Mutation discipline:
  --dry-run is the default for apply/unload; supply --apply to mutate.
  apply REQUIRES --idempotency-key <key> to prevent accidental re-bootstraps.

Source bead: flywheel-tlclp
USG
}

# ----- helpers -----

iso_now() {
  if command -v cli_iso_now >/dev/null; then cli_iso_now; else date -u +'%Y-%m-%dT%H:%M:%SZ'; fi
}

audit_append() {
  local action="$1" status="$2" extra="${3:-{}}"
  if command -v cli_audit_append >/dev/null; then
    cli_audit_append "$AUDIT_LOG" "$action" "$status" "$extra"
    return
  fi
  mkdir -p "$(dirname "$AUDIT_LOG")"
  jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$(iso_now)" --arg action "$action" --arg status "$status" --argjson extra "$extra" \
    '{schema_version:$sv, ts:$ts, action:$action, status:$status, extra:$extra}' >>"$AUDIT_LOG"
}

plist_valid() {
  command -v plutil >/dev/null || return 0
  plutil -lint -s "$1" >/dev/null 2>&1
}

loaded() {
  "$LAUNCHCTL" print "$DOMAIN/$LABEL" >/dev/null 2>&1
}

ensure_watcher_registered() {
  [[ -x "$WATCHERS_BIN" ]] || return 0
  if "$WATCHERS_BIN" registry --json 2>/dev/null | jq -e --arg label "$LABEL" '.active[]? | select(.label == $label and (.active // true))' >/dev/null 2>&1; then
    printf 'noop_already_registered'
    return 0
  fi
  if "$WATCHERS_BIN" register \
        --label "$LABEL" \
        --owner flywheel-orch \
        --reason "blocker-discipline tick chain hourly cadence per yy9qi" \
        --bead "$BEAD_ID" \
        --apply \
        --idempotency-key "tlclp-launchd-${LABEL}" \
        --json >/dev/null 2>&1; then
    printf 'registered'
    return 0
  fi
  printf 'register_failed'
  return 1
}

# ----- subcommand: doctor -----

cmd_doctor() {
  local checks=()
  local status="ok"
  if [[ -r "$SOURCE_PLIST" ]]; then
    checks+=("$(jq -nc --arg c "source_plist_present" --arg s "ok" --arg d "$SOURCE_PLIST" '{check:$c,status:$s,detail:$d}')")
  else
    checks+=("$(jq -nc --arg c "source_plist_present" --arg s "fail" --arg d "$SOURCE_PLIST not readable" '{check:$c,status:$s,detail:$d}')")
    status="fail"
  fi
  if [[ -r "$SOURCE_PLIST" ]] && plist_valid "$SOURCE_PLIST"; then
    checks+=("$(jq -nc --arg c "source_plist_parses" --arg s "ok" --arg d "plutil -lint passed" '{check:$c,status:$s,detail:$d}')")
  elif [[ -r "$SOURCE_PLIST" ]]; then
    checks+=("$(jq -nc --arg c "source_plist_parses" --arg s "fail" --arg d "plutil -lint failed" '{check:$c,status:$s,detail:$d}')")
    status="fail"
  fi
  if [[ -d "$LAUNCH_AGENTS_DIR" ]]; then
    checks+=("$(jq -nc --arg c "launch_agents_dir" --arg s "ok" --arg d "$LAUNCH_AGENTS_DIR" '{check:$c,status:$s,detail:$d}')")
  else
    checks+=("$(jq -nc --arg c "launch_agents_dir" --arg s "warn" --arg d "$LAUNCH_AGENTS_DIR missing (will be created on apply)" '{check:$c,status:$s,detail:$d}')")
  fi
  if [[ -x "$REPO_ROOT/.flywheel/scripts/blocker-discipline-tick-chain.sh" ]]; then
    checks+=("$(jq -nc --arg c "chain_script_executable" --arg s "ok" --arg d "yy9qi chain present" '{check:$c,status:$s,detail:$d}')")
  else
    checks+=("$(jq -nc --arg c "chain_script_executable" --arg s "fail" --arg d "$REPO_ROOT/.flywheel/scripts/blocker-discipline-tick-chain.sh missing" '{check:$c,status:$s,detail:$d}')")
    status="fail"
  fi
  local checks_json
  checks_json="$(printf '%s\n' "${checks[@]}" | jq -s '.')"
  jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$(iso_now)" --arg mode "doctor" --arg status "$status" --argjson checks "$checks_json" \
    '{schema_version:$sv, ts:$ts, mode:$mode, status:$status, checks:$checks}'
}

# ----- subcommand: health -----

cmd_health() {
  local status detail
  if loaded; then
    status="loaded"
    detail="$DOMAIN/$LABEL is registered"
  elif [[ -L "$TARGET_PLIST" || -f "$TARGET_PLIST" ]]; then
    status="installed_not_loaded"
    detail="$TARGET_PLIST exists but not bootstrapped under $DOMAIN"
  else
    status="not_installed"
    detail="$TARGET_PLIST missing"
  fi
  jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$(iso_now)" --arg mode "health" --arg status "$status" --arg detail "$detail" --arg label "$LABEL" --arg domain "$DOMAIN" --arg target "$TARGET_PLIST" \
    '{schema_version:$sv, ts:$ts, mode:$mode, status:$status, detail:$detail, label:$label, domain:$domain, target:$target}'
}

# ----- subcommand: validate -----

cmd_validate() {
  local source_ok=false target_ok=null status="ok"
  if plist_valid "$SOURCE_PLIST"; then source_ok=true; else status="fail"; fi
  if [[ -e "$TARGET_PLIST" ]]; then
    if plist_valid "$TARGET_PLIST"; then target_ok=true; else target_ok=false; status="fail"; fi
  fi
  jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$(iso_now)" --arg mode "validate" --arg status "$status" --argjson source_ok "$source_ok" --argjson target_ok "$target_ok" \
    '{schema_version:$sv, ts:$ts, mode:$mode, status:$status, source_plist_valid:$source_ok, target_plist_valid:$target_ok}'
}

# ----- subcommand: apply -----

cmd_apply() {
  if [[ "$APPLY" -ne 1 ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$(iso_now)" --arg mode "apply" --arg status "dry_run" \
      --arg target "$TARGET_PLIST" --arg source "$SOURCE_PLIST" --arg label "$LABEL" --arg domain "$DOMAIN" \
      '{schema_version:$sv, ts:$ts, mode:$mode, status:$status, would_symlink:{source:$source, target:$target}, would_bootstrap:{label:$label, domain:$domain}, hint:"re-run with --apply --idempotency-key <key>"}'
    return 0
  fi
  if [[ -z "$IDEMPOTENCY_KEY" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$(iso_now)" --arg mode "apply" --arg status "refused" --arg reason "missing_idempotency_key" \
      '{schema_version:$sv, ts:$ts, mode:$mode, status:$status, reason:$reason, hint:"pass --idempotency-key <stable-key>"}'
    audit_append "apply" "refused" "$(jq -nc --arg r "missing_idempotency_key" '{reason:$r}')"
    return 3
  fi
  if ! [[ -r "$SOURCE_PLIST" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$(iso_now)" --arg mode "apply" --arg status "fail" --arg reason "source_plist_missing" --arg path "$SOURCE_PLIST" \
      '{schema_version:$sv, ts:$ts, mode:$mode, status:$status, reason:$reason, source_plist:$path}'
    audit_append "apply" "fail" "$(jq -nc --arg p "$SOURCE_PLIST" '{reason:"source_plist_missing", source:$p}')"
    return 2
  fi
  mkdir -p "$LAUNCH_AGENTS_DIR"
  local already_loaded=false symlink_action="noop"
  if loaded; then already_loaded=true; fi
  if [[ -L "$TARGET_PLIST" ]]; then
    local cur
    cur="$(readlink "$TARGET_PLIST" || true)"
    if [[ "$cur" == "$SOURCE_PLIST" ]]; then
      symlink_action="noop_already_correct"
    else
      ln -sf "$SOURCE_PLIST" "$TARGET_PLIST"
      symlink_action="relinked"
    fi
  elif [[ -e "$TARGET_PLIST" ]]; then
    rm -f "$TARGET_PLIST"
    ln -s "$SOURCE_PLIST" "$TARGET_PLIST"
    symlink_action="replaced_regular_file"
  else
    ln -s "$SOURCE_PLIST" "$TARGET_PLIST"
    symlink_action="created"
  fi
  local register_status
  register_status="$(ensure_watcher_registered)"
  local bootstrap_status="noop_already_loaded"
  if ! "$already_loaded"; then
    if "$LAUNCHCTL" bootstrap "$DOMAIN" "$TARGET_PLIST" >/dev/null 2>&1; then
      bootstrap_status="bootstrapped"
    else
      bootstrap_status="bootstrap_failed"
    fi
  fi
  local final_status="ok"
  if [[ "$bootstrap_status" == "bootstrap_failed" || "$register_status" == "register_failed" ]]; then final_status="fail"; fi
  local extra
  extra="$(jq -nc --arg key "$IDEMPOTENCY_KEY" --arg sym "$symlink_action" --arg reg "$register_status" --arg boot "$bootstrap_status" '{idempotency_key:$key, symlink:$sym, register:$reg, bootstrap:$boot}')"
  audit_append "apply" "$final_status" "$extra"
  jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$(iso_now)" --arg mode "apply" --arg status "$final_status" \
    --arg key "$IDEMPOTENCY_KEY" --arg sym "$symlink_action" --arg reg "$register_status" --arg boot "$bootstrap_status" \
    --arg label "$LABEL" --arg domain "$DOMAIN" --arg target "$TARGET_PLIST" \
    '{schema_version:$sv, ts:$ts, mode:$mode, status:$status, idempotency_key:$key, symlink:$sym, register:$reg, bootstrap:$boot, label:$label, domain:$domain, target:$target}'
  [[ "$final_status" == "ok" ]] || return 4
  return 0
}

# ----- subcommand: unload -----

cmd_unload() {
  if [[ "$APPLY" -ne 1 ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$(iso_now)" --arg mode "unload" --arg status "dry_run" \
      --arg label "$LABEL" --arg domain "$DOMAIN" --arg target "$TARGET_PLIST" \
      '{schema_version:$sv, ts:$ts, mode:$mode, status:$status, would_bootout:{label:$label, domain:$domain}, would_unlink:$target, hint:"re-run with --apply"}'
    return 0
  fi
  local boot_status="noop_not_loaded"
  if loaded; then
    if "$LAUNCHCTL" bootout "$DOMAIN/$LABEL" >/dev/null 2>&1; then boot_status="booted_out"; else boot_status="bootout_failed"; fi
  fi
  local unlink_status="noop_not_present"
  if [[ -L "$TARGET_PLIST" || -f "$TARGET_PLIST" ]]; then
    rm -f "$TARGET_PLIST" && unlink_status="unlinked"
  fi
  local final_status="ok"
  [[ "$boot_status" == "bootout_failed" ]] && final_status="fail"
  local extra
  extra="$(jq -nc --arg b "$boot_status" --arg u "$unlink_status" '{bootout:$b, unlink:$u}')"
  audit_append "unload" "$final_status" "$extra"
  jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$(iso_now)" --arg mode "unload" --arg status "$final_status" \
    --arg b "$boot_status" --arg u "$unlink_status" --arg label "$LABEL" --arg domain "$DOMAIN" \
    '{schema_version:$sv, ts:$ts, mode:$mode, status:$status, bootout:$b, unlink:$u, label:$label, domain:$domain}'
}

# ----- subcommand: audit -----

cmd_audit() {
  local tail_n=20
  if [[ -n "${AUDIT_TAIL:-}" ]]; then tail_n="$AUDIT_TAIL"; fi
  if [[ ! -r "$AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$(iso_now)" --arg mode "audit" --arg status "empty" --arg path "$AUDIT_LOG" \
      '{schema_version:$sv, ts:$ts, mode:$mode, status:$status, audit_log:$path, rows:[]}'
    return 0
  fi
  local rows
  rows="$(tail -n "$tail_n" "$AUDIT_LOG" | jq -s '.')"
  jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$(iso_now)" --arg mode "audit" --arg path "$AUDIT_LOG" --argjson rows "$rows" \
    '{schema_version:$sv, ts:$ts, mode:$mode, status:"ok", audit_log:$path, rows:$rows}'
}

# ----- introspection -----

emit_info() {
  if command -v cli_emit_info >/dev/null; then
    cli_emit_info "blocker-discipline-tick-chain-launchd-install.sh" "$VERSION" "$SCHEMA_VERSION" "doctor,health,validate,apply,unload,audit" "BLOCKER_TICK_CHAIN_LABEL,BLOCKER_TICK_CHAIN_SOURCE_PLIST,BLOCKER_TICK_CHAIN_LAUNCH_AGENTS_DIR,BLOCKER_TICK_CHAIN_DOMAIN,BLOCKER_TICK_CHAIN_AUDIT_LOG" '{}'
    return 0
  fi
  jq -nc --arg sv "$SCHEMA_VERSION" --arg v "$VERSION" --arg name "blocker-discipline-tick-chain-launchd-install.sh" \
    '{schema_version:$sv, command:"info", name:$name, version:$v, capabilities:["doctor","health","validate","apply","unload","audit"]}'
}

emit_schema() {
  jq -nc --arg sv "$SCHEMA_VERSION" \
    '{schema_version:$sv, command:"schema",
      input_schema:{type:"object", properties:{mode:{enum:["doctor","health","validate","apply","unload","audit"]}}, required:["mode"]},
      output_schema:{type:"object", required:["schema_version","mode","status"]}}'
}

emit_examples() {
  if command -v cli_emit_examples >/dev/null; then
    local jsonl
    jsonl="$(jq -nc '{name:"doctor",invocation:"blocker-discipline-tick-chain-launchd-install.sh doctor --json",purpose:"probe install substrate"}'
)"$'\n'"$(jq -nc '{name:"apply",invocation:"blocker-discipline-tick-chain-launchd-install.sh apply --apply --idempotency-key tlclp-2026-05-11",purpose:"symlink plist and bootstrap LaunchAgent"}'
)"$'\n'"$(jq -nc '{name:"unload",invocation:"blocker-discipline-tick-chain-launchd-install.sh unload --apply",purpose:"bootout LaunchAgent and unlink"}'
)"
    cli_emit_examples "$SCHEMA_VERSION" "$jsonl"
    return 0
  fi
  jq -nc --arg sv "$SCHEMA_VERSION" '{schema_version:$sv, command:"examples", examples:[
    {name:"doctor",invocation:"blocker-discipline-tick-chain-launchd-install.sh doctor --json"},
    {name:"apply",invocation:"blocker-discipline-tick-chain-launchd-install.sh apply --apply --idempotency-key tlclp-2026-05-11"},
    {name:"unload",invocation:"blocker-discipline-tick-chain-launchd-install.sh unload --apply"}
  ]}'
}

# ----- arg parse -----

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --info) emit_info; exit 0 ;;
    --schema) emit_schema; exit 0 ;;
    --examples) emit_examples; exit 0 ;;
    --json) JSON_OUT=1; shift ;;
    --apply) APPLY=1; shift ;;
    --dry-run) APPLY=0; shift ;;
    --idempotency-key) IDEMPOTENCY_KEY="$2"; shift 2 ;;
    --tail) AUDIT_TAIL="$2"; shift 2 ;;
    doctor|health|validate|apply|unload|audit) MODE="$1"; shift ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "$MODE" ]]; then usage >&2; exit 2; fi

case "$MODE" in
  doctor) cmd_doctor ;;
  health) cmd_health ;;
  validate) cmd_validate ;;
  apply) cmd_apply ;;
  unload) cmd_unload ;;
  audit) cmd_audit ;;
esac
