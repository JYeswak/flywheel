#!/usr/bin/env bash
set -euo pipefail

VERSION="jeff-intel-scheduled-runner.v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
STATE_DIR="${JEFF_INTEL_STATE_DIR:-$HOME/.local/state/jeff-intel}"
FLYWHEEL_STATE_DIR="${FLYWHEEL_STATE_DIR:-$HOME/.local/state/flywheel}"
LEDGER="${JEFF_INTEL_SCHEDULE_LEDGER:-$STATE_DIR/scheduled-runs.jsonl}"
X_LEDGER="${JEFF_INTEL_X_LEDGER:-$STATE_DIR/x-poll.jsonl}"
X_SNAPSHOT_DIR="${JEFF_INTEL_X_SNAPSHOT_DIR:-$STATE_DIR/x-poll}"
DAILY_SCRIPT="${JEFF_INTEL_DAILY_SCRIPT:-$ROOT/.flywheel/scripts/daily-jeff-ingest.sh}"
SOURCE_REGEN_SCRIPT="${JEFF_INTEL_SOURCE_REGEN_SCRIPT:-$ROOT/.flywheel/scripts/regenerate-dicklesworthstone-sources.sh}"
PHILOSOPHY_SCRIPT="${JEFF_PHILOSOPHY_SCRIPT:-$ROOT/.flywheel/scripts/jeff-philosophy-mine.sh}"
TENTACLE_DRIFT_SCRIPT="${TENTACLE_DRIFT_SCRIPT:-$ROOT/.flywheel/scripts/tentacle-drift-sweep.sh}"
MODE="doctor"
JSON_OUT=0
DRY_RUN=0
STORAGE_MIN_FREE_PCT="${JEFF_INTEL_STORAGE_MIN_FREE_PCT:-}"
NOW="${JEFF_INTEL_NOW:-}"
X_FIXTURE="${JEFF_INTEL_X_FIXTURE:-}"
LAUNCHCTL_LIST_FIXTURE="${JEFF_INTEL_LAUNCHCTL_LIST_FIXTURE:-}"

DAILY_LABEL="ai.zeststream.flywheel-daily-jeff-ingest"
X_LABEL="ai.zeststream.flywheel-jeff-x-poll"
MONTHLY_LABEL="ai.zeststream.flywheel-jeff-philosophy-monthly"
TENTACLE_DRIFT_LABEL="ai.zeststream.flywheel-tentacle-drift-sweep"
DAILY_PLIST="$HOME/Library/LaunchAgents/${DAILY_LABEL}.plist"
X_PLIST="$HOME/Library/LaunchAgents/${X_LABEL}.plist"
MONTHLY_PLIST="$HOME/Library/LaunchAgents/${MONTHLY_LABEL}.plist"
TENTACLE_DRIFT_PLIST="${TENTACLE_DRIFT_PLIST:-$ROOT/launchd/${TENTACLE_DRIFT_LABEL}.plist}"

usage() {
  cat <<'USAGE'
Usage:
  jeff-intel-scheduled-runner.sh --mode daily [--dry-run] [--json]
  jeff-intel-scheduled-runner.sh --mode x-poll [--dry-run] [--json]
  jeff-intel-scheduled-runner.sh --mode monthly-deep-mine [--dry-run] [--json]
  jeff-intel-scheduled-runner.sh --mode tentacle-drift [--dry-run] [--json]
  jeff-intel-scheduled-runner.sh --mode doctor [--json]
  jeff-intel-scheduled-runner.sh --schema [--json]
  jeff-intel-scheduled-runner.sh --examples

Modes:
  daily              Runs GitHub/git, website/RSS, X, JSM, mirror ingest via daily-jeff-ingest.
  x-poll             Runs hourly Jeff X timeline capture for @doodlestein.
  monthly-deep-mine  Runs Jeff philosophy pattern mining refresh.
  tentacle-drift     Runs read-only Jeff checkout drift sweep.
  doctor             Verifies the launchd labels, plists, source coverage, and receipt paths.

Receipts:
  ~/.local/state/jeff-intel/scheduled-runs.jsonl
  ~/.local/state/jeff-intel/x-poll.jsonl
  ~/.local/state/flywheel/daily-jeff-ingest.jsonl
  ~/.local/state/flywheel/tentacle-drift.jsonl
USAGE
}

