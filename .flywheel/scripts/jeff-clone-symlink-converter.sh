#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial -> passing per bead flywheel-k8gcv.11)
set -euo pipefail

VERSION="jeff-clone-symlink-converter.v1.1.0"
SCHEMA_VERSION="jeff-clone-symlink-receipt/v1"
LEDGER="${JEFF_CLONE_LEDGER:-$HOME/.local/state/flywheel/jeff-clone-symlink-converter-ledger.jsonl}"
ROOT_BASE="${JEFF_CLONE_ROOT_BASE:-/Users/josh/Developer}"
CORPUS_BASE="${JEFF_CLONE_CORPUS_BASE:-$ROOT_BASE/jeff-corpus}"
PAIR=""
CANONICAL_SIDE="corpus"
MODE="dry-run"
BACKUP_DIR="$HOME/.local/state/flywheel/jeff-clone-backups"
JSON_OUT=0
IDEMPOTENCY_KEY=""

usage() {
  cat <<'EOF'
usage:
  jeff-clone-symlink-converter.sh --pair NAME [--canonical-side root|corpus] [--mode dry-run|apply] [--idempotency-key KEY] [--backup-dir PATH] [--json]
  jeff-clone-symlink-converter.sh --info --json
  jeff-clone-symlink-converter.sh --schema --json
  jeff-clone-symlink-converter.sh --examples [--json]
  jeff-clone-symlink-converter.sh doctor --json
  jeff-clone-symlink-converter.sh health --json
  jeff-clone-symlink-converter.sh validate --json
  jeff-clone-symlink-converter.sh audit --json [--limit N]
  jeff-clone-symlink-converter.sh why [topic] [--json]
  jeff-clone-symlink-converter.sh quickstart [--json]
  jeff-clone-symlink-converter.sh repair --scope <ledger-prime|backup-dir-prime> [--dry-run|--apply --idempotency-key KEY] [--json]
  jeff-clone-symlink-converter.sh --help|-h
EOF
}

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

emit() {
  local payload="$1"
  if [[ "$JSON_OUT" -eq 1 ]]; then jq -c . <<<"$payload"; else jq . <<<"$payload"; fi
}

fail_json() {
  local code="$1" reason="$2" exit_code="$3"
  emit "$(jq -nc --arg schema_version "$SCHEMA_VERSION" --arg status "$code" --arg reason "$reason" \
    '{schema_version:$schema_version,status:$status,reason:$reason}')"
  exit "$exit_code"
}

info() {
  jq -nc --arg version "$VERSION" --arg schema_version "$SCHEMA_VERSION" --arg ledger "$LEDGER" --arg backup_dir "$BACKUP_DIR" \
    '{
      schema_version:$schema_version,
      command:"info",
      name:"jeff-clone-symlink-converter.sh",
      version:$version,
      ledger:$ledger,
      backup_dir:$backup_dir,
      purpose:"Convert one side of a (developer, jeff-corpus) clone pair into a symlink to the canonical side. Verifies origin+head match + zero dirty + tar-backup with byte-count tolerance before mutation. Receipt + symlink rollback path preserved.",
      subcommands:["doctor","health","validate","audit","why","repair","quickstart"],
      canonical_flags:["--info","--schema","--examples","--json","--apply","--dry-run","--idempotency-key","--pair","--canonical-side","--mode","--backup-dir"],
      capabilities:[
        "pair-existence-precheck",
        "origin-and-head-equality-check",
        "dirty-tree-rejection",
        "tar-backup-with-byte-count-tolerance",
        "atomic-move-then-symlink-create",
        "post-create-resolve-and-ls-and-git-verify",
        "receipt-with-tree-hash-and-byte-counts",
        "idempotency-key-required-for-apply"
      ],
      apply_supported:true,
      dry_run_supported:true,
      idempotency_key_required_for_apply:true,
      mutates_state:true,
      env_vars:["JEFF_CLONE_ROOT_BASE","JEFF_CLONE_CORPUS_BASE","JEFF_CLONE_LEDGER","JEFF_CLONE_FORCE_BYTE_MISMATCH","JEFF_CLONE_BYTE_TOLERANCE"],
      defaults:{canonical_side:"corpus",mode:"dry-run"},
      exit_codes:{"0":"success","1":"verify-fail","2":"safety-check-fail","3":"invalid-args-or-refused-apply-without-idempotency-key"}
    }'
}

