#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial -> passing per bead flywheel-k8gcv.12)
set -euo pipefail

VERSION="jeff-corpus-compact.v1.1.0"
SCHEMA_VERSION="jeff-corpus-compact/v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MANIFEST="${JEFF_CORPUS_MANIFEST:-$ROOT/.flywheel/jeff-corpus/v1/manifest.json}"
DELTA="${JEFF_CORPUS_DELTA:-$ROOT/.flywheel/jeff-corpus/v2/delta-index.jsonl}"
OUT="${JEFF_CORPUS_COMPACT_OUT:-$ROOT/.flywheel/jeff-corpus/v3/manifest.json}"
RECEIPT_DIR="${JEFF_CORPUS_COMPACT_RECEIPTS:-$ROOT/.flywheel/jeff-corpus/compaction-receipts}"
LEDGER="${JEFF_CORPUS_COMPACT_LEDGER:-$HOME/.local/state/flywheel/jeff-corpus-compact-ledger.jsonl}"
IDEMPOTENCY_KEY=""
QDRANT_URL="${JEFF_CORPUS_QDRANT_URL:-}"
DRY_RUN=0
APPLY=0
JSON_OUT=0
NOW="${JEFF_CORPUS_NOW:-}"

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# ---------- canonical-cli emitters (added by flywheel-k8gcv.12) ----------

emit_info() {
  jq -nc --arg sv "$SCHEMA_VERSION" --arg version "$VERSION" \
    --arg manifest "$MANIFEST" --arg delta "$DELTA" --arg out "$OUT" \
    --arg receipt_dir "$RECEIPT_DIR" --arg ledger "$LEDGER" \
    '{
      schema_version:$sv,
      command:"info",
      name:"jeff-corpus-compact.sh",
      version:$version,
      manifest:$manifest,
      delta:$delta,
      out:$out,
      receipt_dir:$receipt_dir,
      ledger:$ledger,
      purpose:"Compact (manifest v1) + (delta-index v2) → manifest v3, superseding old chunks, applying corresponding qdrant ops. Weekly cadence; receipts are idempotent by --idempotency-key.",
      subcommands:["doctor","health","validate","audit","why","repair","quickstart"],
      canonical_flags:["--info","--schema","--examples","--json","--apply","--dry-run","--idempotency-key","--manifest","--delta","--out","--receipt-dir","--qdrant-url","--now"],
      capabilities:[
        "manifest-plus-delta-compaction",
        "qdrant-supersede-ops",
        "idempotent-replay-via-receipt-on-disk",
        "dry-run-plan-emission",
        "fixture-driven-qdrant-test-mode"
      ],
      apply_supported:true,
      dry_run_supported:true,
      idempotency_key_required_for_apply:true,
      mutates_state:true,
      env_vars:["JEFF_CORPUS_MANIFEST","JEFF_CORPUS_DELTA","JEFF_CORPUS_COMPACT_OUT","JEFF_CORPUS_COMPACT_RECEIPTS","JEFF_CORPUS_COMPACT_LEDGER","JEFF_CORPUS_QDRANT_URL","JEFF_CORPUS_QDRANT_FIXTURE","JEFF_CORPUS_NOW"],
      recommended_cadence:"weekly Sunday 04:00Z",
      exit_codes:{"0":"compaction-ok-or-replay","1":"compaction-error","2":"bad-args","3":"refused-apply-without-idempotency-key"}
    }'
}

