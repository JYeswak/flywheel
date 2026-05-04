#!/usr/bin/env bash
set -euo pipefail

SCRIPT_VERSION="2026-05-03.2"
SCHEMA_VERSION="flywheel.vc_observability_probe.v2"
DEFAULT_TIMEOUT_SECONDS=10
TIMEOUT_SECONDS="${VC_OBSERVABILITY_TIMEOUT_SECONDS:-$DEFAULT_TIMEOUT_SECONDS}"
VC_DB_PATH="${VC_OBSERVABILITY_DB_PATH:-$HOME/Library/Application Support/vc/vc.duckdb}"
VC_BIN=""
RESOLVE_REASON=""

usage() {
  cat <<'EOF'
Usage: vc-observability-probe.sh [--json] [--doctor|--health|--info|--schema|--examples]

Modes:
  --json      Emit vc observability snapshot JSON (default)
  --doctor    Emit doctor-oriented JSON check
  --health    Emit health-oriented JSON check
  --info      Emit probe/runtime info JSON
  --schema    Emit output schema JSON
  --examples  Print command examples
EOF
}

json_string_file() {
  LC_ALL=C head -c 2000 "$1" | jq -Rs .
}

timeout_bin() {
  if command -v gtimeout >/dev/null 2>&1; then
    command -v gtimeout
  elif command -v timeout >/dev/null 2>&1; then
    command -v timeout
  elif [ -x /opt/homebrew/bin/timeout ]; then
    printf '%s\n' /opt/homebrew/bin/timeout
  else
    printf '%s\n' ""
  fi
}

run_command() {
  local out_file="$1"
  local err_file="$2"
  shift 2

  local timeout_cmd
  timeout_cmd="$(timeout_bin)"

  set +e
  if [ -n "$timeout_cmd" ]; then
    "$timeout_cmd" "$TIMEOUT_SECONDS" "$@" >"$out_file" 2>"$err_file"
  else
    "$@" >"$out_file" 2>"$err_file"
  fi
  local status=$?
  set -e
  return "$status"
}

strip_vc_logs() {
  sed -E '/^[0-9]{4}-[0-9]{2}-[0-9]{2}T.* (INFO|WARN|ERROR) /d' "$1"
}

is_vibe_vc() {
  local candidate="$1"
  local help_text

  if [ ! -x "$candidate" ]; then
    return 1
  fi

  set +e
  help_text="$("$candidate" --help 2>&1 | head -20)"
  local status=$?
  set -e

  if [ "$status" -ne 0 ]; then
    return 1
  fi

  printf '%s\n' "$help_text" | grep -q 'Vibe Cockpit'
}

classify_vc() {
  local candidate="$1"
  local help_text

  if [ -z "$candidate" ]; then
    printf '%s\n' "missing"
    return 0
  fi
  if [ ! -x "$candidate" ]; then
    printf '%s\n' "not_executable"
    return 0
  fi
  if is_vibe_vc "$candidate"; then
    printf '%s\n' "vibe_cockpit"
    return 0
  fi

  set +e
  help_text="$("$candidate" --help 2>&1 | head -20)"
  set -e
  if printf '%s\n' "$help_text" | grep -qi 'Vercel'; then
    printf '%s\n' "vercel"
  else
    printf '%s\n' "other"
  fi
}

resolve_vc_bin() {
  local path_vc
  path_vc="$(command -v vc 2>/dev/null || true)"

  local candidates=""
  if [ -n "${VC_OBSERVABILITY_VC_BIN:-}" ]; then
    candidates="${VC_OBSERVABILITY_VC_BIN}"
  else
    candidates="/Users/josh/.local/bin/vc
/Users/josh/.cargo/bin/vc"
    if [ -n "$path_vc" ]; then
      candidates="${candidates}
${path_vc}"
    fi
  fi

  local candidate
  while IFS= read -r candidate; do
    [ -n "$candidate" ] || continue
    if is_vibe_vc "$candidate"; then
      VC_BIN="$candidate"
      RESOLVE_REASON="canonical_vibe_cockpit_cli"
      return 0
    fi
  done <<EOF
$candidates
EOF

  VC_BIN=""
  if [ -n "${VC_OBSERVABILITY_VC_BIN:-}" ]; then
    RESOLVE_REASON="configured_vc_bin_not_vibe_cockpit"
  elif [ -n "$path_vc" ]; then
    RESOLVE_REASON="path_vc_is_$(classify_vc "$path_vc")"
  else
    RESOLVE_REASON="vc_not_found"
  fi
  return 1
}

