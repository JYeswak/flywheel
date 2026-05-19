#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
usage: probe-shape-normalizer.sh --class CLASS --original-jq JQ [--sample PATH] [--json]
       probe-shape-normalizer.sh --schema

CLASS: null_vs_empty | missing_vs_null | zero_vs_false | case_only | numeric_string
EOF
}

schema=0
semantic_class=""
original_jq=""
sample=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --class) semantic_class="${2:-}"; shift 2 ;;
    --original-jq) original_jq="${2:-}"; shift 2 ;;
    --sample) sample="${2:-}"; shift 2 ;;
    --json) shift ;;
    --schema) schema=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

if [[ "$schema" -eq 1 ]]; then
  jq -n '{
    schema_version:"probe-shape-normalization/v1",
    semantic_equivalence_classes:["null_vs_empty","missing_vs_null","zero_vs_false","case_only","numeric_string"],
    required_fields:["original_jq","observed_shape","semantic_equivalence_class","normalized_jq","sample_before","sample_after","semantic_divergence","decision"],
    doctor_fields:["probe_shape_normalization_count","probe_shape_semantic_escalation_count","probe_shape_normalizations"]
  }'
  exit 0
fi

if [[ -z "$semantic_class" || -z "$original_jq" ]]; then
  printf 'missing --class or --original-jq\n' >&2
  usage >&2
  exit 64
fi

normalized_jq=""
case "$semantic_class" in
  null_vs_empty) normalized_jq="(${original_jq} // [])" ;;
  missing_vs_null) normalized_jq="(${original_jq} // null)" ;;
  zero_vs_false) normalized_jq="(((${original_jq} // 0) == 0) or ((${original_jq} // false) == false))" ;;
  case_only) normalized_jq="(${original_jq} | if type == \"string\" then ascii_downcase else . end)" ;;
  numeric_string) normalized_jq="(${original_jq} | if type == \"string\" then tonumber else . end)" ;;
  *) normalized_jq="";;
esac

decision="proceed"
semantic_divergence=false
if [[ -z "$normalized_jq" ]]; then
  decision="escalate"
  semantic_divergence=true
fi

sample_before=null
sample_after=null
observed_shape='{}'
if [[ -n "$sample" && -f "$sample" && "$semantic_divergence" == false ]]; then
  sample_before="$(jq -c "$original_jq" "$sample" 2>/dev/null || printf 'null')"
  sample_after="$(jq -c "$normalized_jq" "$sample" 2>/dev/null || printf 'null')"
  observed_shape="$(jq -n --argjson before "$sample_before" --argjson after "$sample_after" '{before_type:($before|type), after_type:($after|type)}')"
fi

normalization_count=0
semantic_escalation_count=0
if [[ "$semantic_divergence" == false ]]; then
  normalization_count=1
else
  semantic_escalation_count=1
fi

jq -n \
  --arg original_jq "$original_jq" \
  --arg observed_shape "$observed_shape" \
  --arg semantic_equivalence_class "$semantic_class" \
  --arg normalized_jq "$normalized_jq" \
  --argjson sample_before "$sample_before" \
  --argjson sample_after "$sample_after" \
  --argjson semantic_divergence "$semantic_divergence" \
  --arg decision "$decision" \
  --argjson probe_shape_normalization_count "$normalization_count" \
  --argjson probe_shape_semantic_escalation_count "$semantic_escalation_count" \
  '{
    schema_version:"probe-shape-normalization/v1",
    original_jq:$original_jq,
    observed_shape:($observed_shape | fromjson),
    semantic_equivalence_class:$semantic_equivalence_class,
    normalized_jq:$normalized_jq,
    sample_before:$sample_before,
    sample_after:$sample_after,
    semantic_divergence:$semantic_divergence,
    decision:$decision,
    probe_shape_normalization_count:$probe_shape_normalization_count,
    probe_shape_semantic_escalation_count:$probe_shape_semantic_escalation_count,
    probe_shape_normalizations:[
      {
        original_jq:$original_jq,
        semantic_equivalence_class:$semantic_equivalence_class,
        normalized_jq:$normalized_jq,
        semantic_divergence:$semantic_divergence,
        decision:$decision
      }
    ]
  }'

if [[ "$semantic_divergence" == true ]]; then
  exit 2
fi

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