emit_schema() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"schema",
    input_schema:{
      type:"object",
      properties:{
        dry_run:{type:"boolean"},
        apply:{type:"boolean"},
        idempotency_key:{type:"string",description:"required with --apply; receipt is keyed by this"},
        manifest:{type:"string",description:"path to v1 manifest.json"},
        delta:{type:"string",description:"path to v2 delta-index.jsonl"},
        out:{type:"string",description:"path to write v3 manifest.json"},
        receipt_dir:{type:"string",description:"dir for per-key receipts (idempotent replay store)"},
        qdrant_url:{type:"string",description:"qdrant URL (defaults to manifest.qdrant_url or http://localhost:16333)"}
      }
    },
    output_schema:{
      type:"object",
      required:["schema_version","ts"],
      properties:{
        schema_version:{type:"string"},
        ts:{type:"string",format:"date-time"},
        idempotent_replay:{type:"boolean"},
        superseded:{type:"integer",minimum:0},
        qdrant_ops:{type:"array"},
        manifest_v3:{type:"string"},
        receipt:{type:"string"}
      }
    },
    exit_codes:{"0":"compaction-ok-or-replay","1":"compaction-error","2":"bad-args","3":"refused-apply-without-idempotency-key"}
  }'
}

emit_examples_text() {
  cat <<'EOF'
examples:
  jeff-corpus-compact.sh --dry-run --json
  jeff-corpus-compact.sh --apply --idempotency-key jcc-2026-05-11 --json
  JEFF_CORPUS_QDRANT_FIXTURE=/tmp/qdrant.json jeff-corpus-compact.sh --dry-run --json
  jeff-corpus-compact.sh doctor --json
  jeff-corpus-compact.sh audit --json
EOF
}

emit_examples_json() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"examples",
    examples:[
      {name:"dry-run-probe",invocation:"jeff-corpus-compact.sh --dry-run --json",purpose:"compute compaction plan + qdrant ops without writing v3 manifest or executing ops"},
      {name:"apply-with-idem-key",invocation:"jeff-corpus-compact.sh --apply --idempotency-key jcc-2026-05-11 --json",purpose:"execute compaction + qdrant ops; receipt at receipt_dir/<key>.json makes replay idempotent"},
      {name:"fixture-driven",invocation:"JEFF_CORPUS_QDRANT_FIXTURE=/tmp/qdrant.json jeff-corpus-compact.sh --dry-run --json",purpose:"override qdrant probe with fixture (for tests)"},
      {name:"doctor",invocation:"jeff-corpus-compact.sh doctor --json",purpose:"verify jq + python3 + manifest + delta + receipt_dir + ledger"},
      {name:"audit",invocation:"jeff-corpus-compact.sh audit --json",purpose:"tail recent compaction ledger rows"}
    ]
  }'
}

emit_canonical_doctor() {
  local ts; ts="$(now_iso)"
  local jq_status="pass"; command -v jq >/dev/null 2>&1 || jq_status="fail"
  local py_status="pass"; command -v python3 >/dev/null 2>&1 || py_status="fail"
  local manifest_status="pass"; [[ -f "$MANIFEST" ]] || manifest_status="warn"
  local delta_status="pass"; [[ -f "$DELTA" ]] || delta_status="warn"
  local receipt_status="pass"
  if [[ -e "$RECEIPT_DIR" ]]; then
    [[ -w "$RECEIPT_DIR" ]] || receipt_status="fail"
  else
    [[ -d "$(dirname "$RECEIPT_DIR")" ]] || receipt_status="warn"
  fi
  local ledger_dir; ledger_dir="$(dirname "$LEDGER")"
  local ledger_status="pass"
  if [[ -e "$LEDGER" ]]; then
    [[ -w "$LEDGER" ]] || ledger_status="fail"
  else
    [[ -d "$ledger_dir" ]] || ledger_status="warn"
  fi
  local overall="pass"
  for s in "$jq_status" "$py_status" "$manifest_status" "$delta_status" "$receipt_status" "$ledger_status"; do
    case "$s" in
      fail) overall="fail" ;;
      warn) [[ "$overall" == "pass" ]] && overall="warn" ;;
    esac
  done
  jq -nc --arg sv "$SCHEMA_VERSION.doctor" --arg ts "$ts" --arg overall "$overall" \
    --arg jq_s "$jq_status" --arg py_s "$py_status" \
    --arg manifest_s "$manifest_status" --arg manifest "$MANIFEST" \
    --arg delta_s "$delta_status" --arg delta "$DELTA" \
    --arg receipt_s "$receipt_status" --arg receipt_dir "$RECEIPT_DIR" \
    --arg ledger_s "$ledger_status" --arg ledger "$LEDGER" \
    '{
      schema_version:$sv,
      command:"doctor",
      ts:$ts,
      status:$overall,
      checks:[
        {name:"jq",status:$jq_s,detail:"jq required for envelope emission"},
        {name:"python3",status:$py_s,detail:"python3 required for compaction logic"},
        {name:"manifest",status:$manifest_s,path:$manifest,detail:"v1 manifest.json (warn if missing)"},
        {name:"delta",status:$delta_s,path:$delta,detail:"v2 delta-index.jsonl (warn if missing)"},
        {name:"receipt_dir",status:$receipt_s,path:$receipt_dir,detail:"per-idempotency-key receipt store"},
        {name:"ledger_writable",status:$ledger_s,path:$ledger,detail:"append-only compaction ledger"}
      ]
    }'
}