now_iso() {
  if [[ -n "$NOW" ]]; then printf '%s\n' "$NOW"; else date -u +%Y-%m-%dT%H:%M:%SZ; fi
}

append_jsonl() {
  local path="$1" row="$2"
  mkdir -p "$(dirname "$path")"
  printf '%s\n' "$row" >>"$path"
}

emit() {
  local row="$1"
  if [[ "$JSON_OUT" -eq 1 ]]; then jq -c . <<<"$row"; else jq -r '"\(.mode) status=\(.status) receipt=\(.receipt_path // "none")"' <<<"$row"; fi
}

schema_json() {
  jq -n \
    --arg version "$VERSION" \
    --arg daily_label "$DAILY_LABEL" \
    --arg x_label "$X_LABEL" \
    --arg monthly_label "$MONTHLY_LABEL" \
    --arg tentacle_label "$TENTACLE_DRIFT_LABEL" \
    --arg daily_plist "$DAILY_PLIST" \
    --arg x_plist "$X_PLIST" \
    --arg monthly_plist "$MONTHLY_PLIST" \
    --arg tentacle_plist "$TENTACLE_DRIFT_PLIST" \
    --arg ledger "$LEDGER" \
    --arg x_ledger "$X_LEDGER" \
    --arg flywheel_ledger "$FLYWHEEL_STATE_DIR/daily-jeff-ingest.jsonl" \
    --arg tentacle_ledger "$FLYWHEEL_STATE_DIR/tentacle-drift.jsonl" \
    --arg tentacle_alert_ledger "$FLYWHEEL_STATE_DIR/tentacle-drift-alerts.jsonl" \
    '{
      schema_version:"jeff-intel-schedule/v1",
      version:$version,
      launchd_labels:{daily:$daily_label,x_hourly:$x_label,monthly_deep_mine:$monthly_label,tentacle_drift:$tentacle_label},
      launchd_plists:{daily:$daily_plist,x_hourly:$x_plist,monthly_deep_mine:$monthly_plist,tentacle_drift:$tentacle_plist},
      source_cadence:{
        github_git:"daily via daily-jeff-ingest plus jeff-corpus diff watcher surface",
        website_rss:"daily via daily-jeff-ingest",
        x:"hourly via x-poll and daily via daily-jeff-ingest",
        jeff_philosophy:"daily via jeff-philosophy-mine.sh --daily-snapshot --skip-fetch; monthly via jeff-philosophy-mine.sh --deep-mine",
        tentacle_drift:"weekly read-only git remote-tracking sweep; no fetch, pull, checkout, or repo mutation"
      },
      receipt_paths:{
        schedule:$ledger,
        x_poll:$x_ledger,
        daily_jeff_ingest:$flywheel_ledger,
        jeff_philosophy_audit:(env.HOME + "/.local/state/jeff-philosophy/audit.jsonl"),
        tentacle_drift:$tentacle_ledger,
        tentacle_drift_alerts:$tentacle_alert_ledger
      },
      modes:["daily","x-poll","monthly-deep-mine","tentacle-drift","doctor"],
      dry_run_supported:true
    }'
}

launchctl_labels() {
  if [[ -n "$LAUNCHCTL_LIST_FIXTURE" ]]; then
    cat "$LAUNCHCTL_LIST_FIXTURE"
  else
    launchctl list
  fi
}

