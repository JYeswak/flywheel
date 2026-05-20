#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
FRAMEWORK="$ROOT/.flywheel/scripts/mp-validator-framework.sh"
REACHABILITY_CHECK="$ROOT/.flywheel/scripts/reachability-check.sh"
DEFAULT_INVENTORY="$ROOT/.flywheel/inventory/2026-05-19-rebuild/inventory-rebuild.jsonl"
SCHEMA_VERSION="fleet-conformance-audit/v1"
VALIDATOR_IDS=(
  MP-01 MP-02 MP-03 MP-04 MP-15 MP-22 MP-26 MP-33 MP-44 MP-66
  MP-80 MP-81 MP-82 MP-83 MP-84 MP-85 MP-86 MP-87 MP-88 MP-89
  MP-90 MP-91 MP-92 MP-93 MP-94 MP-95 MP-96 MP-97 MP-98 MP-99
)

inventory="$DEFAULT_INVENTORY"
out_dir=""
date_stamp="$(date -u +%F)"
tier_regex='^T[12]'
limit=0
json=0
parallel_jobs=4

usage() {
  cat <<'EOF'
usage: .flywheel/scripts/fleet-conformance-audit.sh [--json] [--inventory PATH] [--output-dir DIR] [--date YYYY-MM-DD] [--limit N] [--jobs N]

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
    --jobs) parallel_jobs="$2"; shift 2 ;;
    --tier-regex) tier_regex="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

[[ -r "$inventory" ]] || { printf 'inventory not readable: %s\n' "$inventory" >&2; exit 2; }
[[ -x "$FRAMEWORK" ]] || { printf 'framework not executable: %s\n' "$FRAMEWORK" >&2; exit 2; }
[[ -x "$REACHABILITY_CHECK" ]] || { printf 'reachability check not executable: %s\n' "$REACHABILITY_CHECK" >&2; exit 2; }

