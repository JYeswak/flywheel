#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial -> passing per bead flywheel-k8gcv.13)
set -euo pipefail

VERSION="jeff-corpus-delta-reindex.v1.1.0"
SCHEMA_VERSION="jeff-corpus-delta-reindex/v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MANIFEST="${JEFF_CORPUS_MANIFEST:-$ROOT/.flywheel/jeff-corpus/v1/manifest.json}"
PENDING="${JEFF_CORPUS_PENDING:-$ROOT/.flywheel/jeff-corpus/pending-reindex.jsonl}"
DELTA="${JEFF_CORPUS_DELTA:-$ROOT/.flywheel/jeff-corpus/v2/delta-index.jsonl}"
LEDGER="${JEFF_CORPUS_DELTA_REINDEX_LEDGER:-$HOME/.local/state/flywheel/jeff-corpus-delta-reindex-ledger.jsonl}"
IDEMPOTENCY_KEY=""
DRY_RUN=0
APPLY=0
JSON_OUT=0
NOW="${JEFF_CORPUS_NOW:-}"

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

usage() {
  cat <<'USAGE'
Usage:
  jeff-corpus-delta-reindex.sh --dry-run|--apply [--idempotency-key KEY] [--json]
  jeff-corpus-delta-reindex.sh [--manifest PATH] [--pending PATH] [--delta PATH]
  jeff-corpus-delta-reindex.sh --info --json
  jeff-corpus-delta-reindex.sh --schema --json
  jeff-corpus-delta-reindex.sh --examples [--json]
  jeff-corpus-delta-reindex.sh doctor --json
  jeff-corpus-delta-reindex.sh health --json
  jeff-corpus-delta-reindex.sh validate --json
  jeff-corpus-delta-reindex.sh audit --json [--limit N]
  jeff-corpus-delta-reindex.sh why [topic] [--json]
  jeff-corpus-delta-reindex.sh quickstart [--json]
  jeff-corpus-delta-reindex.sh repair --scope <ledger-prime> [--dry-run|--apply --idempotency-key KEY] [--json]
  jeff-corpus-delta-reindex.sh --help|-h

Processes pending-reindex rows using git diff --name-only and records only changed file chunks.
USAGE
}

# ---------- canonical-cli emitters (added by flywheel-k8gcv.13) ----------

emit_info() {
  jq -nc --arg sv "$SCHEMA_VERSION" --arg version "$VERSION" \
    --arg manifest "$MANIFEST" --arg pending "$PENDING" --arg delta "$DELTA" --arg ledger "$LEDGER" \
    '{
      schema_version:$sv,
      command:"info",
      name:"jeff-corpus-delta-reindex.sh",
      version:$version,
      manifest:$manifest,
      pending:$pending,
      delta:$delta,
      ledger:$ledger,
      purpose:"Process pending-reindex rows using git diff --name-only; record only changed-file chunks as delta-index v2 rows. Companion to jeff-corpus-compact.sh.",
      subcommands:["doctor","health","validate","audit","why","repair","quickstart"],
      canonical_flags:["--info","--schema","--examples","--json","--apply","--dry-run","--idempotency-key","--manifest","--pending","--delta","--now"],
      capabilities:[
        "git-diff-name-only-driven-delta",
        "pending-reindex-jsonl-consumption",
        "manifest-v1-aware-chunk-emission",
        "dry-run-plan-emission",
        "ledger-append-on-apply"
      ],
      apply_supported:true,
      dry_run_supported:true,
      idempotency_key_required_for_apply:true,
      mutates_state:true,
      env_vars:["JEFF_CORPUS_MANIFEST","JEFF_CORPUS_PENDING","JEFF_CORPUS_DELTA","JEFF_CORPUS_DELTA_REINDEX_LEDGER","JEFF_CORPUS_NOW"],
      exit_codes:{"0":"reindex-ok","1":"reindex-error","2":"bad-args","3":"refused-apply-without-idempotency-key"}
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
        idempotency_key:{type:"string",description:"required with --apply"},
        manifest:{type:"string",description:"v1 manifest.json"},
        pending:{type:"string",description:"pending-reindex.jsonl with rows {repo, prev_commit, new_commit, ts}"},
        delta:{type:"string",description:"output v2 delta-index.jsonl"},
        now:{type:"string",description:"override ISO timestamp for tests"}
      }
    },
    output_schema:{
      type:"object",
      required:["schema_version","ts","mode"],
      properties:{
        schema_version:{type:"string"},
        ts:{type:"string",format:"date-time"},
        mode:{enum:["dry-run","apply"]},
        rows_processed:{type:"integer",minimum:0},
        changed_files_total:{type:"integer",minimum:0},
        delta_rows_emitted:{type:"integer",minimum:0}
      }
    },
    exit_codes:{"0":"reindex-ok","1":"reindex-error","2":"bad-args","3":"refused-apply-without-idempotency-key"}
  }'
}