run_daily() {
  local ts tmp regen_out ingest_out philosophy_out regen_rc=0 ingest_rc=0 philosophy_rc=0 status row
  ts="$(now_iso)"
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/jeff-intel-daily.XXXXXX")"
  trap 'rm -rf "$tmp"' RETURN

  if [[ -x "$SOURCE_REGEN_SCRIPT" ]]; then
    "$SOURCE_REGEN_SCRIPT" --dry-run --json >"$tmp/source-regeneration.json" || regen_rc=$?
  else
    jq -n --arg script "$SOURCE_REGEN_SCRIPT" '{status:"skipped", reason:"source_regen_script_missing", script:$script}' >"$tmp/source-regeneration.json"
  fi
  regen_out="$(jq -c . "$tmp/source-regeneration.json")"

  local daily_args=(--json)
  if [[ "$DRY_RUN" -eq 1 ]]; then
    daily_args=(--dry-run --json)
  fi
  if [[ -n "$STORAGE_MIN_FREE_PCT" ]]; then
    DAILY_JEFF_STORAGE_MIN_FREE_PCT="$STORAGE_MIN_FREE_PCT" "$DAILY_SCRIPT" "${daily_args[@]}" >"$tmp/daily-jeff-ingest.json" || ingest_rc=$?
  else
    "$DAILY_SCRIPT" "${daily_args[@]}" >"$tmp/daily-jeff-ingest.json" || ingest_rc=$?
  fi
  ingest_out="$(jq -c . "$tmp/daily-jeff-ingest.json" 2>/dev/null || jq -n --arg path "$tmp/daily-jeff-ingest.json" '{status:"invalid_json", path:$path}')"

  local philosophy_args=(--daily-snapshot --skip-fetch --json)
  if [[ "$DRY_RUN" -eq 1 ]]; then
    philosophy_args+=(--dry-run)
  fi
  if [[ -n "$NOW" ]]; then
    philosophy_args+=(--now "$NOW")
  fi
  if [[ -x "$PHILOSOPHY_SCRIPT" ]]; then
    "$PHILOSOPHY_SCRIPT" "${philosophy_args[@]}" >"$tmp/jeff-philosophy-daily-snapshot.json" || philosophy_rc=$?
  else
    philosophy_rc=127
    jq -n --arg script "$PHILOSOPHY_SCRIPT" '{status:"fail", reason:"philosophy_script_missing", script:$script}' >"$tmp/jeff-philosophy-daily-snapshot.json"
  fi
  philosophy_out="$(jq -c . "$tmp/jeff-philosophy-daily-snapshot.json" 2>/dev/null || jq -n --arg path "$tmp/jeff-philosophy-daily-snapshot.json" '{status:"invalid_json", path:$path}')"

  if [[ "$regen_rc" -eq 0 && "$ingest_rc" -eq 0 && "$philosophy_rc" -eq 0 ]]; then status="pass"; else status="fail"; fi
  row="$(jq -n \
    --arg schema_version "jeff-intel-schedule-receipt/v1" \
    --arg version "$VERSION" \
    --arg ts "$ts" \
    --arg mode "daily" \
    --arg status "$status" \
    --arg label "$DAILY_LABEL" \
    --arg receipt_path "$LEDGER" \
    --arg daily_ledger "$FLYWHEEL_STATE_DIR/daily-jeff-ingest.jsonl" \
    --argjson dry_run "$(if [[ "$DRY_RUN" -eq 1 ]]; then printf true; else printf false; fi)" \
    --argjson regen "$regen_out" \
    --argjson ingest "$ingest_out" \
    --argjson philosophy "$philosophy_out" \
    --argjson regen_rc "$regen_rc" \
    --argjson ingest_rc "$ingest_rc" \
    --argjson philosophy_rc "$philosophy_rc" \
    '{schema_version:$schema_version,version:$version,ts:$ts,mode:$mode,status:$status,launchd_label:$label,dry_run:$dry_run,sources:{github_git:true,website_rss:true,x:true,jsm:true,jeff_philosophy:true},cadence:"daily",receipt_path:$receipt_path,daily_jeff_ledger:$daily_ledger,source_regeneration:$regen,daily_jeff_ingest:$ingest,jeff_philosophy_daily_snapshot:$philosophy,exit_codes:{source_regeneration:$regen_rc,daily_jeff_ingest:$ingest_rc,jeff_philosophy_daily_snapshot:$philosophy_rc}}')"
  [[ "$DRY_RUN" -eq 1 ]] || append_jsonl "$LEDGER" "$row"
  emit "$row"
  [[ "$status" == "pass" ]]
}

