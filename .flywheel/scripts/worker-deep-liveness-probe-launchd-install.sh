#!/usr/bin/env bash
# worker-deep-liveness-probe-launchd-install.sh
# flywheel-cli-surface: true
#
# Installer for the launchd wire-in shipped by flywheel-8p6fz. Symlinks the
# canonical plist at .flywheel/launchd/ into ~/Library/LaunchAgents/ and
# bootstraps under gui/$UID via flywheel-watchers register. Idempotent.
#
# Source bead: flywheel-8p6fz (P3)
# Probe shipped by: flywheel-se3h.7
# Triage that confirmed wired-but-cold: flywheel-2xdi.56
# Sister installer pattern: blocker-discipline-tick-chain-launchd-install.sh (flywheel-tlclp)

set -euo pipefail

SCHEMA_VERSION="worker-deep-liveness-probe-launchd-install/v1"
VERSION="0.1.0"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"

LABEL="${WORKER_DEEP_LIVENESS_LABEL:-ai.zeststream.worker-deep-liveness-probe}"
SOURCE_PLIST="${WORKER_DEEP_LIVENESS_SOURCE_PLIST:-$REPO_ROOT/.flywheel/launchd/$LABEL.plist}"
LAUNCH_AGENTS_DIR="${WORKER_DEEP_LIVENESS_LAUNCH_AGENTS_DIR:-$HOME/Library/LaunchAgents}"
TARGET_PLIST="$LAUNCH_AGENTS_DIR/$LABEL.plist"
DOMAIN="${WORKER_DEEP_LIVENESS_DOMAIN:-gui/$UID}"
LAUNCHCTL="${WORKER_DEEP_LIVENESS_LAUNCHCTL:-launchctl}"
WATCHERS_BIN="${WORKER_DEEP_LIVENESS_WATCHERS_BIN:-$HOME/.local/bin/flywheel-watchers}"
BEAD_ID="${WORKER_DEEP_LIVENESS_BEAD_ID:-flywheel-8p6fz}"
AUDIT_LOG="${WORKER_DEEP_LIVENESS_AUDIT_LOG:-$HOME/.local/state/flywheel/worker-deep-liveness-probe-install-runs.jsonl}"

APPLY=0
IDEMPOTENCY_KEY=""
MODE=""

usage() {
  cat <<'USG'
usage: worker-deep-liveness-probe-launchd-install.sh <subcommand> [OPTIONS]

Subcommands:
  doctor [--json]           probe substrate (source plist present, plutil-valid)
  health [--json]           loaded-state probe (launchctl print)
  apply --idempotency-key K bootstrap LaunchAgent (symlink + launchctl bootstrap)
  unload [--json]           launchctl bootout (idempotent)
  audit [--tail N] [--json] tail install/uninstall audit log

Mutation discipline: apply requires --idempotency-key. apply default is dry-run
unless --apply is supplied. Source bead: flywheel-8p6fz.
USG
}

iso_now() { date -u +'%Y-%m-%dT%H:%M:%SZ'; }

audit_append() {
  local action="$1" status="$2" extra="${3:-{}}"
  mkdir -p "$(dirname "$AUDIT_LOG")"
  jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$(iso_now)" --arg action "$action" --arg status "$status" --argjson extra "$extra" \
    '{schema_version:$sv, ts:$ts, action:$action, status:$status, extra:$extra}' >>"$AUDIT_LOG"
}

plist_valid() { command -v plutil >/dev/null || return 0; plutil -lint -s "$1" >/dev/null 2>&1; }
loaded() { "$LAUNCHCTL" print "$DOMAIN/$LABEL" >/dev/null 2>&1; }

ensure_watcher_registered() {
  [[ -x "$WATCHERS_BIN" ]] || { printf 'noop_no_watchers_bin'; return 0; }
  if "$WATCHERS_BIN" registry --json 2>/dev/null | jq -e --arg label "$LABEL" '.active[]? | select(.label == $label and (.active // true))' >/dev/null 2>&1; then
    printf 'noop_already_registered'; return 0
  fi
  if "$WATCHERS_BIN" register --label "$LABEL" --owner flywheel-orch \
        --reason "worker deep-liveness probe every 5 min per flywheel-8p6fz" \
        --bead "$BEAD_ID" --apply --idempotency-key "8p6fz-launchd-${LABEL}" \
        --json >/dev/null 2>&1; then
    printf 'registered'; return 0
  fi
  printf 'register_failed'; return 1
}

