#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-97"; slug="federated-retrieval-parity-provenance"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-97-federated-retrieval-parity-provenance-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
hay(){ rg -qi "$1" "$target" 2>/dev/null; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
hay 'model.*dimension|dimension.*model|embedding dimension' && hay 'per-source timeout|source timeout|timeout.*source' && hay 'rank normalization|normalize.*rank' && hay 'provenance|source' && hay 'ingest-count drift|ingest count drift|count drift' && emit PASS "federated retrieval records model/dimension, timeout, normalized rank, provenance, ingest drift" 0
hay 'qdrant|RAG|retrieval|vector|knowledge graph|source routing|collection|memory' && emit FAIL "retrieval surface lacks parity/provenance/drift evidence" 1
emit SKIP "not a detected federated retrieval surface" 2