emit_schema() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"schema",
    input_schema:{
      type:"object",
      required:["pair"],
      properties:{
        pair:{type:"string",description:"clone pair name (e.g., \"ntm\", \"beads_rust\"); must not contain / or ."},
        canonical_side:{enum:["root","corpus"],description:"which side becomes canonical (the other becomes the symlink)"},
        mode:{enum:["dry-run","apply"]},
        idempotency_key:{type:"string",description:"required with --mode apply"},
        backup_dir:{type:"string"}
      }
    },
    output_schema:{
      type:"object",
      required:["schema_version","status","pair"],
      properties:{
        schema_version:{const:"jeff-clone-symlink-receipt/v1"},
        status:{enum:["dry_run","applied","invalid_args","safety_check_failed","verify_failed"]},
        pair:{type:"string"},
        canonical_side:{enum:["root","corpus"]},
        canonical_path:{type:"string"},
        noncanonical_path:{type:"string"},
        backup_path:{type:"string"},
        receipt_path:{type:"string"},
        moved_path:{type:"string"},
        origin:{type:"string"},
        head:{type:"string"},
        original_tree_hash:{type:"string"},
        byte_counts:{
          type:"object",
          properties:{
            original_file_bytes:{type:"integer"},
            original_disk_bytes:{type:"integer"},
            archive_member_bytes:{type:"integer"}
          }
        },
        post_state:{
          type:"object",
          properties:{
            symlink:{type:"boolean"},
            verified:{type:"boolean"}
          }
        }
      }
    },
    exit_codes:{"0":"success","1":"verify-fail","2":"safety-check-fail","3":"invalid-args-or-refused-apply-without-idempotency-key"}
  }'
}

examples_text() {
  cat <<'EOF'
examples:
  jeff-clone-symlink-converter.sh --pair ntm --mode dry-run --json
  jeff-clone-symlink-converter.sh --pair ntm --canonical-side corpus --mode apply --idempotency-key clone-ntm-2026-05-11 --json
  jeff-clone-symlink-converter.sh doctor --json
  jeff-clone-symlink-converter.sh audit --json
EOF
}

examples_json() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"examples",
    examples:[
      {name:"dry-run-probe",invocation:"jeff-clone-symlink-converter.sh --pair ntm --mode dry-run --json",purpose:"compute would-convert receipt without writing tarball or moving the directory"},
      {name:"apply-corpus-canonical",invocation:"jeff-clone-symlink-converter.sh --pair ntm --canonical-side corpus --mode apply --idempotency-key clone-ntm-2026-05-11 --json",purpose:"make Developer/ntm a symlink to jeff-corpus/ntm; preserves origin+head equality; requires --idempotency-key"},
      {name:"apply-root-canonical",invocation:"jeff-clone-symlink-converter.sh --pair ntm --canonical-side root --mode apply --idempotency-key clone-ntm-2026-05-11 --json",purpose:"reverse: make jeff-corpus/ntm a symlink to Developer/ntm"},
      {name:"doctor",invocation:"jeff-clone-symlink-converter.sh doctor --json",purpose:"verify jq, git, tar, backup_dir writable, ledger writable"},
      {name:"audit",invocation:"jeff-clone-symlink-converter.sh audit --json",purpose:"tail recent conversion receipts"}
    ]
  }'
}

