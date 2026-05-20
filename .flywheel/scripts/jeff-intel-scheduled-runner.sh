#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial -> passing per bead flywheel-k8gcv.16)
set -euo pipefail

VERSION="jeff-intel-scheduled-runner.v1.1.0"
SCHEMA_VERSION_INFO="jeff-intel-scheduled-runner/v1"
IDEMPOTENCY_KEY=""
APPLY=0
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

emit_info() {
  jq -nc \
    --arg sv "$SCHEMA_VERSION_INFO" \
    --arg version "$VERSION" \
    --arg ledger "$LEDGER" \
    --arg state_dir "$STATE_DIR" \
    '{
      schema_version:$sv,
      command:"info",
      name:"jeff-intel-scheduled-runner.sh",
      version:$version,
      ledger:$ledger,
      state_dir:$state_dir,
      purpose:"launchd-driven runner for Jeff intel ingest cadences: daily (5-source), x-poll (hourly), monthly-deep-mine (philosophy), tentacle-drift (weekly readonly).",
      subcommands:["doctor","health","validate","audit","why","repair","quickstart"],
      legacy_modes:["daily","x-poll","monthly-deep-mine","tentacle-drift","doctor"],
      canonical_flags:["--info","--schema","--examples","--json","--apply","--dry-run","--idempotency-key","--mode","--daily","--x-poll","--monthly-deep-mine","--tentacle-drift","--doctor","--storage-min-free-pct","--now"],
      capabilities:[
        "launchd-label-aware-cadence-runner",
        "daily-ingest-5-sources",
        "daily-source-regeneration-apply-with-per-day-idempotency-key",
        "hourly-x-poll-for-doodlestein",
        "monthly-deep-mine-philosophy",
        "weekly-tentacle-drift-readonly",
        "fixture-driven-launchctl-list-mode",
        "storage-min-free-pct-precheck",
        "receipt-jsonl-append-per-run"
      ],
      apply_supported:true,
      dry_run_supported:true,
      idempotency_key_required_for_apply:true,
      mutates_state:true,
      env_vars:["JEFF_INTEL_STATE_DIR","FLYWHEEL_STATE_DIR","JEFF_INTEL_SCHEDULE_LEDGER","JEFF_INTEL_X_LEDGER","JEFF_INTEL_X_SNAPSHOT_DIR","JEFF_INTEL_DAILY_SCRIPT","JEFF_INTEL_X_FIXTURE","JEFF_INTEL_LAUNCHCTL_LIST_FIXTURE","JEFF_INTEL_STORAGE_MIN_FREE_PCT","JEFF_INTEL_NOW"],
      exit_codes:{"0":"success","1":"mode-fail","3":"refused-apply-without-idempotency-key","64":"bad-args"}
    }'
}

emit_examples_json() {
  jq -nc --arg sv "$SCHEMA_VERSION_INFO" '{
    schema_version:$sv,
    command:"examples",
    examples:[
      {name:"daily-dry-run",invocation:"jeff-intel-scheduled-runner.sh --mode daily --dry-run --storage-min-free-pct 0 --json",purpose:"dry-run the daily 5-source ingest pipeline"},
      {name:"x-poll-dry-run",invocation:"jeff-intel-scheduled-runner.sh --mode x-poll --dry-run --json",purpose:"dry-run the hourly @doodlestein X poll"},
      {name:"monthly-deep-mine-dry-run",invocation:"jeff-intel-scheduled-runner.sh --mode monthly-deep-mine --dry-run --json",purpose:"dry-run the monthly Jeff philosophy refresh"},
      {name:"tentacle-drift-apply",invocation:"jeff-intel-scheduled-runner.sh --mode tentacle-drift --apply --idempotency-key tds-2026-05-11 --json",purpose:"weekly readonly drift sweep (requires --idempotency-key)"},
      {name:"doctor",invocation:"jeff-intel-scheduled-runner.sh doctor --json",purpose:"canonical doctor envelope (.checks shape)"}
    ]
  }'
}

