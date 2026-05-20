#!/usr/bin/env bash
set -euo pipefail

PRIMARY_LABEL="ai.zeststream.codex-stuck-detector-watchdog"
SOURCE_ROOT="${STUCK_DETECTOR_WATCHDOG_SOURCE_ROOT:-/Users/josh/Developer/flywheel}"
SOURCE_PLIST="${STUCK_DETECTOR_WATCHDOG_SOURCE_PLIST:-$SOURCE_ROOT/.flywheel/scripts/codex-template-stuck-detector-watchdog.plist}"
CROSS_SOURCE_DIR="${STUCK_DETECTOR_WATCHDOG_CROSS_SOURCE_DIR:-$SOURCE_ROOT/.flywheel/launchd}"
LAUNCH_AGENTS_DIR="${STUCK_DETECTOR_WATCHDOG_LAUNCH_AGENTS_DIR:-$HOME/Library/LaunchAgents}"
INSTALL_LOG="${STUCK_DETECTOR_WATCHDOG_INSTALL_LOG:-$HOME/.local/state/flywheel/watcher-launchd-install.jsonl}"
LAUNCHCTL="${STUCK_DETECTOR_WATCHDOG_LAUNCHCTL:-launchctl}"
PLUTIL="${STUCK_DETECTOR_WATCHDOG_PLUTIL:-plutil}"
WATCHERS_BIN="${STUCK_DETECTOR_WATCHERS_BIN:-$HOME/.local/bin/flywheel-watchers}"
BEAD_ID="${STUCK_DETECTOR_WATCHDOG_BEAD:-flywheel-watchdog-cross-session-scope-gap-6036}"
BOOTSTRAP_DOMAIN="${STUCK_DETECTOR_WATCHDOG_BOOTSTRAP_DOMAIN:-gui/$UID}"
LEGACY_DOMAIN="${STUCK_DETECTOR_WATCHDOG_LEGACY_DOMAIN:-user/$UID}"
SESSION_KEYS="${STUCK_DETECTOR_WATCHDOG_SESSION_KEYS:-mobile-eats skillos alps vrtx}"
ENABLE=1
DRY_RUN=0
JSON_OUT=0

usage() {
  cat <<'EOF'
usage: install-stuck-detector-watchdog.sh [--enable] [--dry-run] [--json]

Copies and enables the flywheel watchdog plus per-session stuck-detector
LaunchAgents for mobile-eats, skillos, alps, and vrtx. LaunchAgents are loaded
under gui/<uid>.
EOF
}

session_name_for_key() {
  case "$1" in
    alps) printf 'alpsinsurance\n' ;;
    *) printf '%s\n' "$1" ;;
  esac
}

label_for_key() {
  printf 'ai.zeststream.%s-codex-stuck-detector\n' "$1"
}

source_for_key() {
  printf '%s/ai.zeststream.%s-codex-stuck-detector.plist\n' "$CROSS_SOURCE_DIR" "$1"
}

target_for_label() {
  printf '%s/%s.plist\n' "$LAUNCH_AGENTS_DIR" "$1"
}

loaded_label() {
  local label="$1"
  "$LAUNCHCTL" print "$BOOTSTRAP_DOMAIN/$label" >/dev/null 2>&1
}

legacy_loaded_label() {
  local label="$1"
  "$LAUNCHCTL" print "$LEGACY_DOMAIN/$label" >/dev/null 2>&1
}

write_primary_plist() {
  local tmp="$1"
  python3 -c 'import plistlib, sys
src, target, label = sys.argv[1:4]
with open(src, "rb") as handle:
    data = plistlib.load(handle)
data["Label"] = label
data["RunAtLoad"] = True
data["StartInterval"] = 60
with open(target, "wb") as handle:
    plistlib.dump(data, handle, sort_keys=False)' "$SOURCE_PLIST" "$tmp" "$PRIMARY_LABEL"
}

plist_interval() {
  local path="$1"
  python3 -c 'import plistlib, sys
with open(sys.argv[1], "rb") as handle:
    data = plistlib.load(handle)
print(int(data.get("StartInterval", 0)))' "$path"
}

ensure_registered() {
  local label="$1" session_name="$2"
  [[ -x "$WATCHERS_BIN" ]] || return 0
  if "$WATCHERS_BIN" registry --json 2>/dev/null | jq -e --arg label "$label" '.active[]? | select(.label == $label and (.active // true))' >/dev/null; then
    return 0
  fi
  "$WATCHERS_BIN" register \
    --label "$label" \
    --owner flywheel-orch \
    --reason "stuck-detector watchdog scope ${session_name}" \
    --bead "$BEAD_ID" \
    --apply \
    --idempotency-key "watchdog-cross-session-${label}" \
    --json >/dev/null
}

append_install_log() {
  local label="$1" target="$2" session_key="$3" session_name="$4" print_exit="$5" interval="$6"
  mkdir -p "$(dirname "$INSTALL_LOG")"
  jq -nc \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg action "install" \
    --arg plist_path "$target" \
    --arg label "$label" \
    --arg session_key "$session_key" \
    --arg session_name "$session_name" \
    --arg bootstrap_domain "$BOOTSTRAP_DOMAIN" \
    --argjson launchctl_print_exit "$print_exit" \
    --argjson interval_sec "$interval" \
    '{ts:$ts,action:$action,plist_path:$plist_path,label:$label,session_key:$session_key,session_name:$session_name,bootstrap_domain:$bootstrap_domain,launchctl_print_exit:$launchctl_print_exit,interval_sec:$interval_sec,installer_idempotent:true}' >>"$INSTALL_LOG"
}

