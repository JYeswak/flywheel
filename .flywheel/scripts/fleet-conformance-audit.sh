#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
FRAMEWORK="$ROOT/.flywheel/scripts/mp-validator-framework.sh"
DEFAULT_INVENTORY="$ROOT/.flywheel/inventory/2026-05-19-rebuild/inventory-rebuild.jsonl"
SCHEMA_VERSION="fleet-conformance-audit/v1"

inventory="$DEFAULT_INVENTORY"
out_dir=""
date_stamp="$(date -u +%F)"
tier_regex='^T[12]'
limit=0
json=0

usage() {
  cat <<'EOF'
usage: .flywheel/scripts/fleet-conformance-audit.sh [--json] [--inventory PATH] [--output-dir DIR] [--date YYYY-MM-DD] [--limit N]

Read-only audit over inventory T1+T2 rows by default. Produces SCORECARD.md plus JSONL rows.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json=1; shift ;;
    --inventory) inventory="$2"; shift 2 ;;
    --output-dir) out_dir="$2"; shift 2 ;;
    --date) date_stamp="$2"; shift 2 ;;
    --limit) limit="$2"; shift 2 ;;
    --tier-regex) tier_regex="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

[[ -r "$inventory" ]] || { printf 'inventory not readable: %s\n' "$inventory" >&2; exit 2; }
[[ -x "$FRAMEWORK" ]] || { printf 'framework not executable: %s\n' "$FRAMEWORK" >&2; exit 2; }

out_dir="${out_dir:-$ROOT/.flywheel/audits/fleet-conformance-$date_stamp}"
mkdir -p "$out_dir"
rows_jsonl="$out_dir/results.jsonl"
targets_jsonl="$out_dir/targets.jsonl"
: >"$rows_jsonl"
: >"$targets_jsonl"

count=0
while IFS= read -r row; do
    [[ -n "$row" ]] || continue
    if [[ "$limit" -gt 0 && "$count" -ge "$limit" ]]; then
      break
    fi
    repo_path="$(jq -r '.repo_path' <<<"$row")"
    rel_path="$(jq -r '.path' <<<"$row")"
    target="$repo_path/$rel_path"
    [[ -e "$target" ]] || continue
    printf '%s\n' "$row" >>"$targets_jsonl"
    set +e
    score="$("$FRAMEWORK" --json all "$target")"
    rc=$?
    set -e
    if [[ "$rc" -gt 2 ]] || ! jq -e . >/dev/null 2>&1 <<<"$score"; then
      score="$(jq -nc --arg target "$target" '{rows:[{mp_id:"framework",status:"FAIL",reason:"framework failed",target:$target}]}')"
    fi
    jq -c --argjson surface "$row" '
      .rows[]
      | .repo = $surface.repo
      | .repo_path = $surface.repo_path
      | .path = $surface.path
      | .tier = $surface.tier
      | .class = $surface.class
      | .language = $surface.language
    ' <<<"$score" >>"$rows_jsonl"
    count=$((count + 1))
done < <(
  jq -c --arg re "$tier_regex" '
    select((.tier // "") | test($re))
    | select((.missing_repo // false) == false)
    | {repo,repo_path,path,tier,class,language,canonical_cli_present,invoke_count_30d}
  ' "$inventory"
)

summary_json="$out_dir/summary.json"
jq -s --arg sv "$SCHEMA_VERSION" --arg generated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg inventory "$inventory" '
  def c($s): map(select(.status == $s)) | length;
  . as $rows
  | ($rows | c("PASS")) as $pass
  | ($rows | c("FAIL")) as $fail
  | ($rows | c("SKIP")) as $skip
  | ($pass + $fail) as $applicable
  | {
      schema_version:$sv,
      generated_at:$generated_at,
      inventory:$inventory,
      surface_count:($rows | map(.repo + ":" + .path) | unique | length),
      validator_count:($rows | map(.mp_id) | unique | length),
      totals:{pass:$pass,fail:$fail,skip:$skip,applicable:$applicable,total:($rows|length)},
      skill_quality_bar_coverage_ratio:(if $applicable == 0 then 0 else (($pass / $applicable) * 10000 | round / 10000) end),
      per_mp:(
        $rows
        | group_by(.mp_id)
        | map({
            mp_id:.[0].mp_id,
            pass:(c("PASS")),
            fail:(c("FAIL")),
            skip:(c("SKIP")),
            applicable:((c("PASS")) + (c("FAIL"))),
            coverage_ratio:(if ((c("PASS")) + (c("FAIL"))) == 0 then null else (((c("PASS")) / ((c("PASS")) + (c("FAIL")))) * 10000 | round / 10000) end)
          })
      ),
      failing_samples:($rows | map(select(.status=="FAIL")) | .[:20])
    }
' "$rows_jsonl" >"$summary_json"

scorecard="$out_dir/SCORECARD.md"
{
  printf '# Fleet Conformance Scorecard — %s\n\n' "$date_stamp"
  printf '%s\n' "- Schema: \`$SCHEMA_VERSION\`"
  printf '%s\n' "- Inventory: \`$inventory\`"
  jq -r '"- Surfaces audited: \(.surface_count)\n- Validators: \(.validator_count)\n- skill_quality_bar_coverage_ratio: \(.skill_quality_bar_coverage_ratio)\n- PASS/FAIL/SKIP: \(.totals.pass)/\(.totals.fail)/\(.totals.skip)\n- Applicable checks: \(.totals.applicable)"' "$summary_json"
  printf '\n## Per MP\n\n| MP | PASS | FAIL | SKIP | Applicable | Coverage |\n|---|---:|---:|---:|---:|---:|\n'
  jq -r '.per_mp[] | "| \(.mp_id) | \(.pass) | \(.fail) | \(.skip) | \(.applicable) | \(.coverage_ratio // "n/a") |"' "$summary_json"
  printf '\n## Failing Samples\n\n'
  jq -r '.failing_samples[]? | "- \(.mp_id) \(.repo):`\(.path)` — \(.reason)"' "$summary_json"
} >"$scorecard"

if [[ "$json" -eq 1 ]]; then
  jq --arg scorecard "$scorecard" --arg rows "$rows_jsonl" '. + {scorecard:$scorecard, rows_jsonl:$rows}' "$summary_json"
else
  printf 'Wrote %s\n' "$scorecard"
  jq -r '"skill_quality_bar_coverage_ratio=\(.skill_quality_bar_coverage_ratio)"' "$summary_json"
fi