emit_canonical_doctor() {
  # Direct probe (no subshell to run_doctor — too fragile w/ inherited env).
  # Build .checks from on-disk plist presence + launchctl list (with fixture
  # support via LAUNCHCTL_LIST_FIXTURE).
  local ts; ts="$(now_iso)"
  local labels_out=""
  if [[ -n "$LAUNCHCTL_LIST_FIXTURE" && -r "$LAUNCHCTL_LIST_FIXTURE" ]]; then
    labels_out="$(cat "$LAUNCHCTL_LIST_FIXTURE" 2>/dev/null || true)"
  else
    labels_out="$(launchctl list 2>/dev/null || true)"
  fi
  local daily_label_s x_label_s monthly_label_s tentacle_label_s
  local daily_plist_s x_plist_s monthly_plist_s tentacle_plist_s
  if printf '%s' "$labels_out" | grep -qw "$DAILY_LABEL"; then daily_label_s="pass"; else daily_label_s="warn"; fi
  if printf '%s' "$labels_out" | grep -qw "$X_LABEL"; then x_label_s="pass"; else x_label_s="warn"; fi
  if printf '%s' "$labels_out" | grep -qw "$MONTHLY_LABEL"; then monthly_label_s="pass"; else monthly_label_s="warn"; fi
  if printf '%s' "$labels_out" | grep -qw "$TENTACLE_DRIFT_LABEL"; then tentacle_label_s="pass"; else tentacle_label_s="warn"; fi
  if [[ -f "$DAILY_PLIST" ]]; then daily_plist_s="pass"; else daily_plist_s="warn"; fi
  if [[ -f "$X_PLIST" ]]; then x_plist_s="pass"; else x_plist_s="warn"; fi
  if [[ -f "$MONTHLY_PLIST" ]]; then monthly_plist_s="pass"; else monthly_plist_s="warn"; fi
  if [[ -f "$TENTACLE_DRIFT_PLIST" ]]; then tentacle_plist_s="pass"; else tentacle_plist_s="warn"; fi
  local overall="pass"
  for s in "$daily_label_s" "$x_label_s" "$monthly_label_s" "$tentacle_label_s" \
           "$daily_plist_s" "$x_plist_s" "$monthly_plist_s" "$tentacle_plist_s"; do
    [[ "$s" == "warn" ]] && overall="warn"
  done
  jq -nc --arg sv "$SCHEMA_VERSION_INFO.doctor" --arg ts "$ts" --arg overall "$overall" --arg version "$VERSION" \
    --arg dl "$daily_label_s" --arg xl "$x_label_s" --arg ml "$monthly_label_s" --arg tl "$tentacle_label_s" \
    --arg dp "$daily_plist_s" --arg xp "$x_plist_s" --arg mp "$monthly_plist_s" --arg tp "$tentacle_plist_s" \
    --arg daily_plist "$DAILY_PLIST" --arg x_plist "$X_PLIST" --arg monthly_plist "$MONTHLY_PLIST" --arg tentacle_plist "$TENTACLE_DRIFT_PLIST" \
    '{
      schema_version:$sv,
      command:"doctor",
      ts:$ts,
      status:$overall,
      version:$version,
      checks:[
        {name:"launchd_daily",status:$dl,detail:"launchctl loaded label for daily ingest"},
        {name:"launchd_x_hourly",status:$xl,detail:"launchctl loaded label for x-poll hourly"},
        {name:"launchd_monthly_deep_mine",status:$ml,detail:"launchctl loaded label for monthly deep-mine"},
        {name:"launchd_tentacle_drift",status:$tl,detail:"launchctl loaded label for tentacle-drift weekly"},
        {name:"plist_daily",status:$dp,path:$daily_plist,detail:"plist file for daily ingest exists"},
        {name:"plist_x_hourly",status:$xp,path:$x_plist,detail:"plist file for x-poll exists"},
        {name:"plist_monthly_deep_mine",status:$mp,path:$monthly_plist,detail:"plist file for monthly deep-mine exists"},
        {name:"plist_tentacle_drift",status:$tp,path:$tentacle_plist,detail:"plist file for tentacle-drift exists"}
      ]
    }'
}

emit_health() {
  local ts; ts="$(now_iso)"
  local schedule_count=0 x_count=0
  [[ -r "$LEDGER" ]] && schedule_count="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
  [[ -r "$X_LEDGER" ]] && x_count="$(wc -l <"$X_LEDGER" 2>/dev/null | tr -d ' ')"
  [[ -z "$schedule_count" ]] && schedule_count=0
  [[ -z "$x_count" ]] && x_count=0
  jq -nc --arg sv "$SCHEMA_VERSION_INFO.health" --arg ts "$ts" \
    --arg schedule_ledger "$LEDGER" --arg x_ledger "$X_LEDGER" \
    --argjson schedule_count "$schedule_count" --argjson x_count "$x_count" \
    '{schema_version:$sv,command:"health",ts:$ts,status:"pass",schedule_ledger:$schedule_ledger,schedule_row_count:$schedule_count,x_poll_ledger:$x_ledger,x_poll_row_count:$x_count}'
}