emit_health() {
  local ts; ts="$(now_iso)"
  local row_count=0
  local receipt_count=0
  if [[ -r "$LEDGER" ]]; then
    row_count="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$row_count" ]] && row_count=0
  fi
  if [[ -d "$RECEIPT_DIR" ]]; then
    receipt_count="$(find "$RECEIPT_DIR" -maxdepth 1 -name '*.json' 2>/dev/null | wc -l | tr -d ' ')"
    [[ -z "$receipt_count" ]] && receipt_count=0
  fi
  jq -nc --arg sv "$SCHEMA_VERSION.health" --arg ts "$ts" \
    --arg ledger "$LEDGER" --argjson row_count "${row_count:-0}" \
    --arg receipt_dir "$RECEIPT_DIR" --argjson receipt_count "${receipt_count:-0}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:"pass",ledger:$ledger,ledger_row_count:$row_count,receipt_dir:$receipt_dir,receipt_count:$receipt_count}'
}

emit_canonical_validate() {
  local ts; ts="$(now_iso)"
  local rows=0 invalid=0
  if [[ -r "$LEDGER" ]]; then
    rows="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$rows" ]] && rows=0
    if [[ "$rows" -gt 0 ]]; then
      invalid="$(jq -c 'select((.schema_version // "") == "")' "$LEDGER" 2>/dev/null | wc -l | tr -d ' ')"
      [[ -z "$invalid" ]] && invalid=0
    fi
  fi
  local status="pass"
  [[ "$invalid" -gt 0 ]] && status="violations"
  jq -nc --arg sv "$SCHEMA_VERSION.validate" --arg ts "$ts" --arg status "$status" \
    --argjson rows "${rows:-0}" --argjson invalid "${invalid:-0}" --arg ledger "$LEDGER" \
    '{schema_version:$sv,command:"validate",ts:$ts,status:$status,ledger:$ledger,row_count:$rows,invalid_row_count:$invalid,check:"every compaction row has non-empty schema_version"}'
}