run_x_poll() {
  local ts tmp out rc=0 status latest snapshot row count
  ts="$(now_iso)"
  mkdir -p "$X_SNAPSHOT_DIR"
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/jeff-x-poll.XXXXXX")"
  trap 'rm -rf "$tmp"' RETURN
  out="$tmp/x.md"

  if [[ -n "$X_FIXTURE" ]]; then
    cp "$X_FIXTURE" "$out"
  else
    x-cli -md user timeline doodlestein --max 20 >"$out" || rc=$?
  fi
  if [[ "$rc" -eq 0 && -s "$out" ]]; then status="pass"; else status="fail"; fi
  count="$(wc -l <"$out" 2>/dev/null | tr -d ' ' || printf '0')"
  latest="$X_SNAPSHOT_DIR/latest.md"
  snapshot="$X_SNAPSHOT_DIR/x-doodlestein-${ts//[:]/}.md"
  if [[ "$DRY_RUN" -eq 0 && "$status" == "pass" ]]; then
    cp "$out" "$snapshot"
    cp "$out" "$latest"
  fi
  row="$(jq -n \
    --arg schema_version "jeff-x-poll/v1" \
    --arg version "$VERSION" \
    --arg ts "$ts" \
    --arg status "$status" \
    --arg label "$X_LABEL" \
    --arg receipt_path "$X_LEDGER" \
    --arg snapshot "$snapshot" \
    --arg latest "$latest" \
    --argjson dry_run "$(if [[ "$DRY_RUN" -eq 1 ]]; then printf true; else printf false; fi)" \
    --argjson line_count "$count" \
    --argjson exit_code "$rc" \
    '{schema_version:$schema_version,version:$version,ts:$ts,mode:"x-poll",status:$status,launchd_label:$label,dry_run:$dry_run,source:"x:@doodlestein",cadence:"hourly",receipt_path:$receipt_path,snapshot_path:(if $dry_run then null else $snapshot end),latest_path:(if $dry_run then null else $latest end),line_count:$line_count,exit_code:$exit_code}')"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    append_jsonl "$X_LEDGER" "$row"
    append_jsonl "$LEDGER" "$row"
  fi
  emit "$row"
  [[ "$status" == "pass" ]]
}

run_monthly_deep_mine() {
  local ts tmp philosophy_out philosophy_rc=0 status row
  ts="$(now_iso)"
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/jeff-philosophy-monthly.XXXXXX")"
  trap 'rm -rf "$tmp"' RETURN

  local philosophy_args=(--deep-mine --json)
  if [[ "$DRY_RUN" -eq 1 ]]; then
    philosophy_args+=(--dry-run)
  fi
  if [[ -n "$NOW" ]]; then
    philosophy_args+=(--now "$NOW")
  fi
  if [[ -x "$PHILOSOPHY_SCRIPT" ]]; then
    "$PHILOSOPHY_SCRIPT" "${philosophy_args[@]}" >"$tmp/jeff-philosophy-deep-mine.json" || philosophy_rc=$?
  else
    philosophy_rc=127
    jq -n --arg script "$PHILOSOPHY_SCRIPT" '{status:"fail", reason:"philosophy_script_missing", script:$script}' >"$tmp/jeff-philosophy-deep-mine.json"
  fi
  philosophy_out="$(jq -c . "$tmp/jeff-philosophy-deep-mine.json" 2>/dev/null || jq -n --arg path "$tmp/jeff-philosophy-deep-mine.json" '{status:"invalid_json", path:$path}')"

  if [[ "$philosophy_rc" -eq 0 ]]; then status="pass"; else status="fail"; fi
  row="$(jq -n \
    --arg schema_version "jeff-intel-schedule-receipt/v1" \
    --arg version "$VERSION" \
    --arg ts "$ts" \
    --arg mode "monthly-deep-mine" \
    --arg status "$status" \
    --arg label "$MONTHLY_LABEL" \
    --arg receipt_path "$LEDGER" \
    --argjson dry_run "$(if [[ "$DRY_RUN" -eq 1 ]]; then printf true; else printf false; fi)" \
    --argjson philosophy "$philosophy_out" \
    --argjson philosophy_rc "$philosophy_rc" \
    '{schema_version:$schema_version,version:$version,ts:$ts,mode:$mode,status:$status,launchd_label:$label,dry_run:$dry_run,sources:{jeff_philosophy:true},cadence:"monthly",receipt_path:$receipt_path,jeff_philosophy_deep_mine:$philosophy,exit_codes:{jeff_philosophy_deep_mine:$philosophy_rc}}')"
  [[ "$DRY_RUN" -eq 1 ]] || append_jsonl "$LEDGER" "$row"
  emit "$row"
  [[ "$status" == "pass" ]]
}