emit_canonical_validate() {
  local ts; ts="$(now_iso)"
  local rows=0 invalid=0
  if [[ -r "$LEDGER" ]]; then
    rows="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$rows" ]] && rows=0
    if [[ "$rows" -gt 0 ]]; then
      invalid="$(jq -c 'select((.schema_version // "") == "" or (.mode // "") == "")' "$LEDGER" 2>/dev/null | wc -l | tr -d ' ')"
      [[ -z "$invalid" ]] && invalid=0
    fi
  fi
  local status="pass"
  [[ "$invalid" -gt 0 ]] && status="violations"
  jq -nc --arg sv "$SCHEMA_VERSION_INFO.validate" --arg ts "$ts" --arg status "$status" \
    --argjson rows "${rows:-0}" --argjson invalid "${invalid:-0}" --arg ledger "$LEDGER" \
    '{schema_version:$sv,command:"validate",ts:$ts,status:$status,ledger:$ledger,row_count:$rows,invalid_row_count:$invalid,check:"every scheduled-run row has non-empty schema_version + mode"}'
}

emit_audit() {
  local limit="${1:-20}"
  local ts; ts="$(now_iso)"
  if [[ ! -r "$LEDGER" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION_INFO.audit" --arg ts "$ts" --arg ledger "$LEDGER" \
      '{schema_version:$sv,command:"audit",ts:$ts,status:"missing",ledger:$ledger,row_count:0,recent:[]}'
    return 0
  fi
  local row_count
  row_count="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
  [[ -z "$row_count" ]] && row_count=0
  local recent='[]'
  if [[ "$row_count" -gt 0 ]]; then
    recent="$(tail -n "$limit" "$LEDGER" 2>/dev/null | jq -cs '.' 2>/dev/null || printf '%s' '[]')"
    [[ -z "$recent" ]] && recent='[]'
  fi
  local status="pass"
  [[ "$row_count" -eq 0 ]] && status="empty"
  jq -nc --arg sv "$SCHEMA_VERSION_INFO.audit" --arg ts "$ts" --arg status "$status" \
    --arg ledger "$LEDGER" --argjson row_count "$row_count" --argjson recent "$recent" \
    '{schema_version:$sv,command:"audit",ts:$ts,status:$status,ledger:$ledger,row_count:$row_count,recent:$recent}'
}

emit_why() {
  local topic="${1:-}"
  local body=""
  case "$topic" in
    ""|launchd-cadences)
      body='Four cadences: daily (sources.txt regeneration plus 5-source ingest, GitHub+RSS+X+JSM+mirror), x-poll (hourly @doodlestein X capture), monthly-deep-mine (Jeff philosophy refresh), tentacle-drift (weekly readonly drift sweep). Each has a dedicated launchd plist + label so cron-equivalent scheduling lives in macOS native subsystem, not in shell.'
      ;;
    storage-precheck)
      body='--storage-min-free-pct precheck guards against running ingest when disk is full — daily ingest snapshots can be hundreds of MB. Default behavior reads JEFF_INTEL_STORAGE_MIN_FREE_PCT env; --storage-min-free-pct=0 disables the precheck (for tests).'
      ;;
    receipt-paths)
      body='Each mode appends a JSONL receipt to a dedicated ledger: scheduled-runs.jsonl, x-poll.jsonl, daily-jeff-ingest.jsonl, tentacle-drift.jsonl. Receipts include ts + mode + status + (mode-specific fields). doctor surface aggregates loaded launchctl labels + plist_exists across all four.'
      ;;
    *)
      body="unknown topic: $topic. known: launchd-cadences, storage-precheck, receipt-paths"
      ;;
  esac
  jq -nc --arg sv "$SCHEMA_VERSION_INFO" --arg topic "${topic:-launchd-cadences}" --arg body "$body" \
    '{schema_version:$sv,command:"why",topic:$topic,body:$body}'
}

