#!/usr/bin/env bash
# .flywheel/scripts/skill-discoveries-aggregator.sh
# Weekly rollup of sd_ids from the canonical skill-discoveries.jsonl,
# cross-referenced against audit/ evidence and dispatch-log mentions.
# Bead: flywheel-4s3oy
#
# Usage:
#   skill-discoveries-aggregator.sh --info
#   skill-discoveries-aggregator.sh --doctor [--json]
#   skill-discoveries-aggregator.sh --apply [--week=YYYY-WW] [--out=path] [--json]
set -euo pipefail

VERSION="0.1.0"
SCHEMA_VERSION="skill-discoveries-weekly.v1"
SD_FILE="${SD_FILE:-$HOME/.local/state/flywheel/skill-discoveries.jsonl}"
DISPATCH_LOG="${DISPATCH_LOG:-/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl}"
AUDIT_DIR="${AUDIT_DIR:-/Users/josh/Developer/flywheel/.flywheel/audit}"
REPORTS_DIR="${REPORTS_DIR:-/Users/josh/Developer/flywheel/.flywheel/reports}"
TOP_N="${TOP_N:-10}"

mode="apply"
emit_json=0
week_target=""
out_path=""

usage() {
  cat <<EOF
skill-discoveries-aggregator.sh — weekly rollup of skill discoveries

Schema:  $SCHEMA_VERSION
Version: $VERSION

Modes (canonical-cli-scoping triad):
  --info            print this help and exit 0
  --schema          print rollup envelope schema (one line)
  --examples        print invocation examples
  --doctor          probe canonical sources (--json supported)
  --apply           run the weekly aggregation (mutation: writes report)

Options:
  --week=YYYY-WW    target week (default: current ISO week)
  --out=<path>      override output report path
                    (default: $REPORTS_DIR/skill-discoveries-weekly-<week>.md)
  --json            emit machine-readable rollup envelope to stdout
  --version         print version and exit 0

Exit codes:
  0  success
  1  internal error
  2  bad argument or missing dependency
  3  no sd entries found in window (empty week)

Sources read:
  primary:    \$SD_FILE          (canonical skill-discoveries.jsonl)
  secondary:  \$AUDIT_DIR/*/evidence.md  (sd_ids cross-references)

Output sections:
  - Top $TOP_N most-cited candidate_skill_names this week (frequency-ranked)
  - First-time-this-week classes (no prior occurrence in earlier rows)
  - Cross-worker agreements (same candidate cited by 2+ distinct workers)
  - Long-tail (one-off observations from this week)
EOF
}

examples() {
  cat <<'EOF'
# Default current-week run:
skill-discoveries-aggregator.sh --apply

# Specific ISO week:
skill-discoveries-aggregator.sh --apply --week=2026-19

# JSON envelope only (no markdown write):
skill-discoveries-aggregator.sh --apply --json --out=/dev/null

# Doctor probe (sources present, row count, latest ts):
skill-discoveries-aggregator.sh --doctor --json
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --info|-h|--help) usage; exit 0 ;;
    --schema)
      printf '{"schema_version":"%s","keys":["schema_version","week","window_start","window_end","total_entries","unique_candidates","top_n","first_time_classes","cross_worker_agreements","long_tail","by_kind","by_worker"]}\n' "$SCHEMA_VERSION"
      exit 0 ;;
    --examples)       examples; exit 0 ;;
    --version)        printf '%s\n' "$VERSION"; exit 0 ;;
    --doctor)         mode="doctor" ;;
    --apply)          mode="apply" ;;
    --json)           emit_json=1 ;;
    --week=*)         week_target="${1#--week=}" ;;
    --out=*)          out_path="${1#--out=}" ;;
    *) printf 'unknown flag: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }
err() { printf '%s\n' "$*" >&2; }
require() { command -v "$1" >/dev/null || { err "missing dependency: $1"; exit 2; }; }
require jq
require date

# ISO week resolution
current_iso_week() {
  date -u +%G-%V
}

# Compute Mon..Sun UTC bounds for an ISO week (YYYY-WW)
week_window() {
  # Returns: <start_iso> <end_iso>
  local target="$1"
  local year="${target%-*}"
  local week="${target#*-}"
  # macOS date doesn't support ISO-week arithmetic directly. Use python3 fallback.
  if command -v python3 >/dev/null; then
    python3 -c "
import datetime
y = int('$year'); w = int('$week')
mon = datetime.date.fromisocalendar(y, w, 1)
sun = mon + datetime.timedelta(days=6)
print(f'{mon.isoformat()}T00:00:00Z {sun.isoformat()}T23:59:59Z')
"
  else
    # crude fallback via gdate (GNU date) if available
    if command -v gdate >/dev/null; then
      local mon
      mon="$(gdate -d "${year}-W${week}-1" +%Y-%m-%d)"
      local sun
      sun="$(gdate -d "${mon} +6 days" +%Y-%m-%d)"
      printf '%sT00:00:00Z %sT23:59:59Z\n' "$mon" "$sun"
    else
      err "need python3 or gdate for ISO-week math"; exit 2
    fi
  fi
}

doctor() {
  local sd_present sd_lines latest_ts disp_present audit_present
  sd_present=false; sd_lines=0; latest_ts="null"
  if [[ -s "$SD_FILE" ]]; then
    sd_present=true
    sd_lines="$(wc -l < "$SD_FILE" | tr -d ' ')"
    latest_ts="$(jq -s -r 'sort_by(.ts) | last | .ts // "null"' "$SD_FILE" 2>/dev/null || echo null)"
  fi
  [[ -s "$DISPATCH_LOG" ]] && disp_present=true || disp_present=false
  [[ -d "$AUDIT_DIR" ]] && audit_present=true || audit_present=false

  if [[ "$emit_json" == 1 ]]; then
    jq -nc \
      --arg schema "skill-discoveries-aggregator-doctor.v1" \
      --arg ts "$(iso)" \
      --argjson sd "$sd_present" \
      --argjson sd_lines "$sd_lines" \
      --arg latest "$latest_ts" \
      --argjson disp "$disp_present" \
      --argjson audit "$audit_present" \
      --arg sd_file "$SD_FILE" \
      '{schema_version:$schema,ts:$ts,sd_jsonl_present:$sd,sd_jsonl_lines:$sd_lines,sd_jsonl_latest_ts:$latest,sd_jsonl_path:$sd_file,dispatch_log_present:$disp,audit_dir_present:$audit}'
  else
    printf 'sd_jsonl=%s lines=%d latest=%s\n' "$sd_present" "$sd_lines" "$latest_ts"
    printf 'dispatch_log=%s audit_dir=%s\n' "$disp_present" "$audit_present"
  fi
  $sd_present || exit 1
  exit 0
}

apply() {
  [[ -s "$SD_FILE" ]] || { err "missing or empty $SD_FILE"; exit 2; }
  if [[ -z "$week_target" ]]; then
    week_target="$(current_iso_week)"
  fi
  read -r window_start window_end <<<"$(week_window "$week_target")"

  local report_path="${out_path:-$REPORTS_DIR/skill-discoveries-weekly-$week_target.md}"
  if [[ "$report_path" != "/dev/null" ]]; then
    mkdir -p "$(dirname "$report_path")"
  fi

  # Filter rows in window. Normalize: candidate := candidate_skill_name //
  # topic // proposed_skill // "<unknown>"; kind := discovery_kind // kind;
  # worker := worker_identity // worker_pane (as worker-N) // "unknown"
  local in_window prior
  in_window="$(jq -c --arg s "$window_start" --arg e "$window_end" '
    select(.ts >= $s and .ts <= $e) |
    {
      discovery_id,
      ts,
      candidate: (.candidate_skill_name // .topic // .proposed_skill // "<unknown>"),
      kind: (.discovery_kind // .kind // "unknown"),
      worker: (.worker_identity // (if (.worker_pane // null) != null then ("worker-" + (.worker_pane|tostring)) else "unknown" end)),
      session: (.session // "unknown"),
      task_context: (.task_context // .task_id // "unknown"),
      promotion_signal: (.promotion_signal // null),
      should_become: (.should_become // null),
      blocking: (.blocking_current_work // null),
      raw: .
    }' "$SD_FILE" 2>/dev/null)"

  prior="$(jq -c --arg s "$window_start" '
    select(.ts < $s) |
    {candidate: (.candidate_skill_name // .topic // .proposed_skill // "<unknown>")}' "$SD_FILE" 2>/dev/null)"

  if [[ -z "$in_window" ]]; then
    err "no skill-discovery entries in window $window_start .. $window_end"
    if [[ "$emit_json" == 1 ]]; then
      jq -nc --arg schema "$SCHEMA_VERSION" --arg w "$week_target" --arg s "$window_start" --arg e "$window_end" \
        '{schema_version:$schema,week:$w,window_start:$s,window_end:$e,total_entries:0,empty_week:true}'
    fi
    exit 3
  fi

  # Aggregations via jq -s
  local rollup
  rollup="$(jq -nc \
    --arg schema "$SCHEMA_VERSION" \
    --arg w "$week_target" \
    --arg s "$window_start" \
    --arg e "$window_end" \
    --argjson topn "$TOP_N" \
    --slurpfile rows <(printf '%s\n' "$in_window") \
    --slurpfile pri  <(printf '%s\n' "$prior") '
    ($rows // []) as $entries |
    ($pri  // []) as $prior_entries |
    ($entries | group_by(.candidate)) as $by_cand |
    ($entries | group_by(.kind))      as $by_kind |
    ($entries | group_by(.worker))    as $by_worker |
    ($prior_entries | map(.candidate) | unique) as $prior_cands |
    {
      schema_version: $schema,
      week: $w,
      window_start: $s,
      window_end: $e,
      total_entries: ($entries | length),
      unique_candidates: ($by_cand | length),
      top_n: ($by_cand
        | map({candidate: .[0].candidate, count: length, kinds: (map(.kind) | unique), workers: (map(.worker) | unique), example_ts: .[0].ts})
        | sort_by(-.count, .candidate)
        | .[0:$topn]),
      first_time_classes: ($by_cand
        | map(select(.[0].candidate as $c | ($prior_cands | index($c)) == null))
        | map({candidate: .[0].candidate, count: length, ts: .[0].ts, kinds: (map(.kind) | unique)})
        | sort_by(.ts)),
      cross_worker_agreements: ($by_cand
        | map({candidate: .[0].candidate, count: length, distinct_workers: (map(.worker) | unique)})
        | map(select(.distinct_workers | length >= 2))
        | sort_by(-.count, .candidate)),
      long_tail: ($by_cand
        | map(select(length == 1))
        | map({candidate: .[0].candidate, ts: .[0].ts, kind: .[0].kind, worker: .[0].worker})
        | sort_by(.ts)),
      by_kind: ($by_kind
        | map({kind: .[0].kind, count: length})
        | sort_by(-.count)),
      by_worker: ($by_worker
        | map({worker: .[0].worker, count: length})
        | sort_by(-.count))
    }')"

  # Render markdown
  if [[ "$report_path" != "/dev/null" ]]; then
    {
      printf '# Skill discoveries — weekly rollup %s\n\n' "$week_target"
      printf '_Window: %s → %s · source: `%s`_\n\n' "$window_start" "$window_end" "$SD_FILE"

      total="$(jq -r '.total_entries' <<<"$rollup")"
      uniq="$(jq -r '.unique_candidates' <<<"$rollup")"
      printf '## Headline\n\n'
      printf '**%s entries** observed this week across **%s distinct candidate classes** by **%s workers**.\n\n' \
        "$total" "$uniq" "$(jq -r '.by_worker | length' <<<"$rollup")"

      printf '## Top %s most-cited classes\n\n' "$TOP_N"
      jq -r '
        .top_n[]?
        | "- **\(.candidate)** — `\(.count)` × · kinds=`\((.kinds // [])|join(","))` · workers=`\((.workers // [])|join(","))`"
      ' <<<"$rollup"
      printf '\n'

      printf '## First-time-this-week classes\n\n'
      ftw_count="$(jq -r '.first_time_classes | length' <<<"$rollup")"
      if [[ "$ftw_count" -eq 0 ]]; then
        printf '_no new classes this week (all observations match prior weeks)_\n\n'
      else
        jq -r '.first_time_classes[]? | "- **\(.candidate)** · `\(.count)` × · first ts=`\(.ts)` · kinds=`\((.kinds // [])|join(","))`"' <<<"$rollup"
        printf '\n'
      fi

      printf '## Cross-worker agreements (≥2 distinct workers cite same class)\n\n'
      cwa_count="$(jq -r '.cross_worker_agreements | length' <<<"$rollup")"
      if [[ "$cwa_count" -eq 0 ]]; then
        printf '_no cross-worker agreements this week_\n\n'
      else
        jq -r '.cross_worker_agreements[]? | "- **\(.candidate)** — `\(.count)` × · workers=`\(.distinct_workers|join(","))`"' <<<"$rollup"
        printf '\n'
      fi

      printf '## By kind\n\n'
      jq -r '.by_kind[]? | "- `\(.kind)` — \(.count)"' <<<"$rollup"
      printf '\n'

      printf '## By worker\n\n'
      jq -r '.by_worker[]? | "- `\(.worker)` — \(.count)"' <<<"$rollup"
      printf '\n'

      printf '## Long-tail (one-off observations)\n\n'
      lt_count="$(jq -r '.long_tail | length' <<<"$rollup")"
      if [[ "$lt_count" -eq 0 ]]; then
        printf '_no one-off observations_\n\n'
      else
        jq -r '.long_tail[]? | "- `\(.candidate)` · ts=`\(.ts)` · kind=`\(.kind)` · worker=`\(.worker)`"' <<<"$rollup"
        printf '\n'
      fi

      printf -- '---\n_Generated by `%s` v%s · schema `%s` · `%s entries`_\n' \
        ".flywheel/scripts/skill-discoveries-aggregator.sh" "$VERSION" "$SCHEMA_VERSION" "$total"
    } > "$report_path"
  fi

  if [[ "$emit_json" == 1 ]]; then
    printf '%s\n' "$rollup" | jq -c \
      --arg p "$report_path" '. + {report_path:$p}'
  else
    printf 'report=%s entries=%s candidates=%s\n' \
      "$report_path" \
      "$(jq -r '.total_entries' <<<"$rollup")" \
      "$(jq -r '.unique_candidates' <<<"$rollup")"
  fi
}

case "$mode" in
  doctor) doctor ;;
  apply)  apply ;;
  *)      err "unknown mode: $mode"; exit 2 ;;
esac