cmd_doctor() {
  local checks=()
  local status="ok"
  if [[ -r "$SOURCE_PLIST" ]]; then
    checks+=("$(jq -nc --arg c source_plist_present --arg s ok --arg d "$SOURCE_PLIST" '{check:$c,status:$s,detail:$d}')")
  else
    checks+=("$(jq -nc --arg c source_plist_present --arg s fail --arg d "$SOURCE_PLIST not readable" '{check:$c,status:$s,detail:$d}')")
    status="fail"
  fi
  if [[ -r "$SOURCE_PLIST" ]] && plist_valid "$SOURCE_PLIST"; then
    checks+=("$(jq -nc --arg c source_plist_parses --arg s ok --arg d "plutil -lint passed" '{check:$c,status:$s,detail:$d}')")
  elif [[ -r "$SOURCE_PLIST" ]]; then
    checks+=("$(jq -nc --arg c source_plist_parses --arg s fail --arg d "plutil -lint failed" '{check:$c,status:$s,detail:$d}')")
    status="fail"
  fi
  if [[ -d "$LAUNCH_AGENTS_DIR" ]]; then
    checks+=("$(jq -nc --arg c launch_agents_dir --arg s ok --arg d "$LAUNCH_AGENTS_DIR" '{check:$c,status:$s,detail:$d}')")
  else
    checks+=("$(jq -nc --arg c launch_agents_dir --arg s warn --arg d "$LAUNCH_AGENTS_DIR missing (will be created on apply)" '{check:$c,status:$s,detail:$d}')")
  fi
  local probe_path="$HOME/.claude/skills/.flywheel/scripts/worker-deep-liveness-probe.sh"
  if [[ -x "$probe_path" ]]; then
    checks+=("$(jq -nc --arg c probe_script_executable --arg s ok --arg d "se3h.7 probe present" '{check:$c,status:$s,detail:$d}')")
  else
    checks+=("$(jq -nc --arg c probe_script_executable --arg s fail --arg d "$probe_path missing" '{check:$c,status:$s,detail:$d}')")
    status="fail"
  fi
  local checks_json; checks_json="$(printf '%s\n' "${checks[@]}" | jq -s '.')"
  jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$(iso_now)" --arg mode doctor --arg status "$status" --argjson checks "$checks_json" \
    '{schema_version:$sv,ts:$ts,mode:$mode,status:$status,checks:$checks}'
}

cmd_health() {
  local status detail
  if loaded; then status="loaded"; detail="$DOMAIN/$LABEL registered"
  elif [[ -L "$TARGET_PLIST" || -f "$TARGET_PLIST" ]]; then status="installed_not_loaded"; detail="$TARGET_PLIST exists but not bootstrapped"
  else status="not_installed"; detail="$TARGET_PLIST missing"
  fi
  jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$(iso_now)" --arg mode health --arg status "$status" --arg detail "$detail" \
    --arg label "$LABEL" --arg domain "$DOMAIN" --arg target "$TARGET_PLIST" \
    '{schema_version:$sv,ts:$ts,mode:$mode,status:$status,detail:$detail,label:$label,domain:$domain,target:$target}'
}