emit_examples_text() {
  cat <<'EOF'
examples:
  jeff-corpus-delta-reindex.sh --dry-run --json
  jeff-corpus-delta-reindex.sh --apply --idempotency-key jcdr-2026-05-11 --json
  jeff-corpus-delta-reindex.sh --manifest /tmp/v1.json --pending /tmp/pending.jsonl --delta /tmp/v2.jsonl --dry-run --json
  jeff-corpus-delta-reindex.sh doctor --json
  jeff-corpus-delta-reindex.sh audit --json
EOF
}

emit_examples_json() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"examples",
    examples:[
      {name:"dry-run-plan",invocation:"jeff-corpus-delta-reindex.sh --dry-run --json",purpose:"compute delta rows from pending-reindex without writing v2 delta-index"},
      {name:"apply-with-idem-key",invocation:"jeff-corpus-delta-reindex.sh --apply --idempotency-key jcdr-2026-05-11 --json",purpose:"apply: emit delta-index v2 rows for changed-file chunks; requires --idempotency-key"},
      {name:"fixture-driven",invocation:"jeff-corpus-delta-reindex.sh --manifest /tmp/v1.json --pending /tmp/pending.jsonl --delta /tmp/v2.jsonl --dry-run --json",purpose:"override all paths for fixture-driven testing"},
      {name:"doctor",invocation:"jeff-corpus-delta-reindex.sh doctor --json",purpose:"verify jq + python3 + git + manifest + pending + ledger"},
      {name:"audit",invocation:"jeff-corpus-delta-reindex.sh audit --json",purpose:"tail recent reindex ledger rows"}
    ]
  }'
}

emit_canonical_doctor() {
  local ts; ts="$(now_iso)"
  local jq_status="pass"; command -v jq >/dev/null 2>&1 || jq_status="fail"
  local py_status="pass"; command -v python3 >/dev/null 2>&1 || py_status="fail"
  local git_status="pass"; command -v git >/dev/null 2>&1 || git_status="fail"
  local manifest_status="pass"; [[ -f "$MANIFEST" ]] || manifest_status="warn"
  local pending_status="pass"; [[ -f "$PENDING" ]] || pending_status="warn"
  local ledger_dir; ledger_dir="$(dirname "$LEDGER")"
  local ledger_status="pass"
  if [[ -e "$LEDGER" ]]; then
    [[ -w "$LEDGER" ]] || ledger_status="fail"
  else
    [[ -d "$ledger_dir" ]] || ledger_status="warn"
  fi
  local overall="pass"
  for s in "$jq_status" "$py_status" "$git_status" "$manifest_status" "$pending_status" "$ledger_status"; do
    case "$s" in
      fail) overall="fail" ;;
      warn) [[ "$overall" == "pass" ]] && overall="warn" ;;
    esac
  done
  jq -nc --arg sv "$SCHEMA_VERSION.doctor" --arg ts "$ts" --arg overall "$overall" \
    --arg jq_s "$jq_status" --arg py_s "$py_status" --arg git_s "$git_status" \
    --arg manifest_s "$manifest_status" --arg manifest "$MANIFEST" \
    --arg pending_s "$pending_status" --arg pending "$PENDING" \
    --arg ledger_s "$ledger_status" --arg ledger "$LEDGER" \
    '{
      schema_version:$sv,
      command:"doctor",
      ts:$ts,
      status:$overall,
      checks:[
        {name:"jq",status:$jq_s,detail:"jq required for envelope emission"},
        {name:"python3",status:$py_s,detail:"python3 required for reindex logic"},
        {name:"git",status:$git_s,detail:"git required for diff --name-only"},
        {name:"manifest",status:$manifest_s,path:$manifest,detail:"v1 manifest (warn if missing)"},
        {name:"pending",status:$pending_s,path:$pending,detail:"pending-reindex.jsonl (warn if missing)"},
        {name:"ledger_writable",status:$ledger_s,path:$ledger,detail:"append-only reindex ledger"}
      ]
    }'
}