vc_version() {
  local out_file="$TMP_ROOT/vc-version.out"
  local err_file="$TMP_ROOT/vc-version.err"
  local clean_file="$TMP_ROOT/vc-version.clean"

  if [ -z "$VC_BIN" ]; then
    printf '%s\n' ""
    return 0
  fi

  set +e
  run_command "$out_file" "$err_file" "$VC_BIN" --version
  set -e
  strip_vc_logs "$out_file" >"$clean_file"
  sed -n '/./p' "$clean_file" | head -1
}

run_vc_json() {
  local surface="$1"
  shift

  local out_file="$TMP_ROOT/${surface}.out"
  local err_file="$TMP_ROOT/${surface}.err"
  local clean_file="$TMP_ROOT/${surface}.json"

  set +e
  run_command "$out_file" "$err_file" "$VC_BIN" "$@"
  local exit_code=$?
  set -e

  strip_vc_logs "$out_file" >"$clean_file"

  local stderr_json
  local output_json
  stderr_json="$(json_string_file "$err_file")"
  output_json="$(json_string_file "$clean_file")"

  if [ -s "$clean_file" ] && jq -e . "$clean_file" >/dev/null 2>&1 && [ "$exit_code" -eq 0 ]; then
    jq -n \
      --arg surface "$surface" \
      --argjson exit_code "$exit_code" \
      --slurpfile payload "$clean_file" \
      --argjson stderr_snippet "$stderr_json" \
      '{
        surface: $surface,
        ok: true,
        exit_code: $exit_code,
        payload: $payload[0],
        stderr_snippet: $stderr_snippet
      }'
  else
    jq -n \
      --arg surface "$surface" \
      --argjson exit_code "$exit_code" \
      --argjson output_snippet "$output_json" \
      --argjson stderr_snippet "$stderr_json" \
      '{
        surface: $surface,
        ok: false,
        exit_code: $exit_code,
        output_snippet: $output_snippet,
        stderr_snippet: $stderr_snippet
      }'
  fi
}

run_sql_json() {
  local surface="$1"
  local sql="$2"
  local out_file="$TMP_ROOT/${surface}.out"
  local err_file="$TMP_ROOT/${surface}.err"
  local clean_file="$TMP_ROOT/${surface}.json"
  local duckdb_bin

  duckdb_bin="$(command -v duckdb 2>/dev/null || true)"

  set +e
  if [ -n "$duckdb_bin" ] && [ -f "$VC_DB_PATH" ]; then
    run_command "$out_file" "$err_file" "$duckdb_bin" -readonly "$VC_DB_PATH" -json -c "$sql"
  else
    run_command "$out_file" "$err_file" "$VC_BIN" query raw "$sql" --format json
  fi
  local exit_code=$?
  set -e

  strip_vc_logs "$out_file" >"$clean_file"

  local stderr_json
  local output_json
  stderr_json="$(json_string_file "$err_file")"
  output_json="$(json_string_file "$clean_file")"

  if [ -s "$clean_file" ] && jq -e . "$clean_file" >/dev/null 2>&1 && [ "$exit_code" -eq 0 ]; then
    jq -n \
      --arg surface "$surface" \
      --argjson exit_code "$exit_code" \
      --slurpfile payload "$clean_file" \
      --argjson stderr_snippet "$stderr_json" \
      '{
        surface: $surface,
        ok: true,
        exit_code: $exit_code,
        payload: $payload[0],
        stderr_snippet: $stderr_snippet
      }'
  else
    jq -n \
      --arg surface "$surface" \
      --argjson exit_code "$exit_code" \
      --argjson output_snippet "$output_json" \
      --argjson stderr_snippet "$stderr_json" \
      '{
        surface: $surface,
        ok: false,
        exit_code: $exit_code,
        output_snippet: $output_snippet,
        stderr_snippet: $stderr_snippet
      }'
  fi
}