emit_canonical_doctor() {
  local ts; ts="$(now_iso)"
  local jq_status="pass"; command -v jq >/dev/null 2>&1 || jq_status="fail"
  local git_status="pass"; command -v git >/dev/null 2>&1 || git_status="fail"
  local tar_status="pass"; command -v tar >/dev/null 2>&1 || tar_status="fail"
  local backup_status="pass"
  local backup_dir_expanded="${BACKUP_DIR/#\~/$HOME}"
  if [[ -e "$backup_dir_expanded" ]]; then
    [[ -w "$backup_dir_expanded" ]] || backup_status="fail"
  else
    [[ -d "$(dirname "$backup_dir_expanded")" ]] || backup_status="warn"
  fi
  local ledger_dir; ledger_dir="$(dirname "$LEDGER")"
  local ledger_status="pass"
  if [[ -e "$LEDGER" ]]; then
    [[ -w "$LEDGER" ]] || ledger_status="fail"
  else
    [[ -d "$ledger_dir" ]] || ledger_status="warn"
  fi
  local corpus_status="pass"; [[ -d "$CORPUS_BASE" ]] || corpus_status="warn"
  local overall="pass"
  for s in "$jq_status" "$git_status" "$tar_status" "$backup_status" "$ledger_status" "$corpus_status"; do
    case "$s" in
      fail) overall="fail" ;;
      warn) [[ "$overall" == "pass" ]] && overall="warn" ;;
    esac
  done
  jq -nc --arg sv "$SCHEMA_VERSION.doctor" --arg ts "$ts" --arg overall "$overall" \
    --arg jq_s "$jq_status" --arg git_s "$git_status" --arg tar_s "$tar_status" \
    --arg backup_s "$backup_status" --arg backup_dir "$backup_dir_expanded" \
    --arg ledger_s "$ledger_status" --arg ledger "$LEDGER" \
    --arg corpus_s "$corpus_status" --arg corpus "$CORPUS_BASE" \
    '{
      schema_version:$sv,
      command:"doctor",
      ts:$ts,
      status:$overall,
      checks:[
        {name:"jq",status:$jq_s,detail:"jq required for envelope emission"},
        {name:"git",status:$git_s,detail:"git required for origin/head equality + dirty-tree checks"},
        {name:"tar",status:$tar_s,detail:"tar required for backup tarball"},
        {name:"backup_dir",status:$backup_s,path:$backup_dir,detail:"writable backup directory"},
        {name:"ledger_writable",status:$ledger_s,path:$ledger,detail:"append-only conversion ledger"},
        {name:"corpus_base",status:$corpus_s,path:$corpus,detail:"jeff-corpus base directory"}
      ]
    }'
}

emit_health() {
  local ts; ts="$(now_iso)"
  local row_count=0
  if [[ -r "$LEDGER" ]]; then
    row_count="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$row_count" ]] && row_count=0
  fi
  local backup_dir_expanded="${BACKUP_DIR/#\~/$HOME}"
  local backup_count=0
  if [[ -d "$backup_dir_expanded" ]]; then
    backup_count="$(find "$backup_dir_expanded" -maxdepth 1 -name '*.tar.gz' 2>/dev/null | wc -l | tr -d ' ')"
    [[ -z "$backup_count" ]] && backup_count=0
  fi
  jq -nc --arg sv "$SCHEMA_VERSION.health" --arg ts "$ts" \
    --arg ledger "$LEDGER" --argjson row_count "${row_count:-0}" \
    --arg backup_dir "$backup_dir_expanded" --argjson backup_count "${backup_count:-0}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:"pass",ledger:$ledger,ledger_row_count:$row_count,backup_dir:$backup_dir,backup_tarball_count:$backup_count}'
}

emit_canonical_validate() {
  local ts; ts="$(now_iso)"
  local rows=0 invalid=0
  if [[ -r "$LEDGER" ]]; then
    rows="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$rows" ]] && rows=0
    if [[ "$rows" -gt 0 ]]; then
      invalid="$(jq -c 'select((.schema_version // "") != "jeff-clone-symlink-receipt/v1")' "$LEDGER" 2>/dev/null | wc -l | tr -d ' ')"
      [[ -z "$invalid" ]] && invalid=0
    fi
  fi
  local status="pass"
  [[ "$invalid" -gt 0 ]] && status="violations"
  jq -nc --arg sv "$SCHEMA_VERSION.validate" --arg ts "$ts" --arg status "$status" \
    --argjson rows "${rows:-0}" --argjson invalid "${invalid:-0}" --arg ledger "$LEDGER" \
    '{schema_version:$sv,command:"validate",ts:$ts,status:$status,ledger:$ledger,row_count:$rows,invalid_row_count:$invalid,check:"every row has schema_version=jeff-clone-symlink-receipt/v1"}'
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
    ""|safety-checks)
      body='Six safety checks before mutation: (1) noncanonical path is not already a symlink, (2) canonical path is not a symlink, (3) both sides exist as directories, (4) both are git repos, (5) origin URLs match, (6) HEAD commits match. Plus dirty-tree rejection on both sides. Then tar-backup with byte-count tolerance before any move.'
      ;;
    rollback)
      body='Rollback: tarball at backup_path + moved original dir at moved_path. To revert: rm -f noncanonical_path (the symlink) && mv moved_path noncanonical_path. Receipt at receipt_path documents the conversion for forensics.'
      ;;
    canonical-side)
      body='--canonical-side corpus (default): Developer/PAIR becomes symlink to jeff-corpus/PAIR. --canonical-side root: jeff-corpus/PAIR becomes symlink to Developer/PAIR. Corpus-canonical is the doctrine default (source of truth lives in jeff-corpus).'
      ;;
    *)
      body="unknown topic: $topic. known: safety-checks, rollback, canonical-side"
      ;;
  esac
  jq -nc --arg sv "$SCHEMA_VERSION" --arg topic "${topic:-safety-checks}" --arg body "$body" \
    '{schema_version:$sv,command:"why",topic:$topic,body:$body}'
}