out_dir="${out_dir:-$ROOT/.flywheel/audits/fleet-conformance-$date_stamp}"
mkdir -p "$out_dir"
rows_jsonl="$out_dir/results.jsonl"
targets_jsonl="$out_dir/targets.jsonl"
: >"$rows_jsonl"
: >"$targets_jsonl"
validator_ids_json="$(printf '%s\n' "${VALIDATOR_IDS[@]}" | jq -R . | jq -s .)"
target_rows_dir="$out_dir/.target-results-$$"
target_meta_dir="$out_dir/.target-meta-$$"
mkdir -p "$target_rows_dir"
mkdir -p "$target_meta_dir"
cleanup_target_dirs() {
  local part
  for part in "$target_rows_dir"/*.jsonl "$target_meta_dir"/*.jsonl; do
    [[ -e "$part" ]] && rm "$part"
  done
  rmdir "$target_rows_dir" "$target_meta_dir" 2>/dev/null || true
}
trap cleanup_target_dirs EXIT

audit_surface() {
    local row="$1" out_file="$2" target_file="$3"
    local repo_path rel_path target score rc reachability reachability_rc enriched_row
    repo_path="$(jq -r '.repo_path' <<<"$row")"
    rel_path="$(jq -r '.path' <<<"$row")"
    target="$repo_path/$rel_path"
    set +e
    reachability="$("$REACHABILITY_CHECK" --json --inventory "$inventory" "$target")"
    reachability_rc=$?
    set -e
    if [[ "$reachability_rc" -gt 1 ]] || ! jq -e . >/dev/null 2>&1 <<<"$reachability"; then
      reachability="$(jq -nc --arg surface "$target" '{surface:$surface,reachable:false,reason:"reachability_check_failed",invoke_count_30d:0,dispatch_log_hits:0,inbound_caller_count:0,inbound_callers:[]}')"
    fi
    enriched_row="$(jq -c --argjson reachability "$reachability" '
      .reachable = ($reachability.reachable // false)
      | .reachability_reason = ($reachability.reason // "unknown")
      | .reachability_dispatch_log_hits = ($reachability.dispatch_log_hits // 0)
      | .reachability_inbound_caller_count = ($reachability.inbound_caller_count // 0)
      | .reachability_inbound_callers = ($reachability.inbound_callers // [])
      | .invoke_count_30d = ($reachability.invoke_count_30d // .invoke_count_30d // 0)
    ' <<<"$row")"
    printf '%s\n' "$enriched_row" >"$target_file"
    set +e
    score="$("$FRAMEWORK" --json all "$target")"
    rc=$?
    set -e
    if [[ "$rc" -gt 2 ]] || ! jq -e . >/dev/null 2>&1 <<<"$score"; then
      score="$(jq -nc --arg target "$target" --argjson validator_ids "$validator_ids_json" '{rows:($validator_ids | map({mp_id:.,status:"FAIL",reason:"framework failed",target:$target}))}')"
    fi
    jq -c --argjson surface "$enriched_row" --argjson validator_ids "$validator_ids_json" '
      .rows[]
      | select(.mp_id as $mp | $validator_ids | index($mp))
      | .repo = $surface.repo
      | .repo_path = $surface.repo_path
      | .path = $surface.path
      | .tier = $surface.tier
      | .class = $surface.class
      | .language = $surface.language
      | .invoke_count_30d = ($surface.invoke_count_30d // 0)
      | .reachable = ($surface.reachable // false)
      | .reachability_reason = ($surface.reachability_reason // "unknown")
      | .reachability_dispatch_log_hits = ($surface.reachability_dispatch_log_hits // 0)
      | .reachability_inbound_caller_count = ($surface.reachability_inbound_caller_count // 0)
    ' <<<"$score" >"$out_file"
}

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
    audit_surface "$row" "$target_rows_dir/$(printf '%06d' "$count").jsonl" "$target_meta_dir/$(printf '%06d' "$count").jsonl" &
    count=$((count + 1))
    while [[ "$(jobs -pr | wc -l | tr -d ' ')" -ge "$parallel_jobs" ]]; do
      wait -n || true
    done
done < <(
  jq -c --arg re "$tier_regex" '
    select((.tier // "") | test($re))
    | select((.missing_repo // false) == false)
    | {repo,repo_path,path,tier,class,language,canonical_cli_present,invoke_count_30d}
  ' "$inventory"
)
wait
while IFS= read -r part; do
  cat "$part" >>"$targets_jsonl"
done < <(find "$target_meta_dir" -type f -name '*.jsonl' | sort)
while IFS= read -r part; do
  cat "$part" >>"$rows_jsonl"
done < <(find "$target_rows_dir" -type f -name '*.jsonl' | sort)
cleanup_target_dirs

summary_json="$out_dir/summary.json"
jq -s --arg sv "$SCHEMA_VERSION" --arg generated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg inventory "$inventory" '
  def c($s): map(select(.status == $s)) | length;
  def reachable_pass: map(select(.status == "PASS" and (.reachable == true))) | length;
  def dead_pass: map(select(.status == "PASS" and (.reachable != true))) | length;
  def reachable_fail: map(select(.status == "FAIL" and (.reachable == true))) | length;
  def dead_fail: map(select(.status == "FAIL" and (.reachable != true))) | length;
  . as $rows
  | ($rows | c("PASS")) as $pass
  | ($rows | c("FAIL")) as $fail
  | ($rows | c("SKIP")) as $skip
  | ($pass + $fail) as $applicable
  | ($rows | reachable_pass) as $reachable_pass
  | ($rows | dead_pass) as $dead_pass
  | ($rows | reachable_fail) as $reachable_fail
  | ($rows | dead_fail) as $dead_fail
  | (if $applicable == 0 then 0 else (($pass / $applicable) * 10000 | round / 10000) end) as $raw_ratio
  | (if $applicable == 0 then 0 else (($reachable_pass / $applicable) * 10000 | round / 10000) end) as $weighted_ratio
  | {
      schema_version:$sv,
      generated_at:$generated_at,
      inventory:$inventory,
      surface_count:($rows | map(.repo + ":" + .path) | unique | length),
      validator_count:($rows | map(.mp_id) | unique | length),
      baseline:{scope:"10-MP v1",skill_quality_bar_coverage_ratio:0.609},
      totals:{pass:$pass,fail:$fail,skip:$skip,applicable:$applicable,total:($rows|length),reachable_pass:$reachable_pass,dead_pass:$dead_pass,reachable_fail:$reachable_fail,dead_fail:$dead_fail},
      raw_coverage_ratio:$raw_ratio,
      reachability_weighted_coverage_ratio:$weighted_ratio,
      dead_code_pass_inflation_delta:(($raw_ratio - $weighted_ratio) * 10000 | round / 10000),
      skill_quality_bar_coverage_ratio:$raw_ratio,
      per_mp:(
        $rows
        | sort_by(.mp_id)
        | group_by(.mp_id)
        | map({
            mp_id:.[0].mp_id,
            pass:(c("PASS")),
            fail:(c("FAIL")),
            skip:(c("SKIP")),
            reachable_pass:(reachable_pass),
            dead_pass:(dead_pass),
            reachable_fail:(reachable_fail),
            dead_fail:(dead_fail),
            applicable:((c("PASS")) + (c("FAIL"))),
            coverage_ratio:(if ((c("PASS")) + (c("FAIL"))) == 0 then null else (((c("PASS")) / ((c("PASS")) + (c("FAIL")))) * 10000 | round / 10000) end),
            weighted_coverage:(if ((c("PASS")) + (c("FAIL"))) == 0 then null else (((reachable_pass) / ((c("PASS")) + (c("FAIL")))) * 10000 | round / 10000) end)
          })
      ),
      failing_samples:($rows | map(select(.status=="FAIL")) | .[:20]),
      top_lowest_coverage:(
        $rows
        | sort_by(.mp_id)
        | group_by(.mp_id)
        | map({
            mp_id:.[0].mp_id,
            pass:(c("PASS")),
            fail:(c("FAIL")),
            skip:(c("SKIP")),
            reachable_pass:(reachable_pass),
            dead_pass:(dead_pass),
            applicable:((c("PASS")) + (c("FAIL"))),
            coverage_ratio:(if ((c("PASS")) + (c("FAIL"))) == 0 then null else (((c("PASS")) / ((c("PASS")) + (c("FAIL")))) * 10000 | round / 10000) end),
            weighted_coverage:(if ((c("PASS")) + (c("FAIL"))) == 0 then null else (((reachable_pass) / ((c("PASS")) + (c("FAIL")))) * 10000 | round / 10000) end)
          })
        | map(select(.coverage_ratio != null))
        | sort_by(.coverage_ratio, .mp_id)
        | .[:5]
      ),
      top_highest_coverage:(
        $rows
        | sort_by(.mp_id)
        | group_by(.mp_id)
        | map({
            mp_id:.[0].mp_id,
            pass:(c("PASS")),
            fail:(c("FAIL")),
            skip:(c("SKIP")),
            reachable_pass:(reachable_pass),
            dead_pass:(dead_pass),
            applicable:((c("PASS")) + (c("FAIL"))),
            coverage_ratio:(if ((c("PASS")) + (c("FAIL"))) == 0 then null else (((c("PASS")) / ((c("PASS")) + (c("FAIL")))) * 10000 | round / 10000) end),
            weighted_coverage:(if ((c("PASS")) + (c("FAIL"))) == 0 then null else (((reachable_pass) / ((c("PASS")) + (c("FAIL")))) * 10000 | round / 10000) end)
          })
        | map(select(.coverage_ratio != null))
        | sort_by(.coverage_ratio, .mp_id)
        | reverse
        | .[:5]
      )
    }
' "$rows_jsonl" >"$summary_json"

scorecard="$out_dir/SCORECARD.md"
{
  printf '# Fleet Conformance Scorecard — %s\n\n' "$date_stamp"
  printf '%s\n' "- Schema: \`$SCHEMA_VERSION\`"
  printf '%s\n' "- Inventory: \`$inventory\`"
  jq -r '"- Surfaces audited: \(.surface_count)\n- Validators: \(.validator_count)\n- skill_quality_bar_coverage_ratio: \(.skill_quality_bar_coverage_ratio)\n- PASS/FAIL/SKIP: \(.totals.pass)/\(.totals.fail)/\(.totals.skip)\n- Applicable checks: \(.totals.applicable)"' "$summary_json"
  jq -r '"- raw_coverage_ratio: \(.raw_coverage_ratio)\n- reachability_weighted_coverage_ratio: \(.reachability_weighted_coverage_ratio)\n- dead-code PASS inflation delta: \(.dead_code_pass_inflation_delta)\n- Reachability split: reachable_pass=\(.totals.reachable_pass) dead_pass=\(.totals.dead_pass) reachable_fail=\(.totals.reachable_fail) dead_fail=\(.totals.dead_fail)"' "$summary_json"
  jq -r '"- raw=\(.raw_coverage_ratio) reachable_weighted=\(.reachability_weighted_coverage_ratio) delta=-\(.dead_code_pass_inflation_delta) (\(if .raw_coverage_ratio == 0 then 0 else ((.dead_code_pass_inflation_delta / .raw_coverage_ratio * 10000 | round) / 100) end)% inflation from dead-code PASS)"' "$summary_json"
  jq -r '"- v1 baseline \( .baseline.scope ): \( .baseline.skill_quality_bar_coverage_ratio )\n- v2 delta: \(((.skill_quality_bar_coverage_ratio - .baseline.skill_quality_bar_coverage_ratio) * 10000 | round / 10000))"' "$summary_json"
  printf '\n## Per MP\n\n| MP | PASS | FAIL | SKIP | Reachable PASS | Dead PASS | Applicable | Raw Coverage | Weighted Coverage |\n|---|---:|---:|---:|---:|---:|---:|---:|---:|\n'
  jq -r '.per_mp[] | "| \(.mp_id) | \(.pass) | \(.fail) | \(.skip) | \(.reachable_pass) | \(.dead_pass) | \(.applicable) | \(.coverage_ratio // "n/a") | \(.weighted_coverage // "n/a") |"' "$summary_json"
  printf '\n## Top-5 Lowest Coverage\n\n| MP | PASS | FAIL | SKIP | Reachable PASS | Dead PASS | Applicable | Raw Coverage | Weighted Coverage |\n|---|---:|---:|---:|---:|---:|---:|---:|---:|\n'
  jq -r '.top_lowest_coverage[] | "| \(.mp_id) | \(.pass) | \(.fail) | \(.skip) | \(.reachable_pass) | \(.dead_pass) | \(.applicable) | \(.coverage_ratio) | \(.weighted_coverage) |"' "$summary_json"
  printf '\n## Top-5 Highest Coverage\n\n| MP | PASS | FAIL | SKIP | Reachable PASS | Dead PASS | Applicable | Raw Coverage | Weighted Coverage |\n|---|---:|---:|---:|---:|---:|---:|---:|---:|\n'
  jq -r '.top_highest_coverage[] | "| \(.mp_id) | \(.pass) | \(.fail) | \(.skip) | \(.reachable_pass) | \(.dead_pass) | \(.applicable) | \(.coverage_ratio) | \(.weighted_coverage) |"' "$summary_json"
  printf '\n## Failing Samples\n\n'
  jq -r '.failing_samples[]? | "- \(.mp_id) \(.repo):`\(.path)` — \(.reason)"' "$summary_json"
} >"$scorecard"

if [[ "$json" -eq 1 ]]; then
  jq --arg scorecard "$scorecard" --arg rows "$rows_jsonl" '. + {scorecard:$scorecard, rows_jsonl:$rows}' "$summary_json"
else
  printf 'Wrote %s\n' "$scorecard"
  jq -r '"skill_quality_bar_coverage_ratio=\(.skill_quality_bar_coverage_ratio)"' "$summary_json"
fi
