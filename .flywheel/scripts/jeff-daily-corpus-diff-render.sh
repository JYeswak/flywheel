#!/usr/bin/env bash
# .flywheel/scripts/jeff-daily-corpus-diff-render.sh
# Render a daily activity snapshot (jeff-daily-diff-collector.v1) as a
# Joshua-readable markdown report — <2-min skim target.
#
# Bead: flywheel-ys7em
# Spec:  .flywheel/audit/jeff-daily-corpus-diff/apply-spec.md (AG3)
#
# Usage:
#   jeff-daily-corpus-diff-render.sh --info
#   jeff-daily-corpus-diff-render.sh doctor|--doctor
#   jeff-daily-corpus-diff-render.sh --apply --in <snapshot.json> [--out <report.md>]
set -euo pipefail

VERSION="0.1.0"
SCHEMA_VERSION="jeff-daily-diff-render.v1"
QUIET_DAY_THRESHOLD="${JEFF_DIFF_QUIET_THRESHOLD:-5}"

mode="apply"
in_path=""
out_path=""

usage() {
  cat <<EOF
jeff-daily-corpus-diff-render.sh — render daily activity snapshot as markdown

Schema:  $SCHEMA_VERSION
Version: $VERSION

Modes (canonical-cli-scoping triad):
  --info            print this help and exit 0
  --schema          print emit schema and exit 0
  --examples        print invocation examples and exit 0
  doctor|--doctor   emit read-only prerequisite/output-path doctor JSON
  --apply           render a snapshot to markdown

Options:
  --in=<path>       input snapshot json (REQUIRED for --apply)
  --out=<path>      output markdown path (default:
                      .flywheel/reports/jeff-corpus-diff-<UTC-date>.md)
  --version         print version and exit 0

Exit codes:
  0 success; 1 internal error; 2 bad argument or missing input

Sections rendered (AG3):
  - Headline (one-liner)
  - Releases (high signal)
  - Active repos (3+ commits today)
  - New issues (across all repos, truncated)
  - Quiet day marker if total events < $QUIET_DAY_THRESHOLD
EOF
}

examples() {
  cat <<'EOF'
# Read-only doctor:
jeff-daily-corpus-diff-render.sh doctor

# Default daily render (today's snapshot from canonical state dir):
SNAP=.flywheel/state/jeff-corpus-activity-$(date -u +%Y-%m-%d).json
jeff-daily-corpus-diff-render.sh --apply --in="$SNAP"

# Custom output path:
jeff-daily-corpus-diff-render.sh --apply --in="$SNAP" --out=/tmp/preview.md
EOF
}

doctor_json() {
  local jq_status output_status input_status overall out_parent
  overall="pass"
  if command -v jq >/dev/null; then
    jq_status="pass"
  else
    jq_status="fail"
    overall="fail"
  fi
  if [[ -n "$in_path" ]]; then
    if [[ -f "$in_path" ]]; then
      input_status="pass"
    else
      input_status="fail"
      overall="fail"
    fi
  else
    input_status="warn"
    [[ "$overall" == "fail" ]] || overall="warn"
  fi
  if [[ -n "$out_path" ]]; then
    out_parent="$(dirname "$out_path")"
  else
    out_parent="/Users/josh/Developer/flywheel/.flywheel/reports"
  fi
  if [[ -d "$out_parent" && -w "$out_parent" ]]; then
    output_status="pass"
  else
    output_status="warn"
    [[ "$overall" == "fail" ]] || overall="warn"
  fi
  jq -nc \
    --arg status "$overall" \
    --arg version "$VERSION" \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg input_path "$in_path" \
    --arg output_parent "$out_parent" \
    --arg jq_status "$jq_status" \
    --arg input_status "$input_status" \
    --arg output_status "$output_status" \
    '{
      schema_version: "jeff-daily-diff-render.doctor.v1",
      command: "doctor",
      status: $status,
      mode: "read_only",
      mutates: false,
      version: $version,
      render_schema_version: $schema_version,
      input_path: $input_path,
      output_parent: $output_parent,
      checks: [
        {name:"jq_available", status:$jq_status},
        {name:"input_snapshot_readable", status:$input_status},
        {name:"output_parent_writable", status:$output_status}
      ]
    }'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --info|-h|--help) usage; exit 0 ;;
    --schema)         printf '{"schema_version":"%s","output":"markdown","sections":["headline","releases","active_repos","new_issues","quiet_day_marker"]}\n' "$SCHEMA_VERSION"; exit 0 ;;
    --examples)       examples; exit 0 ;;
    --version)        printf '%s\n' "$VERSION"; exit 0 ;;
    --apply)          mode="apply" ;;
    --in=*)           in_path="${1#--in=}" ;;
    --out=*)          out_path="${1#--out=}" ;;
    doctor|--doctor)  doctor_json; exit 0 ;;
    *) printf 'unknown flag: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

[[ "$mode" == "apply" ]] || { printf 'unknown mode: %s\n' "$mode" >&2; exit 2; }
[[ -n "$in_path" && -f "$in_path" ]] || { printf 'missing or nonexistent --in path: %s\n' "$in_path" >&2; exit 2; }
command -v jq >/dev/null || { printf 'missing jq\n' >&2; exit 2; }