emit_quickstart() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"quickstart",
    status:"ok",
    steps:[
      {step:1,action:"check-doctor",command:"jeff-clone-symlink-converter.sh doctor --json"},
      {step:2,action:"dry-run-pair",command:"jeff-clone-symlink-converter.sh --pair ntm --mode dry-run --json"},
      {step:3,action:"apply-with-idem-key",command:"jeff-clone-symlink-converter.sh --pair ntm --mode apply --idempotency-key clone-ntm-$(date +%Y%m%d) --json"},
      {step:4,action:"tail-recent-conversions",command:"jeff-clone-symlink-converter.sh audit --json"}
    ],
    next_actions:["repeat-for-each-clone-pair","periodic-symlink-resolve-audit"]
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
      --help|-h) printf 'repair --scope <ledger-prime|backup-dir-prime> [--dry-run|--apply --idempotency-key KEY]\n'; exit 0 ;;
      "") shift ;;
      *) printf 'ERR: unknown repair arg %s\n' "$1" >&2; exit 2 ;;
    esac
  done
  if [[ -z "$scope" ]]; then
    printf '{"schema_version":"%s.repair","status":"refused","reason":"--scope required (ledger-prime|backup-dir-prime)","exit_code":2}\n' "$SCHEMA_VERSION"
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
    backup-dir-prime)
      local backup_dir_expanded="${BACKUP_DIR/#\~/$HOME}"
      local before_exists; before_exists="$([[ -d "$backup_dir_expanded" ]] && printf true || printf false)"
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$backup_dir_expanded" 2>/dev/null || true
      fi
      local after_exists; after_exists="$([[ -d "$backup_dir_expanded" ]] && printf true || printf false)"
      jq -nc --arg sv "$SCHEMA_VERSION.repair" --arg ts "$ts" --arg scope "$scope" --arg mode "$mode" \
        --arg path "$backup_dir_expanded" --arg key "$idem_key" \
        --argjson before "$before_exists" --argjson after "$after_exists" \
        '{schema_version:$sv,command:"repair",ts:$ts,status:"pass",scope:$scope,mode:$mode,idempotency_key:$key,backup_dir:$path,present_before:$before,present_after:$after}'
      ;;
    *)
      printf '{"schema_version":"%s.repair","status":"refused","scope":"%s","reason":"unknown scope; known: ledger-prime, backup-dir-prime","exit_code":2}\n' "$SCHEMA_VERSION" "$scope"
      exit 2
      ;;
  esac
}

# Canonical no-dash subcommand intercept BEFORE main arg parser.
case "${1:-}" in
  --schema) emit_schema; exit 0 ;;
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

norm_origin() {
  git -C "$1" config --get remote.origin.url 2>/dev/null | sed 's/[.]git$//'
}

git_head() {
  git -C "$1" rev-parse HEAD 2>/dev/null
}

dirty() {
  [[ -n "$(git -C "$1" status --porcelain 2>/dev/null)" ]]
}

dir_file_bytes() {
  find -P "$1" -type f -exec stat -f %z {} + 2>/dev/null | awk '{s+=$1} END{print s+0}'
}

dir_disk_bytes() {
  du -sk "$1" 2>/dev/null | awk '{print $1 * 1024}'
}

archive_member_bytes() {
  tar -tvzf "$1" 2>/dev/null | awk '{s+=$5} END{print s+0}'
}