emit_audit() {
  local limit="${1:-20}"
  local ts; ts="$(now_iso)"
  if [[ ! -r "$LEDGER" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION.audit" --arg ts "$ts" --arg ledger "$LEDGER" \
      '{schema_version:$sv,command:"audit",ts:$ts,status:"missing",ledger:$ledger,row_count:0,recent:[]}'
    return 0
  fi
  local row_count
  row_count="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
  [[ -z "$row_count" ]] && row_count=0
  local recent='[]'
  if [[ "$row_count" -gt 0 ]]; then
    recent="$(tail -n "$limit" "$LEDGER" 2>/dev/null | jq -cs '.' 2>/dev/null || printf '%s' '[]')"
    [[ -z "$recent" ]] && recent='[]'
  fi
  local status="pass"
  [[ "$row_count" -eq 0 ]] && status="empty"
  jq -nc --arg sv "$SCHEMA_VERSION.audit" --arg ts "$ts" --arg status "$status" \
    --arg ledger "$LEDGER" --argjson row_count "$row_count" --argjson recent "$recent" \
    '{schema_version:$sv,command:"audit",ts:$ts,status:$status,ledger:$ledger,row_count:$row_count,recent:$recent}'
}

emit_why() {
  local topic="${1:-}"
  local body=""
  case "$topic" in
    ""|compaction-flow)
      body='Inputs: v1 manifest.json + v2 delta-index.jsonl. Output: v3 manifest.json + per-repo qdrant supersede ops. Old chunks are marked superseded but their qdrant points remain until explicit delete-by-id ops fire. Receipt at receipt_dir/<idempotency-key>.json makes the apply idempotent on replay.'
      ;;
    idempotent-replay)
      body='Apply mode is idempotent by --idempotency-key: if receipt_dir/<key>.json exists, the script short-circuits with idempotent_replay=true and returns the cached receipt. Re-running with the SAME key is safe; re-running with a NEW key produces a fresh compaction pass against current manifest+delta.'
      ;;
    qdrant-supersede)
      body='Per-repo qdrant ops: superseded chunk ids → delete-by-id requests sent to JEFF_CORPUS_QDRANT_URL (defaults to manifest.qdrant_url or http://localhost:16333). Fixture override: JEFF_CORPUS_QDRANT_FIXTURE=<path.json> short-circuits the HTTP layer for tests.'
      ;;
    *)
      body="unknown topic: $topic. known: compaction-flow, idempotent-replay, qdrant-supersede"
      ;;
  esac
  jq -nc --arg sv "$SCHEMA_VERSION" --arg topic "${topic:-compaction-flow}" --arg body "$body" \
    '{schema_version:$sv,command:"why",topic:$topic,body:$body}'
}

emit_quickstart() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"quickstart",
    status:"ok",
    steps:[
      {step:1,action:"check-doctor",command:"jeff-corpus-compact.sh doctor --json"},
      {step:2,action:"dry-run-plan",command:"jeff-corpus-compact.sh --dry-run --json"},
      {step:3,action:"apply-with-idem-key",command:"jeff-corpus-compact.sh --apply --idempotency-key jcc-$(date +%Y%m%d) --json"},
      {step:4,action:"audit-recent",command:"jeff-corpus-compact.sh audit --json"}
    ],
    next_actions:["wire-to-weekly-cron-sunday-04Z","tail-receipt-dir-for-forensics"]
  }'
}