if [[ -z "$out_path" ]]; then
  ymd_from_input="$(jq -r '.ts_completed[:10] // empty' "$in_path")"
  [[ -z "$ymd_from_input" ]] && ymd_from_input="$(date -u +%Y-%m-%d)"
  out_path="/Users/josh/Developer/flywheel/.flywheel/reports/jeff-corpus-diff-$ymd_from_input.md"
fi
mkdir -p "$(dirname "$out_path")"

ts_completed="$(jq -r '.ts_completed // ""' "$in_path")"
since="$(jq -r '.since // ""' "$in_path")"
repo_count="$(jq -r '.repo_count // 0' "$in_path")"
total_commits="$(jq -r '.total_commits // 0' "$in_path")"
total_issues="$(jq -r '.total_issues // 0' "$in_path")"
total_releases="$(jq -r '.total_releases // 0' "$in_path")"
total_prs="$(jq -r '.total_prs // 0' "$in_path")"

# Active repos (3+ commits)
active_repos="$(jq -r '.repos | map(select((.commits|length) >= 3)) | sort_by(-(.commits|length))' "$in_path")"
active_count="$(printf '%s' "$active_repos" | jq 'length')"
total_events=$((total_commits + total_issues + total_releases + total_prs))

{
  printf '# Jeffrey Emanuel corpus — daily diff for %s\n\n' "${ts_completed:0:10}"
  printf '_Window: since %s · %s repos polled · rendered %s_\n\n' "$since" "$repo_count" "$ts_completed"

  # Headline
  printf '## Headline\n\n'
  printf 'Jeffrey shipped **%s commits across %s repos**, **%s new releases**, **%s PRs merged**, **%s issues touched** in the last 24h.\n\n' \
    "$total_commits" "$active_count" "$total_releases" "$total_prs" "$total_issues"

  # Quiet day marker
  if [[ "$total_events" -lt "$QUIET_DAY_THRESHOLD" ]]; then
    printf '> **Quiet day** — total activity (%s events) below threshold (%s). Skim and close.\n\n' "$total_events" "$QUIET_DAY_THRESHOLD"
  fi

  # Releases section (high signal)
  printf '## Releases (high signal)\n\n'
  releases_md="$(jq -r '
    .repos
    | map(select((.releases|length) > 0))
    | map(.repo as $r | .releases | map(. + {repo: $r}))
    | flatten
    | sort_by(.ts) | reverse
    | if length == 0 then "_no new releases in window_" else
        map("- **\(.repo)** [`\(.tag)`](\(.url)) — \(.name // .tag) · \(.ts)")
        | join("\n")
      end' "$in_path" 2>/dev/null || echo "_no new releases in window_")"
  printf '%s\n\n' "$releases_md"

  # Active repos
  printf '## Active repos (3+ commits today)\n\n'
  if [[ "$active_count" -eq 0 ]]; then
    printf '_no repos hit the 3-commit threshold today_\n\n'
  else
    printf '%s' "$active_repos" | jq -r '
      .[] | "### " + .repo + " (" + ((.commits|length)|tostring) + " commits)\n\n" +
            (.commits[0:5] | map("- `" + .sha + "` " + .message + " · _" + .author + "_") | join("\n")) +
            (if (.commits|length) > 5 then "\n- _… and " + (((.commits|length) - 5)|tostring) + " more_" else "" end) +
            "\n"'
    printf '\n'
  fi

  # New issues (truncated)
  printf '## New issues (touched in window)\n\n'
  issues_md="$(jq -r '
    .repos
    | map(.repo as $r | .issues | map(. + {repo: $r}))
    | flatten
    | sort_by(.ts) | reverse
    | if length == 0 then "_no issues touched in window_" else
        .[0:15] as $top
        | ($top | map("- **\(.repo)** #\(.number) [\(.title)](\(.url)) · _\(.state) · \(.ts)_") | join("\n")) +
          (if length > 15 then "\n- _… and " + ((length - 15)|tostring) + " more_" else "" end)
      end' "$in_path" 2>/dev/null || echo "_no issues touched in window_")"
  printf '%s\n\n' "$issues_md"

  # PRs merged (inline tail)
  if [[ "$total_prs" -gt 0 ]]; then
    printf '## PRs merged\n\n'
    jq -r '
      .repos
      | map(.repo as $r | .prs | map(. + {repo: $r}))
      | flatten
      | sort_by(.ts) | reverse
      | map("- **\(.repo)** #\(.number) [\(.title)](\(.url)) · _\(.ts)_")
      | join("\n")' "$in_path"
    printf '\n\n'
  fi

  printf -- "---\n_Generated by \`.flywheel/scripts/jeff-daily-corpus-diff-render.sh\` v%s · schema \`%s\` · source \`%s\`_\n" \
    "$VERSION" "$SCHEMA_VERSION" "$in_path"
} > "$out_path"

printf 'rendered=%s bytes=%s\n' "$out_path" "$(/usr/bin/stat -f %z "$out_path")"