emit_health() {
  local ts; ts="$(now_iso)"
  local row_count=0
  local last_mode=""
  if [[ -r "$LEDGER" ]]; then
    row_count="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$row_count" ]] && row_count=0
    if [[ "$row_count" -gt 0 ]]; then
      last_mode="$(tail -n 1 "$LEDGER" 2>/dev/null | jq -r '.mode // empty' 2>/dev/null || true)"
    fi
  fi
  jq -nc --arg sv "$SCHEMA_VERSION.health" --arg ts "$ts" \
    --arg ledger "$LEDGER" --argjson row_count "${row_count:-0}" --arg last_mode "${last_mode:-}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:"pass",ledger:$ledger,ledger_row_count:$row_count,last_mode:$last_mode}'
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
    '{schema_version:$sv,command:"validate",ts:$ts,status:$status,ledger:$ledger,row_count:$rows,invalid_row_count:$invalid,check:"every reindex row has non-empty schema_version"}'
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
    ""|delta-driven-reindex)
      body='Instead of re-embedding entire repos on every change, the delta-reindex walks pending-reindex.jsonl rows (each {repo, prev_commit, new_commit, ts}), runs git diff --name-only prev..new, and emits chunk-level delta rows for ONLY the changed files. The compaction step later folds these into manifest v3 + qdrant supersede ops.'
      ;;
    pending-reindex-jsonl)
      body='pending-reindex.jsonl is appended by upstream watchers (e.g., jeff-binary-version-watchtower drift detection or manual operator triggers) with rows: {repo, prev_commit, new_commit, ts}. The delta-reindex script consumes and clears (in --apply mode) and emits to v2/delta-index.jsonl.'
      ;;
    git-diff-name-only)
      body='git diff --name-only prev..new is the minimum-cost diff that gives us the set of changed paths. We do NOT embed/diff file contents here — just compute the changed-file set so downstream chunk extraction knows which files to re-embed. Companion: jeff-corpus-compact then folds delta + manifest → v3 manifest.'
      ;;
    *)
      body="unknown topic: $topic. known: delta-driven-reindex, pending-reindex-jsonl, git-diff-name-only"
      ;;
  esac
  jq -nc --arg sv "$SCHEMA_VERSION" --arg topic "${topic:-delta-driven-reindex}" --arg body "$body" \
    '{schema_version:$sv,command:"why",topic:$topic,body:$body}'
}

emit_quickstart() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"quickstart",
    status:"ok",
    steps:[
      {step:1,action:"check-doctor",command:"jeff-corpus-delta-reindex.sh doctor --json"},
      {step:2,action:"dry-run-plan",command:"jeff-corpus-delta-reindex.sh --dry-run --json"},
      {step:3,action:"apply-with-idem-key",command:"jeff-corpus-delta-reindex.sh --apply --idempotency-key jcdr-$(date +%Y%m%d) --json"},
      {step:4,action:"feed-into-compact",command:"jeff-corpus-compact.sh --apply --idempotency-key jcc-$(date +%Y%m%d) --json"}
    ],
    next_actions:["companion-jeff-corpus-compact","tail-ledger-via-audit"]
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
      --help|-h) printf 'repair --scope <ledger-prime> [--dry-run|--apply --idempotency-key KEY]\n'; exit 0 ;;
      "") shift ;;
      *) printf 'ERR: unknown repair arg %s\n' "$1" >&2; exit 2 ;;
    esac
  done
  if [[ -z "$scope" ]]; then
    printf '{"schema_version":"%s.repair","status":"refused","reason":"--scope required (ledger-prime)","exit_code":2}\n' "$SCHEMA_VERSION"
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
    *)
      printf '{"schema_version":"%s.repair","status":"refused","scope":"%s","reason":"unknown scope; known: ledger-prime","exit_code":2}\n' "$SCHEMA_VERSION" "$scope"
      exit 2
      ;;
  esac
}