emit_repair() {
  local scope="" mode="dry_run" idem_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --scope) scope="${2:-}"; shift 2 ;;
      --dry-run) mode="dry_run"; shift ;;
      --apply) mode="apply"; shift ;;
      --idempotency-key) idem_key="${2:-}"; shift 2 ;;
      --idempotency-key=*) idem_key="${1#--idempotency-key=}"; shift ;;
      --json) shift ;;
      --help|-h) printf 'repair --scope <ledger-prime|receipt-dir-prime> [--dry-run|--apply --idempotency-key KEY]\n'; exit 0 ;;
      "") shift ;;
      *) printf 'ERR: unknown repair arg %s\n' "$1" >&2; exit 2 ;;
    esac
  done
  if [[ -z "$scope" ]]; then
    printf '{"schema_version":"%s.repair","status":"refused","reason":"--scope required (ledger-prime|receipt-dir-prime)","exit_code":2}\n' "$SCHEMA_VERSION"
    exit 2
  fi
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    printf '{"schema_version":"%s.repair","status":"refused","mode":"apply","scope":"%s","reason":"--apply requires --idempotency-key","exit_code":3}\n' "$SCHEMA_VERSION" "$scope"
    exit 3
  fi
  local ts; ts="$(now_iso)"
  case "$scope" in
    ledger-prime)
      local ledger_dir present_before present_after
      ledger_dir="$(dirname "$LEDGER")"
      present_before="$([[ -f "$LEDGER" ]] && printf true || printf false)"
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$ledger_dir" 2>/dev/null || true
        [[ -f "$LEDGER" ]] || : > "$LEDGER"
      fi
      present_after="$([[ -f "$LEDGER" ]] && printf true || printf false)"
      jq -nc --arg sv "$SCHEMA_VERSION.repair" --arg ts "$ts" --arg scope "$scope" --arg mode "$mode" \
        --arg ledger "$LEDGER" --arg key "$idem_key" \
        --argjson before "$present_before" --argjson after "$present_after" \
        '{schema_version:$sv,command:"repair",ts:$ts,status:"pass",scope:$scope,mode:$mode,idempotency_key:$key,ledger:$ledger,ledger_present_before:$before,ledger_present_after:$after}'
      ;;
    receipt-dir-prime)
      local before_exists; before_exists="$([[ -d "$RECEIPT_DIR" ]] && printf true || printf false)"
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$RECEIPT_DIR" 2>/dev/null || true
      fi
      local after_exists; after_exists="$([[ -d "$RECEIPT_DIR" ]] && printf true || printf false)"
      jq -nc --arg sv "$SCHEMA_VERSION.repair" --arg ts "$ts" --arg scope "$scope" --arg mode "$mode" \
        --arg path "$RECEIPT_DIR" --arg key "$idem_key" \
        --argjson before "$before_exists" --argjson after "$after_exists" \
        '{schema_version:$sv,command:"repair",ts:$ts,status:"pass",scope:$scope,mode:$mode,idempotency_key:$key,receipt_dir:$path,present_before:$before,present_after:$after}'
      ;;
    *)
      printf '{"schema_version":"%s.repair","status":"refused","scope":"%s","reason":"unknown scope; known: ledger-prime, receipt-dir-prime","exit_code":2}\n' "$SCHEMA_VERSION" "$scope"
      exit 2
      ;;
  esac
}

# Canonical no-dash subcommand intercept BEFORE main arg parser.
case "${1:-}" in
  --schema) emit_schema; exit 0 ;;
  --info) emit_info; exit 0 ;;
  --examples)
    shift
    if [[ "${1:-}" == "--json" ]]; then emit_examples_json; else emit_examples_text; fi
    exit 0
    ;;
  doctor) shift; emit_canonical_doctor; exit 0 ;;
  health) shift; emit_health; exit 0 ;;
  validate) shift; emit_canonical_validate; exit 0 ;;
  audit)
    shift
    LIMIT=20
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --limit) LIMIT="${2:-20}"; shift 2 ;;
        --json) shift ;;
        "") shift ;;
        *) shift ;;
      esac
    done
    emit_audit "$LIMIT"
    exit 0
    ;;
  why)
    shift
    TOPIC=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --json) shift ;;
        "") shift ;;
        *) [[ -z "$TOPIC" ]] && TOPIC="$1"; shift ;;
      esac
    done
    emit_why "$TOPIC"
    exit 0
    ;;
  quickstart) shift; emit_quickstart; exit 0 ;;
  repair) shift; emit_repair "$@"; exit 0 ;;
esac