tree_hash() {
  (cd "$1" && find . -type f -print0 | sort -z | while IFS= read -r -d '' f; do
    shasum -a 256 "$f"
  done) | shasum -a 256 | awk '{print $1}'
}

valid_pair() {
  [[ -n "$PAIR" && "$PAIR" != .* && "$PAIR" != *"/"* && "$PAIR" != ".." ]]
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pair) [[ -n "${2:-}" ]] || fail_json invalid_args missing_pair_value 3; PAIR="$2"; shift 2 ;;
    --canonical-side) [[ -n "${2:-}" ]] || fail_json invalid_args missing_canonical_side 3; CANONICAL_SIDE="$2"; shift 2 ;;
    --mode) [[ -n "${2:-}" ]] || fail_json invalid_args missing_mode 3; MODE="$2"; shift 2 ;;
    --backup-dir) [[ -n "${2:-}" ]] || fail_json invalid_args missing_backup_dir 3; BACKUP_DIR="$2"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --info) info; exit 0 ;;
    --schema) emit_schema; exit 0 ;;
    --examples)
      shift
      if [[ "${1:-}" == "--json" ]]; then examples_json; else examples_text; fi
      exit 0
      ;;
    --idempotency-key) [[ -n "${2:-}" ]] || fail_json invalid_args missing_idempotency_key_value 3; IDEMPOTENCY_KEY="$2"; shift 2 ;;
    --idempotency-key=*) IDEMPOTENCY_KEY="${1#--idempotency-key=}"; shift ;;
    --apply) MODE="apply"; shift ;;
    --dry-run) MODE="dry-run"; shift ;;
    --help|-h) usage; exit 0 ;;
    *) fail_json invalid_args "unknown_arg:$1" 3 ;;
  esac
done

case "$CANONICAL_SIDE" in root|corpus) ;; *) fail_json invalid_args invalid_canonical_side 3 ;; esac
case "$MODE" in dry-run|apply) ;; *) fail_json invalid_args invalid_mode 3 ;; esac
# Canonical apply contract: --mode apply requires --idempotency-key.
if [[ "$MODE" == "apply" && -z "$IDEMPOTENCY_KEY" ]]; then
  printf '{"schema_version":"%s","status":"refused","mode":"apply","reason":"--mode apply (or --apply) requires --idempotency-key","exit_code":3}\n' "$SCHEMA_VERSION"
  exit 3
fi
valid_pair || fail_json invalid_args invalid_pair 3

ROOT_PATH="$ROOT_BASE/$PAIR"
CORPUS_PATH="$CORPUS_BASE/$PAIR"
if [[ "$CANONICAL_SIDE" == "corpus" ]]; then
  CANONICAL_PATH="$CORPUS_PATH"; NONCANONICAL_PATH="$ROOT_PATH"
else
  CANONICAL_PATH="$ROOT_PATH"; NONCANONICAL_PATH="$CORPUS_PATH"
fi

[[ ! -L "$NONCANONICAL_PATH" ]] || fail_json safety_check_failed noncanonical_already_symlink 2
[[ ! -L "$CANONICAL_PATH" ]] || fail_json safety_check_failed canonical_is_symlink 2
[[ -d "$ROOT_PATH" && -d "$CORPUS_PATH" ]] || fail_json safety_check_failed missing_pair_path 2
git -C "$ROOT_PATH" rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail_json safety_check_failed root_not_git_repo 2
git -C "$CORPUS_PATH" rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail_json safety_check_failed corpus_not_git_repo 2

root_origin="$(norm_origin "$ROOT_PATH")"
corpus_origin="$(norm_origin "$CORPUS_PATH")"
[[ -n "$root_origin" && "$root_origin" == "$corpus_origin" ]] || fail_json safety_check_failed origin_mismatch 2
root_head="$(git_head "$ROOT_PATH")"
corpus_head="$(git_head "$CORPUS_PATH")"
[[ -n "$root_head" && "$root_head" == "$corpus_head" ]] || fail_json safety_check_failed commit_mismatch 2
dirty "$ROOT_PATH" && fail_json safety_check_failed root_dirty 2
dirty "$CORPUS_PATH" && fail_json safety_check_failed corpus_dirty 2