run_tentacle_drift() {
  local ts tmp drift_out drift_rc=0 status row
  ts="$(now_iso)"
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/tentacle-drift-schedule.XXXXXX")"
  trap 'rm -rf "$tmp"' RETURN

  local drift_args=(--json)
  if [[ "$DRY_RUN" -eq 1 ]]; then
    drift_args+=(--dry-run)
  else
    drift_args+=(--apply)
  fi
  if [[ -n "$NOW" ]]; then
    drift_args+=(--now "$NOW")
  fi
  if [[ -x "$TENTACLE_DRIFT_SCRIPT" ]]; then
    "$TENTACLE_DRIFT_SCRIPT" "${drift_args[@]}" >"$tmp/tentacle-drift.json" || drift_rc=$?
  else
    drift_rc=127
    jq -n --arg script "$TENTACLE_DRIFT_SCRIPT" '{status:"fail", reason:"tentacle_drift_script_missing", script:$script}' >"$tmp/tentacle-drift.json"
  fi
  drift_out="$(jq -c . "$tmp/tentacle-drift.json" 2>/dev/null || jq -n --arg path "$tmp/tentacle-drift.json" '{status:"invalid_json", path:$path}')"

  if [[ "$drift_rc" -eq 0 ]]; then status="pass"; else status="fail"; fi
  row="$(jq -n \
    --arg schema_version "jeff-intel-schedule-receipt/v1" \
    --arg version "$VERSION" \
    --arg ts "$ts" \
    --arg mode "tentacle-drift" \
    --arg status "$status" \
    --arg label "$TENTACLE_DRIFT_LABEL" \
    --arg receipt_path "$LEDGER" \
    --argjson dry_run "$(if [[ "$DRY_RUN" -eq 1 ]]; then printf true; else printf false; fi)" \
    --argjson drift "$drift_out" \
    --argjson drift_rc "$drift_rc" \
    '{schema_version:$schema_version,version:$version,ts:$ts,mode:$mode,status:$status,launchd_label:$label,dry_run:$dry_run,sources:{tentacle_drift:true},cadence:"weekly",receipt_path:$receipt_path,tentacle_drift:$drift,exit_codes:{tentacle_drift:$drift_rc}}')"
  [[ "$DRY_RUN" -eq 1 ]] || append_jsonl "$LEDGER" "$row"
  emit "$row"
  [[ "$status" == "pass" ]]
}