usage() {
  printf '%s\n' \
    "Usage:" \
    "  jeff-corpus-compact.sh --dry-run|--apply [--idempotency-key KEY] [--json]" \
    "  jeff-corpus-compact.sh [--manifest PATH] [--delta PATH] [--out PATH] [--receipt-dir PATH] [--qdrant-url URL]" \
    "" \
    "Recommended weekly schedule: Sunday 04:00Z."
}

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --json) JSON_OUT=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --apply) APPLY=1; shift ;;
    --manifest) [ $# -ge 2 ] || { printf 'ERROR: --manifest requires PATH\n' >&2; exit 2; }; MANIFEST="$2"; shift 2 ;;
    --delta) [ $# -ge 2 ] || { printf 'ERROR: --delta requires PATH\n' >&2; exit 2; }; DELTA="$2"; shift 2 ;;
    --out) [ $# -ge 2 ] || { printf 'ERROR: --out requires PATH\n' >&2; exit 2; }; OUT="$2"; shift 2 ;;
    --receipt-dir) [ $# -ge 2 ] || { printf 'ERROR: --receipt-dir requires PATH\n' >&2; exit 2; }; RECEIPT_DIR="$2"; shift 2 ;;
    --idempotency-key) [ $# -ge 2 ] || { printf 'ERROR: --idempotency-key requires KEY\n' >&2; exit 2; }; IDEMPOTENCY_KEY="$2"; shift 2 ;;
    --qdrant-url) [ $# -ge 2 ] || { printf 'ERROR: --qdrant-url requires URL\n' >&2; exit 2; }; QDRANT_URL="$2"; shift 2 ;;
    --now) [ $# -ge 2 ] || { printf 'ERROR: --now requires ISO timestamp\n' >&2; exit 2; }; NOW="$2"; shift 2 ;;
    *) printf 'ERROR: unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

if [ "$DRY_RUN" -eq 0 ] && [ "$APPLY" -eq 0 ]; then
  printf 'ERROR: choose --dry-run or --apply\n' >&2
  exit 2
fi
# Canonical apply contract: --apply requires --idempotency-key.
if [ "$APPLY" -eq 1 ] && [ -z "$IDEMPOTENCY_KEY" ]; then
  printf '{"schema_version":"%s","status":"refused","mode":"apply","reason":"--apply requires --idempotency-key","exit_code":3}\n' "$SCHEMA_VERSION"
  exit 3
fi

python3 - "$MANIFEST" "$DELTA" "$OUT" "$DRY_RUN" "$APPLY" "$NOW" "$JSON_OUT" "$RECEIPT_DIR" "$IDEMPOTENCY_KEY" "$QDRANT_URL" <<'PY'
import gzip
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

manifest_path = Path(sys.argv[1])
delta_path = Path(sys.argv[2])
out_path = Path(sys.argv[3])
dry_run = sys.argv[4] == "1"
apply = sys.argv[5] == "1"
now = sys.argv[6] or time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
json_out = sys.argv[7] == "1"
receipt_dir = Path(sys.argv[8])
idempotency_key = sys.argv[9]
qdrant_url_arg = sys.argv[10].rstrip("/")

safe_ts = re.sub(r"[^0-9A-Za-z]+", "", now)
safe_key = re.sub(r"[^0-9A-Za-z_.-]+", "_", idempotency_key)
receipt_path = receipt_dir / f"{safe_key}.json" if idempotency_key else None
if apply and receipt_path and receipt_path.exists():
    receipt = json.loads(receipt_path.read_text())
    receipt["idempotent_replay"] = True
    print(json.dumps(receipt, separators=(",", ":")) if json_out else f"idempotent_replay=true receipt={receipt_path}")
    raise SystemExit(0)

manifest = json.loads(manifest_path.read_text())
delta_rows = [json.loads(line) for line in delta_path.read_text().splitlines() if line.strip()] if delta_path.exists() else []
by_repo = {repo["repo"]: repo for repo in manifest.get("repos", [])}
qdrant_url = qdrant_url_arg or manifest.get("qdrant_url") or "http://localhost:16333"
qdrant_fixture_path = os.environ.get("JEFF_CORPUS_QDRANT_FIXTURE")
qdrant_fixture = None
if qdrant_fixture_path:
    qdrant_fixture = json.loads(Path(qdrant_fixture_path).read_text())

superseded = 0
qdrant_ops = []
refused_collections = []