install_one() {
  local kind="$1" label="$2" source="$3" target="$4" session_key="$5" session_name="$6" rows_file="$7"
  local tmp copied loaded_state print_exit interval

  [[ -f "$source" ]] || { printf 'missing source plist: %s\n' "$source" >&2; exit 1; }
  "$PLUTIL" -lint "$source" >/dev/null

  copied=false
  if [[ "$DRY_RUN" -eq 0 ]]; then
    mkdir -p "$LAUNCH_AGENTS_DIR" "$HOME/.local/logs" "$HOME/.local/state/flywheel" "$(dirname "$INSTALL_LOG")"
    tmp="${target}.$$.$RANDOM.tmp"
    if [[ "$kind" == "primary" ]]; then
      write_primary_plist "$tmp"
    else
      cp "$source" "$tmp"
    fi
    mv "$tmp" "$target"
    copied=true
    ensure_registered "$label" "$session_name"
  fi

  if [[ "$ENABLE" -eq 1 && "$DRY_RUN" -eq 0 ]]; then
    if loaded_label "$label"; then
      "$LAUNCHCTL" bootout "$BOOTSTRAP_DOMAIN/$label" >/dev/null 2>&1 || true
    fi
    if legacy_loaded_label "$label"; then
      "$LAUNCHCTL" bootout "$LEGACY_DOMAIN/$label" >/dev/null 2>&1 || true
    fi
    "$LAUNCHCTL" bootstrap "$BOOTSTRAP_DOMAIN" "$target"
    "$LAUNCHCTL" kickstart -k "$BOOTSTRAP_DOMAIN/$label" >/dev/null 2>&1 || true
  fi

  loaded_state=false
  print_exit=1
  if "$LAUNCHCTL" print "$BOOTSTRAP_DOMAIN/$label" >/dev/null 2>&1; then
    loaded_state=true
    print_exit=0
  fi

  interval=60
  if [[ -f "$target" ]]; then
    interval="$(plist_interval "$target")"
  fi

  if [[ "$DRY_RUN" -eq 0 ]]; then
    append_install_log "$label" "$target" "$session_key" "$session_name" "$print_exit" "$interval"
  fi

  jq -nc \
    --arg kind "$kind" \
    --arg label "$label" \
    --arg source "$source" \
    --arg target "$target" \
    --arg session_key "$session_key" \
    --arg session_name "$session_name" \
    --arg bootstrap_domain "$BOOTSTRAP_DOMAIN" \
    --argjson copied "$copied" \
    --argjson loaded "$loaded_state" \
    --argjson print_exit "$print_exit" \
    --argjson interval "$interval" \
    '{kind:$kind,label:$label,source_plist:$source,target_plist:$target,session_key:$session_key,session_name:$session_name,bootstrap_domain:$bootstrap_domain,copied:$copied,loaded:$loaded,launchctl_print_exit:$print_exit,interval_sec:$interval,installer_idempotent:true}' >>"$rows_file"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --enable) ENABLE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

rows_file="$(mktemp "${TMPDIR:-/tmp}/stuck-detector-watchdog-install.XXXXXX")"
trap 'rm -f "$rows_file"' EXIT

install_one primary "$PRIMARY_LABEL" "$SOURCE_PLIST" "$(target_for_label "$PRIMARY_LABEL")" flywheel flywheel "$rows_file"

for key in $SESSION_KEYS; do
  session_name="$(session_name_for_key "$key")"
  install_one session "$(label_for_key "$key")" "$(source_for_key "$key")" "$(target_for_label "$(label_for_key "$key")")" "$key" "$session_name" "$rows_file"
done

if [[ "$JSON_OUT" -eq 1 ]]; then
  jq -s \
    --arg schema_version "codex-template-stuck-detector-watchdog.install.v2" \
    --arg label "$PRIMARY_LABEL" \
    --arg source "$SOURCE_PLIST" \
    --arg target "$(target_for_label "$PRIMARY_LABEL")" \
    --arg bootstrap_domain "$BOOTSTRAP_DOMAIN" \
    --arg print_domain "$BOOTSTRAP_DOMAIN" \
    --arg install_log "$INSTALL_LOG" \
    --argjson enabled "$ENABLE" \
    --argjson dry_run "$DRY_RUN" \
    '{
      schema_version:$schema_version,
      label:$label,
      source_plist:$source,
      target_plist:$target,
      bootstrap_domain:$bootstrap_domain,
      print_domain:$print_domain,
      install_log:$install_log,
      enabled:($enabled == 1),
      dry_run:($dry_run == 1),
      copied:(any(.[]; .kind == "primary" and .copied == true)),
      loaded:(any(.[]; .kind == "primary" and .loaded == true)),
      launchctl_print_exit:((.[] | select(.kind == "primary") | .launchctl_print_exit) // 1),
      interval_sec:((.[] | select(.kind == "primary") | .interval_sec) // 0),
      installer_idempotent:true,
      plists_installed:length,
      session_plists:[.[] | select(.kind == "session")],
      all_loaded:all(.[]; .loaded == true),
      rows:.
    }' "$rows_file"
else
  jq -r '. | "label=\(.label) session=\(.session_name) copied=\(.copied) loaded=\(.loaded) launchctl_print_exit=\(.launchctl_print_exit) interval_sec=\(.interval_sec)"' "$rows_file"
fi

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
