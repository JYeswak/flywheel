#!/usr/bin/env bash
# customer-facing-observability-probe.sh — smallest recurring measurement
# for value-gap dimension `customer-facing-observability` (#3 of 10 in
# `.flywheel/scripts/value-gap-probe.sh:DIMENSIONS[]`).
#
# Owns: bead flywheel-1rmp.14. Sisters (same shape): flywheel-1rmp.5,
# flywheel-1rmp.7, flywheel-1rmp.9, flywheel-1rmp.11.
#
# Measures (proxy):
#   - per-client repo presence (alpsinsurance, blackfoot, terratitle,
#     plus active product surfaces zesttube + mobile-eats)
#   - per-client .flywheel/reports/ daily-report freshness (mtime)
#   - aggregated coverage_count / coverage_ratio
#   - explicit customer_observability_state=no_aggregation_pipeline_yet
#     because no flywheel-side surface aggregates per-client health
#     into a single dashboard / receipt
#
# Step 4o anti-pattern guardrail: SURFACES the gap; does NOT
# auto-create receipts, file beads, or dispatch fixes.
#
# Stable exit codes: 0 ok | 1 domain | 64 usage
# Triad: doctor / info / schema; --json default for robot consumers.

set -uo pipefail

VERSION="customer-facing-observability-probe.v1"
SCRIPT_VERSION="2026-05-09.1"

DEV_ROOT="${CUSTOMER_OBS_DEV_ROOT:-/Users/josh/Developer}"
LEDGER="${CUSTOMER_OBS_LEDGER:-$HOME/.local/state/flywheel/customer-facing-observability.jsonl}"
FRESHNESS_HOURS="${CUSTOMER_OBS_FRESHNESS_HOURS:-72}"

# canonical client/product surfaces — extend over time
CLIENT_SLUGS=(alpsinsurance blackfoot terratitle)
PRODUCT_SLUGS=(zesttube mobile-eats)

JSON_OUT=0
MODE="run"
APPLY=0
DRY_RUN=0

usage() {
  cat <<'USAGE'
Usage:
  customer-facing-observability-probe.sh [--apply|--dry-run] [--json]
  customer-facing-observability-probe.sh --doctor [--json]
  customer-facing-observability-probe.sh --info [--json]
  customer-facing-observability-probe.sh --schema [--json]
  customer-facing-observability-probe.sh --help

Smallest recurring measurement for the value-gap-hunter dimension
"customer-facing-observability". Probes presence + report-freshness
across clients (alpsinsurance/blackfoot/terratitle) and active
product surfaces (zesttube/mobile-eats).
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --dry-run) DRY_RUN=1; APPLY=0; shift ;;
    --dev-root) DEV_ROOT="${2:?}"; shift 2 ;;
    --ledger) LEDGER="${2:?}"; shift 2 ;;
    --doctor) MODE="doctor"; shift ;;
    --info) MODE="info"; shift ;;
    --schema) MODE="schema"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "customer-facing-observability-probe.sh: unknown arg: $1" >&2; usage >&2; exit 64 ;;
  esac
done

if [[ $MODE == "run" && $APPLY -eq 0 && $DRY_RUN -eq 0 ]]; then
  DRY_RUN=1
fi

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }
emit() {
  if [[ $JSON_OUT -eq 1 || $MODE == "info" || $MODE == "schema" || $MODE == "doctor" ]]; then
    printf '%s\n' "$1"
  fi
}

info_payload() {
  jq -nc \
    --arg version "$VERSION" \
    --arg script_version "$SCRIPT_VERSION" \
    --arg dev_root "$DEV_ROOT" \
    --arg ledger "$LEDGER" \
    --argjson freshness "$FRESHNESS_HOURS" \
    --argjson clients "$(printf '%s\n' "${CLIENT_SLUGS[@]}" | jq -R . | jq -s .)" \
    --argjson products "$(printf '%s\n' "${PRODUCT_SLUGS[@]}" | jq -R . | jq -s .)" \
    '{
      version: $version,
      script_version: $script_version,
      schema_version: "customer-facing-observability/v1",
      mode: "info",
      dev_root: $dev_root,
      ledger: $ledger,
      client_slugs: $clients,
      product_slugs: $products,
      freshness_budget_hours: $freshness,
      modes: ["run","doctor","info","schema"],
      owns: "flywheel-1rmp.14",
      parent: "flywheel-1rmp",
      value_gap_dimension: "customer-facing-observability",
      meadows_tier: "#8 information flow",
      customer_observability_state: "no_aggregation_pipeline_yet",
      no_aggregation_reason: "Each client/product repo can have its own .flywheel/reports/ daily-report (mobile-eats does), but no flywheel-side surface aggregates per-client customer-visible value+risk into a single receipt or dashboard. The smallest recurring proxy is presence + freshness inventory until an aggregation pipeline lands.",
      step_4o_anti_pattern_guardrail: "this probe surfaces; it does NOT auto-aggregate, auto-publish, or auto-file followups",
      status: "ok"
    }'
}