def collection_count(collection):
    if qdrant_fixture is not None:
        return int(qdrant_fixture.get("collections", {}).get(collection, {}).get("points_count", 0))
    url = f"{qdrant_url}/collections/{urllib.parse.quote(collection, safe='')}"
    try:
        with urllib.request.urlopen(url, timeout=10) as response:
            payload = json.loads(response.read().decode())
        result = payload.get("result") or {}
        return int(result.get("points_count") or result.get("indexed_vectors_count") or 0)
    except (OSError, urllib.error.URLError, json.JSONDecodeError, ValueError) as exc:
        raise RuntimeError(f"qdrant count failed for {collection}: {exc}") from exc

def delete_superseded_point(collection, relative_path, old_sha):
    old_hash = (old_sha or "")[:16]
    if not old_hash:
        return 0
    if qdrant_fixture is not None:
        coll = qdrant_fixture.setdefault("collections", {}).setdefault(collection, {})
        deleted = int(coll.get("delete_matches", 0))
        coll["points_count"] = max(0, int(coll.get("points_count", 0)) - deleted)
        coll["delete_matches"] = 0
        return deleted
    body = {
        "filter": {
            "must": [
                {"key": "relativePath", "match": {"value": relative_path}},
                {"key": "contentHash", "match": {"value": old_hash}},
            ]
        }
    }
    data = json.dumps(body).encode()
    url = f"{qdrant_url}/collections/{urllib.parse.quote(collection, safe='')}/points/delete?wait=true"
    request = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"}, method="POST")
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            response.read()
        return -1
    except (OSError, urllib.error.URLError) as exc:
        raise RuntimeError(f"qdrant delete failed for {collection}:{relative_path}: {exc}") from exc

for row in delta_rows:
    repo = by_repo.get(row["repo"])
    if not repo:
        continue
    by_path = {item["path"]: item for item in repo.get("content_hash_set", [])}
    old_item = by_path.get(row["path"])
    if row["path"] in by_path:
        superseded += 1
        collection = repo.get("qdrant_collection")
        target = row.get("target_collection") or collection
        if target and target.startswith("codebase_") and target != collection:
            refused_collections.append({"repo": row["repo"], "path": row["path"], "target_collection": target, "allowed_collection": collection})
        if collection:
            op = {
                "repo": row["repo"],
                "path": row["path"],
                "collection": collection,
                "old_content_hash": (old_item or {}).get("sha256", "")[:16],
                "delete_issued": False,
                "points_before": None,
                "points_after": None,
                "points_deleted": 0,
            }
            if apply:
                op["points_before"] = collection_count(collection)
                deleted = delete_superseded_point(collection, row["path"], (old_item or {}).get("sha256"))
                op["delete_issued"] = True
                op["points_after"] = collection_count(collection)
                op["points_deleted"] = deleted if deleted >= 0 else max(0, op["points_before"] - op["points_after"])
            qdrant_ops.append(op)
    by_path[row["path"]] = {"path": row["path"], "sha256": row["content_sha256"], "bytes": row["bytes"]}
    repo["content_hash_set"] = [by_path[k] for k in sorted(by_path)]
    repo["git_sha"] = row.get("new_sha") or repo.get("git_sha")
    repo["last_indexed_at"] = row.get("indexed_at") or now
    repo["chunk_count"] = int(repo.get("chunk_count") or 0) + 1

raw_total_bytes = int(manifest.get("raw_total_repo_size_bytes") or manifest.get("total_repo_size_bytes") or 0)
compacted_total_bytes = 0
for repo in manifest.get("repos", []):
    raw_repo_bytes = int(repo.get("raw_repo_size_bytes") or repo.get("repo_size_bytes") or 0)
    repo["raw_repo_size_bytes"] = raw_repo_bytes
    compacted_repo_bytes = sum(int(item.get("bytes") or 0) for item in repo.get("content_hash_set", []))
    repo["repo_size_bytes"] = compacted_repo_bytes
    repo["compacted_content_bytes"] = compacted_repo_bytes
    compacted_total_bytes += compacted_repo_bytes