run_doctor() {
  local labels daily_loaded x_loaded monthly_loaded tentacle_loaded daily_plist_ok x_plist_ok monthly_plist_ok tentacle_plist_ok status row
  labels="$(launchctl_labels)"
  if grep -q "$DAILY_LABEL" <<<"$labels"; then daily_loaded=true; else daily_loaded=false; fi
  if grep -q "$X_LABEL" <<<"$labels"; then x_loaded=true; else x_loaded=false; fi
  if grep -q "$MONTHLY_LABEL" <<<"$labels"; then monthly_loaded=true; else monthly_loaded=false; fi
  if grep -q "$TENTACLE_DRIFT_LABEL" <<<"$labels"; then tentacle_loaded=true; else tentacle_loaded=false; fi
  if [[ -f "$DAILY_PLIST" ]]; then daily_plist_ok=true; else daily_plist_ok=false; fi
  if [[ -f "$X_PLIST" ]]; then x_plist_ok=true; else x_plist_ok=false; fi
  if [[ -f "$MONTHLY_PLIST" ]]; then monthly_plist_ok=true; else monthly_plist_ok=false; fi
  if [[ -f "$TENTACLE_DRIFT_PLIST" ]]; then tentacle_plist_ok=true; else tentacle_plist_ok=false; fi
  if [[ "$daily_loaded" == true && "$x_loaded" == true && "$monthly_loaded" == true && "$tentacle_loaded" == true && "$daily_plist_ok" == true && "$x_plist_ok" == true && "$monthly_plist_ok" == true && "$tentacle_plist_ok" == true ]]; then status="pass"; else status="fail"; fi
  row="$(schema_json | jq \
    --arg status "$status" \
    --argjson daily_loaded "$daily_loaded" \
    --argjson x_loaded "$x_loaded" \
    --argjson monthly_loaded "$monthly_loaded" \
    --argjson tentacle_loaded "$tentacle_loaded" \
    --argjson daily_plist_ok "$daily_plist_ok" \
    --argjson x_plist_ok "$x_plist_ok" \
    --argjson monthly_plist_ok "$monthly_plist_ok" \
    --argjson tentacle_plist_ok "$tentacle_plist_ok" \
    '. + {mode:"doctor",status:$status,loaded:{daily:$daily_loaded,x_hourly:$x_loaded,monthly_deep_mine:$monthly_loaded,tentacle_drift:$tentacle_loaded},plist_exists:{daily:$daily_plist_ok,x_hourly:$x_plist_ok,monthly_deep_mine:$monthly_plist_ok,tentacle_drift:$tentacle_plist_ok}}')"
  emit "$row"
  [[ "$status" == "pass" ]]
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="${2:-}"; [[ -n "$MODE" ]] || { echo "ERR: --mode requires value" >&2; exit 64; }; shift 2 ;;
    --daily) MODE="daily"; shift ;;
    --x-poll) MODE="x-poll"; shift ;;
    --monthly-deep-mine) MODE="monthly-deep-mine"; shift ;;
    --tentacle-drift) MODE="tentacle-drift"; shift ;;
    --doctor) MODE="doctor"; shift ;;
    --schema) MODE="schema"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --storage-min-free-pct) STORAGE_MIN_FREE_PCT="${2:-}"; shift 2 ;;
    --now) NOW="${2:-}"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    --examples)
      printf '%s\n' \
        'jeff-intel-scheduled-runner.sh --mode daily --dry-run --storage-min-free-pct 0 --json' \
        'jeff-intel-scheduled-runner.sh --mode x-poll --dry-run --json' \
        'jeff-intel-scheduled-runner.sh --mode monthly-deep-mine --dry-run --json' \
        'jeff-intel-scheduled-runner.sh --mode tentacle-drift --dry-run --json' \
        'jeff-intel-scheduled-runner.sh --mode doctor --json'
      exit 0 ;;
    *) echo "ERR: unknown argument: $1" >&2; exit 64 ;;
  esac
done

case "$MODE" in
  schema) schema_json ;;
  daily) run_daily ;;
  x-poll) run_x_poll ;;
  monthly-deep-mine) run_monthly_deep_mine ;;
  tentacle-drift) run_tentacle_drift ;;
  doctor) run_doctor ;;
  *) echo "ERR: unknown mode: $MODE" >&2; exit 64 ;;
esac
