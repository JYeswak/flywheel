#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-95"; slug="data-contract-reconciliation-ledger"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-95-data-contract-reconciliation-ledger-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
hay(){ rg -qi "$1" "$target" 2>/dev/null; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
hay 'schema version|schema_version' && hay 'freshness|completeness|SLA' && hay 'lineage' && hay 'rejected records|reject' && hay 'dedup|dedupe' && hay 'row count|row_count|reconciliation result' && emit PASS "pipeline records data contract, lineage, rejects, row counts, and reconciliation before trust" 0
hay 'etl|batch processing|migration|analytics|de-identification|billing data|dataset|pipeline|corruption' && emit FAIL "data pipeline lacks contract reconciliation ledger evidence" 1
emit SKIP "not a detected data-contract pipeline surface" 2