manifest["schema_version"] = "jeff-corpus-manifest/v1"
manifest["baseline"] = "jeff-corpus-v3"
manifest["compacted_at"] = now
manifest["delta_rows_merged"] = len(delta_rows)
manifest["superseded_chunks_dropped"] = superseded
manifest["raw_total_repo_size_bytes"] = raw_total_bytes
manifest["raw_total_repo_size_mb"] = round(raw_total_bytes / 1024 / 1024, 1) if raw_total_bytes else 0
manifest["total_repo_size_bytes"] = compacted_total_bytes
manifest["total_repo_size_mb"] = round(compacted_total_bytes / 1024 / 1024, 1)
manifest["compaction_semantics"] = {
    "storage_metric": "sum(content_hash_set[].bytes)",
    "raw_repo_size_preserved_as": "raw_repo_size_bytes",
    "qdrant_cleanup": "delete superseded old relativePath/contentHash points in each repo manifest collection",
}
manifest["qdrant_cleanup"] = {
    "qdrant_url": qdrant_url,
    "superseded_rows": len(qdrant_ops),
    "points_deleted": sum(int(op.get("points_deleted") or 0) for op in qdrant_ops),
    "refused_collections": refused_collections,
}

archive_root = manifest_path.parent.parent if manifest_path.parent.name == "v1" else manifest_path.parent
archive_manifest_path = archive_root / f"v1.archived-{safe_ts}.json.gz"
archive_delta_path = archive_root / f"v2.archived-{safe_ts}.jsonl.gz"
if apply:
    archive_root.mkdir(parents=True, exist_ok=True)
    with gzip.open(archive_manifest_path, "wt") as fh:
        json.dump(json.loads(manifest_path.read_text()), fh, sort_keys=True)
    if delta_path.exists():
        with gzip.open(archive_delta_path, "wt") as fh:
            fh.write(delta_path.read_text())
    for target in {out_path, manifest_path}:
        target.parent.mkdir(parents=True, exist_ok=True)
        tmp = target.with_suffix(target.suffix + ".tmp")
        tmp.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
        tmp.replace(target)
    if delta_path.exists():
        delta_path.write_text("")

summary = {
    "status": "pass",
    "mode": "dry_run" if dry_run else "apply",
    "source_manifest": str(manifest_path),
    "delta_path": str(delta_path),
    "output_manifest": str(out_path),
    "delta_rows_merged": len(delta_rows),
    "superseded_chunks_dropped": superseded,
    "qdrant_deletes_attempted": len([op for op in qdrant_ops if op.get("delete_issued")]),
    "qdrant_points_deleted": sum(int(op.get("points_deleted") or 0) for op in qdrant_ops),
    "qdrant_ops": qdrant_ops,
    "qdrant_refused_collections": refused_collections,
    "pre_total_mb": round(raw_total_bytes / 1024 / 1024, 1) if raw_total_bytes else 0,
    "post_total_mb": manifest["total_repo_size_mb"],
    "archive_manifest_path": str(archive_manifest_path) if apply else None,
    "archive_delta_path": str(archive_delta_path) if apply and delta_path.exists() else None,
    "retired_to_cold_storage": bool(apply),
    "promoted_to_doctor_baseline": bool(apply),
    "idempotency_key": idempotency_key or None,
    "receipt_path": str(receipt_path) if receipt_path else None,
    "idempotent_replay": False,
    "recommended_schedule": "Sunday 04:00Z",
}
if apply and receipt_path:
    receipt_dir.mkdir(parents=True, exist_ok=True)
    receipt_path.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n")
print(json.dumps(summary, separators=(",", ":")) if json_out else f"merged={len(delta_rows)} superseded={superseded}")
PY