cmd_apply() {
  if [[ "$APPLY" -ne 1 ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$(iso_now)" --arg mode apply --arg status dry_run \
      --arg src "$SOURCE_PLIST" --arg tgt "$TARGET_PLIST" --arg label "$LABEL" --arg domain "$DOMAIN" \
      '{schema_version:$sv,ts:$ts,mode:$mode,status:$status,would_symlink:{source:$src,target:$tgt},would_bootstrap:{label:$label,domain:$domain},hint:"re-run with --apply --idempotency-key <key>"}'
    return 0
  fi
  if [[ -z "$IDEMPOTENCY_KEY" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$(iso_now)" --arg mode apply --arg status refused --arg reason missing_idempotency_key \
      '{schema_version:$sv,ts:$ts,mode:$mode,status:$status,reason:$reason,hint:"pass --idempotency-key <stable-key>"}'
    audit_append apply refused "$(jq -nc --arg r missing_idempotency_key '{reason:$r}')"
    return 3
  fi
  if ! [[ -r "$SOURCE_PLIST" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$(iso_now)" --arg mode apply --arg status fail --arg reason source_plist_missing --arg path "$SOURCE_PLIST" \
      '{schema_version:$sv,ts:$ts,mode:$mode,status:$status,reason:$reason,source_plist:$path}'
    audit_append apply fail "$(jq -nc --arg p "$SOURCE_PLIST" '{reason:"source_plist_missing",source:$p}')"
    return 2
  fi
  mkdir -p "$LAUNCH_AGENTS_DIR"
  local already_loaded=false sym_action=noop
  if loaded; then already_loaded=true; fi
  if [[ -L "$TARGET_PLIST" ]]; then
    local cur; cur="$(readlink "$TARGET_PLIST" || true)"
    if [[ "$cur" == "$SOURCE_PLIST" ]]; then sym_action=noop_already_correct
    else ln -sf "$SOURCE_PLIST" "$TARGET_PLIST"; sym_action=relinked
    fi
  elif [[ -e "$TARGET_PLIST" ]]; then
    rm -f "$TARGET_PLIST"; ln -s "$SOURCE_PLIST" "$TARGET_PLIST"; sym_action=replaced_regular_file
  else
    ln -s "$SOURCE_PLIST" "$TARGET_PLIST"; sym_action=created
  fi
  local register_status; register_status="$(ensure_watcher_registered)"
  local boot_status=noop_already_loaded
  if ! "$already_loaded"; then
    if "$LAUNCHCTL" bootstrap "$DOMAIN" "$TARGET_PLIST" >/dev/null 2>&1; then boot_status=bootstrapped
    else boot_status=bootstrap_failed
    fi
  fi
  local final=ok
  [[ "$boot_status" == bootstrap_failed || "$register_status" == register_failed ]] && final=fail
  local extra; extra="$(jq -nc --arg key "$IDEMPOTENCY_KEY" --arg sym "$sym_action" --arg reg "$register_status" --arg boot "$boot_status" '{idempotency_key:$key,symlink:$sym,register:$reg,bootstrap:$boot}')"
  audit_append apply "$final" "$extra"
  jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$(iso_now)" --arg mode apply --arg status "$final" \
    --arg key "$IDEMPOTENCY_KEY" --arg sym "$sym_action" --arg reg "$register_status" --arg boot "$boot_status" \
    --arg label "$LABEL" --arg domain "$DOMAIN" --arg target "$TARGET_PLIST" \
    '{schema_version:$sv,ts:$ts,mode:$mode,status:$status,idempotency_key:$key,symlink:$sym,register:$reg,bootstrap:$boot,label:$label,domain:$domain,target:$target}'
  [[ "$final" == ok ]] || return 4
  return 0
}

cmd_unload() {
  if [[ "$APPLY" -ne 1 ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$(iso_now)" --arg mode unload --arg status dry_run \
      --arg label "$LABEL" --arg domain "$DOMAIN" --arg target "$TARGET_PLIST" \
      '{schema_version:$sv,ts:$ts,mode:$mode,status:$status,would_bootout:{label:$label,domain:$domain},would_unlink:$target,hint:"re-run with --apply"}'
    return 0
  fi
  local boot=noop_not_loaded
  if loaded; then
    if "$LAUNCHCTL" bootout "$DOMAIN/$LABEL" >/dev/null 2>&1; then boot=booted_out; else boot=bootout_failed; fi
  fi
  local unlink=noop_not_present
  if [[ -L "$TARGET_PLIST" || -f "$TARGET_PLIST" ]]; then rm -f "$TARGET_PLIST" && unlink=unlinked; fi
  local final=ok; [[ "$boot" == bootout_failed ]] && final=fail
  audit_append unload "$final" "$(jq -nc --arg b "$boot" --arg u "$unlink" '{bootout:$b,unlink:$u}')"
  jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$(iso_now)" --arg mode unload --arg status "$final" \
    --arg b "$boot" --arg u "$unlink" --arg label "$LABEL" --arg domain "$DOMAIN" \
    '{schema_version:$sv,ts:$ts,mode:$mode,status:$status,bootout:$b,unlink:$u,label:$label,domain:$domain}'
}

cmd_audit() {
  local tail_n=20
  if [[ -n "${AUDIT_TAIL:-}" ]]; then tail_n="$AUDIT_TAIL"; fi
  if [[ ! -r "$AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$(iso_now)" --arg mode audit --arg status empty --arg path "$AUDIT_LOG" \
      '{schema_version:$sv,ts:$ts,mode:$mode,status:$status,audit_log:$path,rows:[]}'
    return 0
  fi
  local rows; rows="$(tail -n "$tail_n" "$AUDIT_LOG" | jq -s '.')"
  jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$(iso_now)" --arg mode audit --arg path "$AUDIT_LOG" --argjson rows "$rows" \
    '{schema_version:$sv,ts:$ts,mode:$mode,status:"ok",audit_log:$path,rows:$rows}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --json) shift ;;
    --apply) APPLY=1; shift ;;
    --dry-run) APPLY=0; shift ;;
    --idempotency-key) IDEMPOTENCY_KEY="$2"; shift 2 ;;
    --tail) AUDIT_TAIL="$2"; shift 2 ;;
    doctor|health|apply|unload|audit) MODE="$1"; shift ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "$MODE" ]]; then usage >&2; exit 2; fi

case "$MODE" in
  doctor) cmd_doctor ;;
  health) cmd_health ;;
  apply) cmd_apply ;;
  unload) cmd_unload ;;
  audit) cmd_audit ;;
esac