schema_payload() {
  jq -nc '{
    schema_version: "customer-facing-observability/v1",
    ledger_row_required_fields: [
      "schema_version","ts","dev_root","client_count","product_count",
      "repos_present_count","repos_total","reports_dir_present_count",
      "fresh_report_count","stale_report_count","missing_report_count",
      "coverage_ratio","customer_observability_state",
      "no_aggregation_reason","clients","products"
    ],
    proxy_metrics: [
      {"name":"repos_present_count","describes":"client/product repos resolvable under dev_root"},
      {"name":"reports_dir_present_count","describes":"repos with .flywheel/reports/ directory"},
      {"name":"fresh_report_count","describes":"repos whose newest daily-report mtime is within freshness_budget_hours"},
      {"name":"coverage_ratio","describes":"fresh / total"}
    ],
    customer_observability_state_enum: ["no_aggregation_pipeline_yet","draft","wired"],
    surfaced_via: ["ledger:~/.local/state/flywheel/customer-facing-observability.jsonl","cli:customer-facing-observability-probe.sh","value-gap-probe parent ledger"],
    exit_codes: {"0":"ok","1":"domain","64":"usage"},
    mode: "schema",
    status: "ok"
  }'
}

doctor_payload() {
  local issues=()
  command -v jq >/dev/null 2>&1 || issues+=("jq_missing")
  [[ -d "$DEV_ROOT" ]] || issues+=("dev_root_missing=$DEV_ROOT")
  mkdir -p "$(dirname "$LEDGER")" 2>/dev/null
  [[ -w "$(dirname "$LEDGER")" ]] || issues+=("ledger_dir_not_writable=$(dirname "$LEDGER")")
  local issues_json
  if [[ ${#issues[@]} -gt 0 ]]; then
    issues_json=$(printf '%s\n' "${issues[@]}" | jq -R . | jq -s .)
  else
    issues_json='[]'
  fi
  jq -nc \
    --arg version "$VERSION" \
    --argjson issues "$issues_json" \
    '{
      version: $version,
      schema_version: "customer-facing-observability/v1",
      mode: "doctor",
      issues: $issues,
      status: (if ($issues|length)==0 then "ok" else "degraded" end)
    }'
}

mtime_iso() { stat -f '%Sm' -t '%Y-%m-%dT%H:%M:%SZ' "$1" 2>/dev/null; }
mtime_epoch() { stat -f '%m' "$1" 2>/dev/null; }

probe_repo() {
  local kind="$1" slug="$2" now_epoch="$3"
  local repo="$DEV_ROOT/$slug"
  local repo_present=false reports_dir=false newest_report="" newest_iso="" newest_age=999999
  local report_status="missing"

  if [[ -d "$repo" ]]; then
    repo_present=true
    if [[ -d "$repo/.flywheel/reports" ]]; then
      reports_dir=true
      local f
      f=$(ls -t "$repo/.flywheel/reports/"daily-*.md 2>/dev/null | head -1)
      if [[ -n "$f" && -f "$f" ]]; then
        newest_report=$(basename "$f")
        newest_iso=$(mtime_iso "$f")
        local ep
        ep=$(mtime_epoch "$f")
        if [[ -n "$ep" ]]; then
          newest_age=$(( (now_epoch - ep) / 3600 ))
          if (( newest_age <= FRESHNESS_HOURS )); then
            report_status="fresh"
          else
            report_status="stale"
          fi
        fi
      fi
    fi
  fi

  jq -nc \
    --arg kind "$kind" \
    --arg slug "$slug" \
    --argjson present "$repo_present" \
    --argjson reports_dir "$reports_dir" \
    --arg newest_report "$newest_report" \
    --arg newest_iso "$newest_iso" \
    --argjson newest_age "$newest_age" \
    --arg report_status "$report_status" \
    '{
      kind: $kind,
      slug: $slug,
      repo_present: $present,
      reports_dir_present: $reports_dir,
      newest_report: (if $newest_report == "" then null else $newest_report end),
      newest_report_mtime: (if $newest_iso == "" then null else $newest_iso end),
      newest_report_age_hours: $newest_age,
      report_status: $report_status
    }'
}

run_pass() {
  local mode_label="$1"
  local now_epoch
  now_epoch=$(date -u +%s)

  local clients_json='[]' products_json='[]'
  for s in "${CLIENT_SLUGS[@]}"; do
    clients_json=$(jq -c \
      --argjson row "$(probe_repo client "$s" "$now_epoch")" \
      '. + [$row]' <<<"$clients_json")
  done
  for s in "${PRODUCT_SLUGS[@]}"; do
    products_json=$(jq -c \
      --argjson row "$(probe_repo product "$s" "$now_epoch")" \
      '. + [$row]' <<<"$products_json")
  done

  # Aggregate
  local total
  total=$(jq -s 'add | length' <<<"[$clients_json][$products_json]" 2>/dev/null || echo 0)
  total=$(( ${#CLIENT_SLUGS[@]} + ${#PRODUCT_SLUGS[@]} ))

  local repos_present reports_dir_present fresh stale missing
  repos_present=$(jq -s '[.[][] | select(.repo_present)] | length' <<<"$clients_json"$'\n'"$products_json")
  reports_dir_present=$(jq -s '[.[][] | select(.reports_dir_present)] | length' <<<"$clients_json"$'\n'"$products_json")
  fresh=$(jq -s '[.[][] | select(.report_status=="fresh")] | length' <<<"$clients_json"$'\n'"$products_json")
  stale=$(jq -s '[.[][] | select(.report_status=="stale")] | length' <<<"$clients_json"$'\n'"$products_json")
  missing=$(jq -s '[.[][] | select(.report_status=="missing")] | length' <<<"$clients_json"$'\n'"$products_json")

  local coverage='0'
  if (( total > 0 )); then
    coverage=$(python3 -c "print(round($fresh / $total, 4))" 2>/dev/null || echo "0")
  fi

  local row
  row=$(jq -nc \
    --arg ts "$(now_iso)" \
    --arg dev_root "$DEV_ROOT" \
    --argjson client_count "${#CLIENT_SLUGS[@]}" \
    --argjson product_count "${#PRODUCT_SLUGS[@]}" \
    --argjson repos_total "$total" \
    --argjson repos_present "$repos_present" \
    --argjson reports_dir_present "$reports_dir_present" \
    --argjson fresh "$fresh" \
    --argjson stale "$stale" \
    --argjson missing "$missing" \
    --arg coverage "$coverage" \
    --argjson clients "$clients_json" \
    --argjson products "$products_json" \
    '{
      schema_version: "customer-facing-observability/v1",
      ts: $ts,
      dev_root: $dev_root,
      client_count: $client_count,
      product_count: $product_count,
      repos_total: $repos_total,
      repos_present_count: $repos_present,
      reports_dir_present_count: $reports_dir_present,
      fresh_report_count: $fresh,
      stale_report_count: $stale,
      missing_report_count: $missing,
      coverage_ratio: ($coverage | tonumber? // 0),
      customer_observability_state: "no_aggregation_pipeline_yet",
      no_aggregation_reason: "Per-repo .flywheel/reports/daily-*.md exists for some products (mobile-eats), but no flywheel-side surface aggregates per-client value+risk into a single customer receipt. Smallest recurring proxy is presence + freshness inventory until an aggregation pipeline lands.",
      clients: $clients,
      products: $products
    }')

  if [[ "$mode_label" == "apply" ]]; then
    mkdir -p "$(dirname "$LEDGER")" 2>/dev/null
    printf '%s\n' "$row" >> "$LEDGER" 2>/dev/null
  fi

  emit "$(printf '%s' "$row" | jq -c --arg mode "$mode_label" --arg ledger "$LEDGER" '{mode:$mode, ledger:$ledger} + .')"
  return 0
}

case "$MODE" in
  info)   emit "$(info_payload)"; exit 0 ;;
  schema) emit "$(schema_payload)"; exit 0 ;;
  doctor)
    payload="$(doctor_payload)"
    emit "$payload"
    [[ "$(printf '%s' "$payload" | jq -r .status)" == "ok" ]] && exit 0 || exit 1
    ;;
esac

if [[ $DRY_RUN -eq 1 ]]; then
  run_pass dry-run
  exit $?
fi
run_pass apply
exit $?