ts="$(date -u +%Y%m%dT%H%M%SZ)"
backup_dir_expanded="${BACKUP_DIR/#\~/$HOME}"
backup_path="$backup_dir_expanded/$PAIR-$ts.tar.gz"
receipt_path="$backup_dir_expanded/$PAIR-$ts.receipt.json"
moved_path="$backup_dir_expanded/$PAIR-$ts.original-dir"
orig_file_bytes="$(dir_file_bytes "$NONCANONICAL_PATH")"
orig_disk_bytes="$(dir_disk_bytes "$NONCANONICAL_PATH")"
orig_tree_hash="$(tree_hash "$NONCANONICAL_PATH")"

base_receipt() {
  jq -nc \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg version "$VERSION" \
    --arg ts "$ts" \
    --arg pair "$PAIR" \
    --arg canonical_side "$CANONICAL_SIDE" \
    --arg canonical_path "$CANONICAL_PATH" \
    --arg noncanonical_path "$NONCANONICAL_PATH" \
    --arg backup_path "$backup_path" \
    --arg receipt_path "$receipt_path" \
    --arg moved_path "$moved_path" \
    --arg origin "$root_origin" \
    --arg head "$root_head" \
    --arg tree_hash "$orig_tree_hash" \
    --argjson file_bytes "$orig_file_bytes" \
    --argjson disk_bytes "$orig_disk_bytes" \
    '{schema_version:$schema_version,version:$version,ts:$ts,pair:$pair,canonical_side:$canonical_side,canonical_path:$canonical_path,noncanonical_path:$noncanonical_path,backup_path:$backup_path,receipt_path:$receipt_path,moved_path:$moved_path,origin:$origin,head:$head,byte_counts:{original_file_bytes:$file_bytes,original_disk_bytes:$disk_bytes},original_tree_hash:$tree_hash}'
}

if [[ "$MODE" == "dry-run" ]]; then
  emit "$(base_receipt | jq '. + {status:"dry_run",would_convert:true}')"
  exit 0
fi

mkdir -p "$backup_dir_expanded" || fail_json verify_failed backup_dir_unwritable 1
[[ ! -e "$backup_path" && ! -e "$receipt_path" && ! -e "$moved_path" ]] || fail_json verify_failed backup_collision 1
tar -czf "$backup_path" -C "$(dirname "$NONCANONICAL_PATH")" "$(basename "$NONCANONICAL_PATH")" || fail_json verify_failed backup_tar_failed 1
archive_bytes="$(archive_member_bytes "$backup_path")"
if [[ "${JEFF_CLONE_FORCE_BYTE_MISMATCH:-0}" == "1" ]]; then archive_bytes=0; fi
tolerance="${JEFF_CLONE_BYTE_TOLERANCE:-0}"
if [[ "$archive_bytes" -lt $((orig_file_bytes - tolerance)) ]]; then
  fail_json verify_failed backup_byte_count_mismatch 1
fi

mv "$NONCANONICAL_PATH" "$moved_path" || fail_json verify_failed move_original_failed 1
ln -s "$CANONICAL_PATH" "$NONCANONICAL_PATH" || fail_json verify_failed symlink_create_failed 1
resolved="$(cd "$(dirname "$NONCANONICAL_PATH")" && cd "$(basename "$NONCANONICAL_PATH")" && pwd -P 2>/dev/null)" || fail_json verify_failed symlink_unresolvable 1
expected="$(cd "$CANONICAL_PATH" && pwd -P)" || fail_json verify_failed canonical_unresolvable 1
[[ "$resolved" == "$expected" ]] || fail_json verify_failed symlink_wrong_target 1
ls "$NONCANONICAL_PATH" >/dev/null 2>&1 || fail_json verify_failed ls_failed 1
git -C "$NONCANONICAL_PATH" rev-parse HEAD >/dev/null 2>&1 || fail_json verify_failed git_failed_after_symlink 1

receipt="$(base_receipt | jq \
  --argjson archive_bytes "$archive_bytes" \
  '. + {status:"applied",byte_counts:(.byte_counts + {archive_member_bytes:$archive_bytes}),post_state:{symlink:true,verified:true}}')"
printf '%s\n' "$receipt" >"$receipt_path" || fail_json verify_failed receipt_write_failed 1
emit "$receipt"