compute_vc_metrics() {
  local collector_json="$1"
  local repos_json="$2"
  local repo_status_json="$3"
  local gh_json="$4"

  jq -n \
    --argjson collector "$collector_json" \
    --argjson repos "$repos_json" \
    --argjson repo_status "$repo_status_json" \
    --argjson gh "$gh_json" \
    '
    def rows($s):
      if ($s.ok == true and ($s.payload | type) == "array") then $s.payload else [] end;
    def text_blob:
      (((rows($repos) | map([.path, .url, .name] | map(. // "") | join(" ")))
        + (rows($repo_status) | map((.raw_json | fromjson? | [.path, .repo] | map(. // "") | join(" "))))
        + (rows($gh) | map((.raw_json | fromjson? | .repo_dir // ""))))
        | join("\n") | ascii_downcase);
    def visible($patterns):
      any($patterns[]; . as $pattern | text_blob | contains($pattern));
    (rows($collector)
      | sort_by((.collector // ""), (.collected_at // ""))
      | group_by(.collector // "")
      | map(max_by(.collected_at // ""))) as $latest_collectors
    | [
        {key: "flywheel", patterns: ["flywheel"]},
        {key: "mobile-eats", patterns: ["mobile-eats"]},
        {key: "skillos", patterns: ["skillos"]},
        {key: "alps/alpsinsurance", patterns: ["alps", "alpsinsurance"]},
        {key: "terra-title", patterns: ["terra-title", "terratitle"]},
        {key: "zesttube", patterns: ["zesttube"]},
        {key: "zeststream-infra", patterns: ["zeststream-infra"]}
      ] as $fleet
    | ($latest_collectors | map(select((.success | tostring) == "true")) | length) as $collector_successes
    | ($fleet | map(select(visible(.patterns))) | map(.key)) as $visible_repos
    | {
        vc_collector_health: (($collector_successes | tostring) + "/16"),
        vc_collectors_succeeding: $collector_successes,
        vc_collectors_observed: ($latest_collectors | length),
        vc_collector_failures: ($latest_collectors | map(select((.success | tostring) != "true")) | map({collector, error_class})),
        vc_repo_coverage: (($visible_repos | length | tostring) + "/8"),
        vc_repo_coverage_count: ($visible_repos | length),
        vc_repos_visible: $visible_repos,
        vc_repos_missing: ($fleet | map(.key) - $visible_repos),
        vc_ledger_growth_per_cycle: (($latest_collectors | map(.rows_inserted // 0) | add) // 0)
      }'
}

emit_unavailable() {
  local mode="$1"
  local path_vc
  path_vc="$(command -v vc 2>/dev/null || true)"

  jq -n \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg checked_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --arg mode "$mode" \
    --arg version "$SCRIPT_VERSION" \
    --arg reason "$RESOLVE_REASON" \
    --arg path_vc "$path_vc" \
    --arg path_vc_kind "$(classify_vc "$path_vc")" \
    '{
      schema_version: $schema_version,
      checked_at: $checked_at,
      mode: $mode,
      probe_version: $version,
      success: false,
      vc_status: "unavailable",
      vc_alerts_count: 0,
      vc_digest_summary: ("vc unavailable: " + $reason),
      vc_version: null,
      vc_bin: null,
      reason: $reason,
      canonical_scope: {
        path_vc: $path_vc,
        path_vc_kind: $path_vc_kind,
        preferred_bins: ["/Users/josh/.local/bin/vc", "/Users/josh/.cargo/bin/vc"],
        env_override: env.VC_OBSERVABILITY_VC_BIN
      },
      warnings: ["vc observability unavailable; tick should warn and continue"],
      surfaces: {}
    }'
}

emit_snapshot() {
  local mode="$1"

  if ! resolve_vc_bin; then
    emit_unavailable "$mode"
    return 0
  fi

  local status_json
  local health_json
  local report_json
  local alert_json
  local collector_health_json
  local repos_json
  local repo_status_json
  local gh_repo_json
  local metrics_json
  local version_text
  local path_vc

  status_json="$(run_vc_json robot_status robot --format json status)"
  health_json="$(run_vc_json robot_health robot --format json health)"
  report_json="$(run_vc_json report report --output json)"
  alert_json="$(run_vc_json alert_list alert --format json list)"
  collector_health_json="$(run_sql_json collector_health "SELECT collector, success, rows_inserted, error_class, collected_at FROM collector_health ORDER BY collected_at DESC LIMIT 80;")"
  repos_json="$(run_sql_json repos "SELECT path, url, name FROM repos;")"
  repo_status_json="$(run_sql_json repo_status_snapshots "SELECT repo_id, raw_json FROM repo_status_snapshots ORDER BY collected_at DESC LIMIT 400;")"
  gh_repo_json="$(run_sql_json gh_repo_issue_pr_snapshot "SELECT repo_id, raw_json FROM gh_repo_issue_pr_snapshot ORDER BY collected_at DESC LIMIT 400;")"
  metrics_json="$(compute_vc_metrics "$collector_health_json" "$repos_json" "$repo_status_json" "$gh_repo_json")"
  version_text="$(vc_version)"
  path_vc="$(command -v vc 2>/dev/null || true)"

  jq -n \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg checked_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --arg mode "$mode" \
    --arg version "$SCRIPT_VERSION" \
    --arg vc_bin "$VC_BIN" \
    --arg vc_version "$version_text" \
    --arg resolve_reason "$RESOLVE_REASON" \
    --arg path_vc "$path_vc" \
    --arg path_vc_kind "$(classify_vc "$path_vc")" \
    --argjson status "$status_json" \
    --argjson health "$health_json" \
    --argjson report "$report_json" \
    --argjson alert "$alert_json" \
    --argjson collector_health "$collector_health_json" \
    --argjson repos "$repos_json" \
    --argjson repo_status "$repo_status_json" \
    --argjson gh_repo "$gh_repo_json" \
    --argjson metrics "$metrics_json" \
    '
    def robot_alerts:
      if ($status.ok == true) then
        (($status.payload.data.alerts.critical // 0)
        + ($status.payload.data.alerts.high // 0)
        + ($status.payload.data.alerts.medium // 0)
        + ($status.payload.data.alerts.low // 0))
      else null end;
    def health_alerts:
      if ($health.ok == true) then ($health.payload.data.overall.active_alerts // null) else null end;
    def report_alerts:
      if ($report.ok == true) then ($report.payload.summary.open_alerts // null) else null end;
    def alerts_count: (robot_alerts // health_alerts // report_alerts // 0);
    def status_warnings:
      if ($status.ok == true) then ($status.payload.data.warnings // []) else ["vc robot status unavailable"] end;
    def health_warnings:
      if ($health.ok == true) then ($health.payload.data.warnings // []) else ["vc robot health unavailable"] end;
    def report_warnings:
      if ($report.ok == true) then [] else ["vc report unavailable"] end;
    def alert_warnings:
      if ($alert.ok == true) then [] else ["vc alert list unavailable or not implemented"] end;
    def metric_warnings:
      ([if ($metrics.vc_collectors_observed // 0) == 0 then "vc collector_health unavailable" else empty end]
      + [if ($metrics.vc_collectors_observed // 0) < 16 then "vc collector denominator below expected 16" else empty end]
      + [if ($metrics.vc_repo_coverage_count // 0) < 3 then "vc fleet repo coverage below acceptance gate" else empty end]);
    def warnings: ((status_warnings + health_warnings + report_warnings + alert_warnings + metric_warnings) | unique);
    def notable:
      if ($report.ok == true) then
        (($report.payload.sections[]? | select(.title == "Notable Events") | .items[0]?) // "no notable events")
      else empty end;
    def digest:
      if ($report.ok == true) then
        ("open_alerts=" + ((report_alerts // 0) | tostring) + "; " + (notable | tostring))
      elif ($status.ok == true) then
        ("fleet_online=" + (($status.payload.data.fleet.online_machines // 0) | tostring)
        + "/" + (($status.payload.data.fleet.total_machines // 0) | tostring)
        + "; health_score=" + (($status.payload.data.fleet.health_score // "unknown") | tostring))
      elif ($health.ok == true) then
        ("health_score=" + (($health.payload.data.overall.score // "unknown") | tostring)
        + "; severity=" + (($health.payload.data.overall.severity // "unknown") | tostring))
      else
        "vc digest unavailable"
      end;
    def computed_status:
      if (($status.ok != true) and ($health.ok != true)) then "unavailable"
      elif ((warnings | length) > 0) then "degraded"
      else "ok" end;
    {
      schema_version: $schema_version,
      checked_at: $checked_at,
      mode: $mode,
      probe_version: $version,
      success: (computed_status != "unavailable"),
      vc_status: computed_status,
      vc_alerts_count: alerts_count,
      vc_digest_summary: digest,
      vc_collector_health: $metrics.vc_collector_health,
      vc_collectors_succeeding: $metrics.vc_collectors_succeeding,
      vc_collectors_observed: $metrics.vc_collectors_observed,
      vc_collector_failures: $metrics.vc_collector_failures,
      vc_repo_coverage: $metrics.vc_repo_coverage,
      vc_repo_coverage_count: $metrics.vc_repo_coverage_count,
      vc_repos_visible: $metrics.vc_repos_visible,
      vc_repos_missing: $metrics.vc_repos_missing,
      vc_ledger_growth_per_cycle: $metrics.vc_ledger_growth_per_cycle,
      vc_version: $vc_version,
      vc_bin: $vc_bin,
      reason: $resolve_reason,
      canonical_scope: {
        path_vc: $path_vc,
        path_vc_kind: $path_vc_kind,
        preferred_bins: ["/Users/josh/.local/bin/vc", "/Users/josh/.cargo/bin/vc"],
        env_override: env.VC_OBSERVABILITY_VC_BIN
      },
      warnings: warnings,
      doctor_check: {
        name: "vc_observability",
        status: (if computed_status == "ok" then "pass" elif computed_status == "degraded" then "warn" else "fail" end),
        message: (digest + "; collectors=" + ($metrics.vc_collector_health // "unknown") + "; fleet_repos=" + ($metrics.vc_repo_coverage // "unknown"))
      },
      surfaces: {
        robot_status: $status,
        robot_health: $health,
        report: $report,
        alert_list: $alert,
        collector_health: $collector_health,
        repos: $repos,
        repo_status_snapshots: $repo_status,
        gh_repo_issue_pr_snapshot: $gh_repo
      }
    }'
}

emit_info() {
  local path_vc
  local local_kind
  local cargo_kind
  local path_kind
  local resolved="false"
  local version_text=""

  path_vc="$(command -v vc 2>/dev/null || true)"
  local_kind="$(classify_vc /Users/josh/.local/bin/vc)"
  cargo_kind="$(classify_vc /Users/josh/.cargo/bin/vc)"
  path_kind="$(classify_vc "$path_vc")"
  if resolve_vc_bin; then
    resolved="true"
    version_text="$(vc_version)"
  fi

  jq -n \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg checked_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --arg version "$SCRIPT_VERSION" \
    --argjson resolved "$resolved" \
    --arg vc_bin "$VC_BIN" \
    --arg vc_version "$version_text" \
    --arg resolve_reason "$RESOLVE_REASON" \
    --arg path_vc "$path_vc" \
    --arg path_kind "$path_kind" \
    --arg local_kind "$local_kind" \
    --arg cargo_kind "$cargo_kind" \
    --arg timeout_seconds "$TIMEOUT_SECONDS" \
    '{
      schema_version: $schema_version,
      checked_at: $checked_at,
      mode: "info",
      probe_version: $version,
      success: $resolved,
      vc_bin: (if $vc_bin == "" then null else $vc_bin end),
      vc_version: (if $vc_version == "" then null else $vc_version end),
      reason: $resolve_reason,
      timeout_seconds: ($timeout_seconds | tonumber? // $timeout_seconds),
      canonical_scope: {
        path_vc: $path_vc,
        path_vc_kind: $path_kind,
        local_bin: "/Users/josh/.local/bin/vc",
        local_bin_kind: $local_kind,
        cargo_bin: "/Users/josh/.cargo/bin/vc",
        cargo_bin_kind: $cargo_kind,
        preferred_bins: ["/Users/josh/.local/bin/vc", "/Users/josh/.cargo/bin/vc"],
        env_override: env.VC_OBSERVABILITY_VC_BIN
      },
      known_good: {
        cli_identity: "Vibe Cockpit",
        schema_version: "vc.robot.status.v1",
        observed_version_prefix: "vc 0.1.0"
      }
    }'
}

emit_schema() {
  jq -n \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg version "$SCRIPT_VERSION" \
    '{
      schema_version: $schema_version,
      probe_version: $version,
      required_receipt_fields: ["vc_status", "vc_alerts_count", "vc_digest_summary"],
      optional_receipt_fields: ["vc_version", "vc_bin", "vc_observability_warnings", "vc_collector_health", "vc_repo_coverage", "vc_ledger_growth_per_cycle", "vc_collectors_succeeding", "vc_repos_visible"],
      vc_status_values: ["ok", "degraded", "unavailable"],
      metric_fields: {
        vc_collector_health: "X/16 latest collector_health successes",
        vc_repo_coverage: "N/8 target fleet repos visible in vc repo surfaces",
        vc_ledger_growth_per_cycle: "sum(rows_inserted) across latest collector_health rows"
      },
      modes: ["snapshot", "doctor", "health", "info", "schema", "examples"],
      doctor_probe: {
        name: "vc_observability",
        fail_open: true,
        degraded_or_unavailable_behavior: "warn_and_continue"
      },
      canonical_cli_scope: {
        env_override: "VC_OBSERVABILITY_VC_BIN",
        preferred_bins: ["/Users/josh/.local/bin/vc", "/Users/josh/.cargo/bin/vc"],
        reject_if_help_missing: "Vibe Cockpit"
      }
    }'
}

emit_examples() {
  cat <<'EOF'
# Default tick snapshot
.flywheel/scripts/vc-observability-probe.sh --json

# Doctor probe, fail-open JSON for flywheel tick
.flywheel/scripts/vc-observability-probe.sh --doctor --json

# Info/canonical CLI scoping audit
.flywheel/scripts/vc-observability-probe.sh --info --json

# Graceful-degrade simulation
VC_OBSERVABILITY_VC_BIN=/opt/homebrew/bin/vc .flywheel/scripts/vc-observability-probe.sh --json
VC_OBSERVABILITY_VC_BIN=/no/such/vc .flywheel/scripts/vc-observability-probe.sh --json
EOF
}

MODE="snapshot"
JSON_REQUESTED="false"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --json)
      JSON_REQUESTED="true"
      ;;
    --doctor)
      MODE="doctor"
      ;;
    --health)
      MODE="health"
      ;;
    --info)
      MODE="info"
      ;;
    --schema)
      MODE="schema"
      ;;
    --examples)
      MODE="examples"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if [ "$JSON_REQUESTED" = "false" ] && [ "$MODE" != "examples" ] && [ "$MODE" != "schema" ]; then
  JSON_REQUESTED="true"
fi

TMP_ROOT="$(mktemp -d /tmp/vc-observability-probe.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

case "$MODE" in
  snapshot)
    emit_snapshot "snapshot"
    ;;
  doctor)
    emit_snapshot "doctor"
    ;;
  health)
    emit_snapshot "health"
    ;;
  info)
    emit_info
    ;;
  schema)
    emit_schema
    ;;
  examples)
    emit_examples
    ;;
esac
