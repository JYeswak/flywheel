#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
usage: jeff-workaround-research-gate.sh [--repo PATH] [--ledger PATH] [--json]
       jeff-workaround-research-gate.sh --schema

Scans recent dispatch/callback text for Jeff-upstream issue intent and requires
a matching workaround-research receipt before the issue path is considered
eligible.
EOF
}

repo="/Users/josh/Developer/flywheel"
ledger=""
schema=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) repo="${2:-}"; shift 2 ;;
    --ledger) ledger="${2:-}"; shift 2 ;;
    --json) shift ;;
    --schema) schema=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

if [[ "$schema" -eq 1 ]]; then
  jq -n '{
    schema_version:"jeff-workaround-research-gate/v1",
    required_receipt_fields:["socraticode_queries","socraticode_k_per_query","workarounds_ranked","top_workarounds_copy_tested","jeff_issue_warranted","all_workarounds_failed","foundational_no_workaround"],
    doctor_fields:["jeff_issue_pending_without_workaround_research_count","jeff_issue_candidates_without_receipt","jeff_issue_workaround_gate_status"]
  }'
  exit 0
fi

if [[ -z "$ledger" ]]; then
  ledger="$repo/.flywheel/dispatch-log.jsonl"
fi

tmp="$(mktemp "${TMPDIR:-/tmp}/jeff-workaround-gate.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

: >"$tmp"
if [[ -f "$ledger" ]]; then
  rg -i 'jeff issue|file upstream|jeff-worthy|escalate to jeff' "$ledger" >>"$tmp" || true
fi
if compgen -G "/tmp/dispatch*jeff*" >/dev/null; then
  rg -i 'jeff issue|file upstream|jeff-worthy|escalate to jeff' /tmp/dispatch*jeff* >>"$tmp" || true
fi

candidates_json="[]"
if [[ -s "$tmp" ]]; then
  candidates_json="$(
    jq -R -s '
      split("\n")
      | map(select(length > 0))
      | map({text:., has_workaround_research:(test("workaround"; "i") and test("socraticode_queries|workarounds_ranked|copy_test"; "i"))})
      | map(select(.has_workaround_research | not))
    ' "$tmp"
  )"
fi

pending_count="$(jq 'length' <<<"$candidates_json")"
status="pass"
if [[ "$pending_count" -gt 0 ]]; then
  status="fail"
fi

jq -n \
  --arg status "$status" \
  --arg ledger "$ledger" \
  --argjson candidates "$candidates_json" \
  --argjson pending_count "$pending_count" \
  '{
    schema_version:"jeff-workaround-research-gate/v1",
    status:$status,
    ledger:$ledger,
    jeff_issue_pending_without_workaround_research_count:$pending_count,
    jeff_issue_candidates_without_receipt:$candidates,
    jeff_issue_workaround_gate_status:$status,
    required_predicate:"(.socraticode_queries >= 2 and .socraticode_k_per_query >= 10) and (.workarounds_ranked >= 5) and (.top_workarounds_copy_tested >= 2) and ((.jeff_issue_warranted == false) or (.all_workarounds_failed == true or .foundational_no_workaround == true))"
  }'

if [[ "$pending_count" -gt 0 ]]; then
  exit 2
fi