emit_quickstart() {
  jq -nc --arg sv "$SCHEMA_VERSION_INFO" '{
    schema_version:$sv,
    command:"quickstart",
    status:"ok",
    steps:[
      {step:1,action:"check-doctor",command:"jeff-intel-scheduled-runner.sh doctor --json"},
      {step:2,action:"dry-run-daily",command:"jeff-intel-scheduled-runner.sh --mode daily --dry-run --storage-min-free-pct 0 --json"},
      {step:3,action:"verify-launchd-loaded",command:"launchctl list | grep flywheel-jeff"},
      {step:4,action:"tail-receipts",command:"jeff-intel-scheduled-runner.sh audit --json"}
    ],
    next_actions:["install-launchd-plists","wire-storage-monitoring"]
  }'
}

emit_repair() {
  local scope="" mode="dry_run" idem_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --scope) scope="${2:-}"; shift 2 ;;
      --dry-run) mode="dry_run"; shift ;;
      --apply) mode="apply"; shift ;;
      --idempotency-key) idem_key="${2:-}"; shift 2 ;;
      --idempotency-key=*) idem_key="${1#--idempotency-key=}"; shift ;;
      --json) shift ;;
      --help|-h) printf 'repair --scope <ledger-prime|state-dir-prime> [--dry-run|--apply --idempotency-key KEY]\n'; exit 0 ;;
      "") shift ;;
      *) printf 'ERR: unknown repair arg %s\n' "$1" >&2; exit 2 ;;
    esac
  done
  if [[ -z "$scope" ]]; then
    printf '{"schema_version":"%s.repair","status":"refused","reason":"--scope required (ledger-prime|state-dir-prime)","exit_code":2}\n' "$SCHEMA_VERSION_INFO"
    exit 2
  fi
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    printf '{"schema_version":"%s.repair","status":"refused","mode":"apply","scope":"%s","reason":"--apply requires --idempotency-key","exit_code":3}\n' "$SCHEMA_VERSION_INFO" "$scope"
    exit 3
  fi
  local ts; ts="$(now_iso)"
  case "$scope" in
    ledger-prime|state-dir-prime)
      local target="$LEDGER"
      [[ "$scope" == "state-dir-prime" ]] && target="$STATE_DIR"
      local before_exists; before_exists="$([[ -e "$target" ]] && printf true || printf false)"
      if [[ "$mode" == "apply" ]]; then
        if [[ "$scope" == "state-dir-prime" ]]; then
          mkdir -p "$target" 2>/dev/null || true
        else
          mkdir -p "$(dirname "$target")" 2>/dev/null || true
          [[ -f "$target" ]] || : > "$target"
        fi
      fi
      local after_exists; after_exists="$([[ -e "$target" ]] && printf true || printf false)"
      jq -nc --arg sv "$SCHEMA_VERSION_INFO.repair" --arg ts "$ts" --arg scope "$scope" --arg mode "$mode" \
        --arg path "$target" --arg key "$idem_key" \
        --argjson before "$before_exists" --argjson after "$after_exists" \
        '{schema_version:$sv,command:"repair",ts:$ts,status:"pass",scope:$scope,mode:$mode,idempotency_key:$key,target:$path,present_before:$before,present_after:$after}'
      ;;
    *)
      printf '{"schema_version":"%s.repair","status":"refused","scope":"%s","reason":"unknown scope; known: ledger-prime, state-dir-prime","exit_code":2}\n' "$SCHEMA_VERSION_INFO" "$scope"
      exit 2
      ;;
  esac
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
      command:"schema",
      input_schema:{
        type:"object",
        properties:{
          mode:{enum:["daily","x-poll","monthly-deep-mine","tentacle-drift","doctor"]},
          dry_run:{type:"boolean"},
          apply:{type:"boolean"},
          idempotency_key:{type:"string",description:"required with --apply"},
          storage_min_free_pct:{type:"number",description:"abort if disk free pct below this"},
          now:{type:"string",description:"override ISO timestamp for tests"}
        }
      },
      output_schema:{
        type:"object",
        required:["schema_version","mode","status"],
        properties:{
          schema_version:{type:"string"},
          mode:{type:"string"},
          status:{enum:["pass","fail","warn","ok"]},
          ts:{type:"string",format:"date-time"},
          receipt_path:{type:"string"},
          version:{type:"string"}
        }
      },
      version:$version,
      launchd_labels:{daily:$daily_label,x_hourly:$x_label,monthly_deep_mine:$monthly_label,tentacle_drift:$tentacle_label},
      launchd_plists:{daily:$daily_plist,x_hourly:$x_plist,monthly_deep_mine:$monthly_plist,tentacle_drift:$tentacle_plist},
      source_cadence:{
        github_git:"daily via sources.txt regeneration apply, daily-jeff-ingest, and jeff-corpus diff watcher surface",
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
    if [[ "$DRY_RUN" -eq 1 ]]; then
      "$SOURCE_REGEN_SCRIPT" --dry-run --now "$ts" --json >"$tmp/source-regeneration.json" || regen_rc=$?
    else
      local regen_key_date source_regen_key
      regen_key_date="${ts%%T*}"
      source_regen_key="${IDEMPOTENCY_KEY:-daily-jeff-sources-${regen_key_date}}"
      "$SOURCE_REGEN_SCRIPT" --apply --idempotency-key "$source_regen_key" --now "$ts" --json >"$tmp/source-regeneration.json" || regen_rc=$?
    fi
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

# Canonical no-dash subcommand intercept BEFORE main arg parser.
case "${1:-}" in
  --info) emit_info; exit 0 ;;
  doctor) shift; emit_canonical_doctor; exit 0 ;;
  health) shift; emit_health; exit 0 ;;
  validate) shift; emit_canonical_validate; exit 0 ;;
  audit)
    shift
    LIMIT=20
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --limit) LIMIT="${2:-20}"; shift 2 ;;
        --json) shift ;;
        "") shift ;;
        *) shift ;;
      esac
    done
    emit_audit "$LIMIT"
    exit 0
    ;;
  why)
    shift
    TOPIC=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --json) shift ;;
        "") shift ;;
        *) [[ -z "$TOPIC" ]] && TOPIC="$1"; shift ;;
      esac
    done
    emit_why "$TOPIC"
    exit 0
    ;;
  quickstart) shift; emit_quickstart; exit 0 ;;
  repair) shift; emit_repair "$@"; exit 0 ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="${2:-}"; [[ -n "$MODE" ]] || { echo "ERR: --mode requires value" >&2; exit 64; }; shift 2 ;;
    --daily) MODE="daily"; shift ;;
    --x-poll) MODE="x-poll"; shift ;;
    --monthly-deep-mine) MODE="monthly-deep-mine"; shift ;;
    --tentacle-drift) MODE="tentacle-drift"; shift ;;
    --doctor) MODE="doctor"; shift ;;
    --schema) MODE="schema"; shift ;;
    --info) emit_info; exit 0 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --apply) APPLY=1; shift ;;
    --idempotency-key) IDEMPOTENCY_KEY="${2:-}"; shift 2 ;;
    --idempotency-key=*) IDEMPOTENCY_KEY="${1#--idempotency-key=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --storage-min-free-pct) STORAGE_MIN_FREE_PCT="${2:-}"; shift 2 ;;
    --now) NOW="${2:-}"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    --examples)
      shift
      if [[ "${1:-}" == "--json" ]]; then
        emit_examples_json
      else
        printf '%s\n' \
          'jeff-intel-scheduled-runner.sh --mode daily --dry-run --storage-min-free-pct 0 --json' \
          'jeff-intel-scheduled-runner.sh --mode x-poll --dry-run --json' \
          'jeff-intel-scheduled-runner.sh --mode monthly-deep-mine --dry-run --json' \
          'jeff-intel-scheduled-runner.sh --mode tentacle-drift --dry-run --json' \
          'jeff-intel-scheduled-runner.sh --mode doctor --json'
      fi
      exit 0 ;;
    *) echo "ERR: unknown argument: $1" >&2; exit 64 ;;
  esac
done

# Canonical apply contract: --apply requires --idempotency-key.
if [[ "$APPLY" -eq 1 && -z "$IDEMPOTENCY_KEY" ]]; then
  printf '{"schema_version":"%s","status":"refused","mode":"apply","reason":"--apply requires --idempotency-key","exit_code":3}\n' "$SCHEMA_VERSION_INFO"
  exit 3
fi

case "$MODE" in
  schema) schema_json ;;
  daily) run_daily ;;
  x-poll) run_x_poll ;;
  monthly-deep-mine) run_monthly_deep_mine ;;
  tentacle-drift) run_tentacle_drift ;;
  doctor) run_doctor ;;
  *) echo "ERR: unknown mode: $MODE" >&2; exit 64 ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-76-authority-ranked-retrieval-maintenance.md`