# Canonical no-dash subcommand intercept BEFORE main arg parser.
case "${1:-}" in
  --info) emit_info; exit 0 ;;
  --schema) emit_schema; exit 0 ;;
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

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --json) JSON_OUT=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --apply) APPLY=1; shift ;;
    --idempotency-key) [ $# -ge 2 ] || { printf 'ERROR: --idempotency-key requires KEY\n' >&2; exit 2; }; IDEMPOTENCY_KEY="$2"; shift 2 ;;
    --idempotency-key=*) IDEMPOTENCY_KEY="${1#--idempotency-key=}"; shift ;;
    --manifest) [ $# -ge 2 ] || { printf 'ERROR: --manifest requires PATH\n' >&2; exit 2; }; MANIFEST="$2"; shift 2 ;;
    --pending) [ $# -ge 2 ] || { printf 'ERROR: --pending requires PATH\n' >&2; exit 2; }; PENDING="$2"; shift 2 ;;
    --delta) [ $# -ge 2 ] || { printf 'ERROR: --delta requires PATH\n' >&2; exit 2; }; DELTA="$2"; shift 2 ;;
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

# Backward-compat aliases I need:
# emit_examples_text and emit_examples_json are referenced above.
true

python3 - "$MANIFEST" "$PENDING" "$DELTA" "$DRY_RUN" "$APPLY" "$NOW" "$JSON_OUT" <<'PY'
import hashlib
import json
import subprocess
import sys
import time
from pathlib import Path

manifest_path = Path(sys.argv[1])
pending_path = Path(sys.argv[2])
delta_path = Path(sys.argv[3])
dry_run = sys.argv[4] == "1"
apply = sys.argv[5] == "1"
now = sys.argv[6] or time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
json_out = sys.argv[7] == "1"

manifest = json.loads(manifest_path.read_text())
pending = [json.loads(line) for line in pending_path.read_text().splitlines() if line.strip()] if pending_path.exists() else []

def run(args, cwd):
    return subprocess.run(args, cwd=cwd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True).stdout

def changed_files(repo_path: Path, old: str, new: str):
    out = run(["git", "diff", "--name-only", old, new, "--"], repo_path)
    return sorted([line for line in out.splitlines() if line.strip()])

def hash_file(path: Path):
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest(), path.stat().st_size

existing = {
    (repo["repo"], item["path"], item["sha256"])
    for repo in manifest.get("repos", [])
    for item in repo.get("content_hash_set", [])
    if item.get("sha256")
}
manifest_by_repo = {repo["repo"]: repo for repo in manifest.get("repos", [])}
delta_rows = []
processed = []
warnings = []

for row in pending:
    repo_name = row["repo"]
    repo = manifest_by_repo.get(repo_name)
    if not repo:
        warnings.append({"repo": repo_name, "code": "repo_not_in_manifest"})
        continue
    repo_path = Path(row["path"])
    try:
        files = changed_files(repo_path, row["old_sha"], row["new_sha"])
    except Exception as exc:
        warnings.append({"repo": repo_name, "code": "git_diff_failed", "detail": str(exc)})
        continue
    new_chunks = []
    for rel in files:
        path = repo_path / rel
        if not path.is_file():
            continue
        sha, size = hash_file(path)
        if (repo_name, rel, sha) in existing:
            continue
        chunk = {
            "schema_version": "jeff-corpus-delta/v1",
            "indexed_at": now,
            "repo": repo_name,
            "path": rel,
            "old_sha": row["old_sha"],
            "new_sha": row["new_sha"],
            "content_sha256": sha,
            "bytes": size,
            "target_collection": "jeff-corpus-v2",
        }
        new_chunks.append(chunk)
        delta_rows.append(chunk)
    processed.append({"repo": repo_name, "changed_files": len(files), "new_chunks": len(new_chunks)})
    if apply:
        repo["git_sha"] = row["new_sha"]
        repo["last_indexed_at"] = now
        by_path = {item["path"]: item for item in repo.get("content_hash_set", [])}
        for rel in files:
            path = repo_path / rel
            if path.is_file():
                sha, size = hash_file(path)
                by_path[rel] = {"path": rel, "sha256": sha, "bytes": size}
            else:
                by_path.pop(rel, None)
        repo["content_hash_set"] = [by_path[k] for k in sorted(by_path)]

if apply:
    delta_path.parent.mkdir(parents=True, exist_ok=True)
    with delta_path.open("a") as fh:
        for row in delta_rows:
            fh.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")
    tmp = manifest_path.with_suffix(manifest_path.suffix + ".tmp")
    tmp.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    tmp.replace(manifest_path)
    pending_path.write_text("")

summary = {
    "status": "pass",
    "mode": "dry_run" if dry_run else "apply",
    "pending_count": len(pending),
    "processed": processed,
    "new_chunks": len(delta_rows),
    "target_collection": "jeff-corpus-v2",
    "delta_path": str(delta_path),
    "manifest_updated": bool(apply),
    "full_reindex": False,
    "warnings": warnings,
}
print(json.dumps(summary, separators=(",", ":")) if json_out else f"new_chunks={len(delta_rows)} full_reindex=false")
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-76-authority-ranked-retrieval-maintenance.md`
