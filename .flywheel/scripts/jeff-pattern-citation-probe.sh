#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial -> passing per bead flywheel-k8gcv.18)
set -euo pipefail

VERSION="jeff-pattern-citation-probe.v1.1.0"
SCHEMA_VERSION="jeff-pattern-citation/v1"
LEDGER="${JEFF_PATTERN_CITATION_LEDGER:-$HOME/.local/state/flywheel/jeff-pattern-citation-probe-ledger.jsonl}"
REPO="/Users/josh/Developer/flywheel"
JSON_OUT=0
DOCTOR=0
PATHS=()

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

usage() {
  cat <<'EOF'
usage: jeff-pattern-citation-probe.sh [--repo PATH] [--json] [--doctor] [PATH ...]

Validates Jeff-originated pattern claims. Any doctrine, skill draft, or plan
line that imports/adopts a Jeff pattern must include:

  Source: Jeff <repo>:<file>:<line> + ZestStream adaptation
EOF
}

info() {
  jq -nc --arg sv "$SCHEMA_VERSION" --arg version "$VERSION" --arg ledger "$LEDGER" '{
    schema_version:$sv,
    command:"info",
    name:"jeff-pattern-citation-probe.sh",
    version:$version,
    ledger:$ledger,
    purpose:"Require file-line evidence before importing Jeff-originated patterns into flywheel doctrine, skills, or plans",
    signal:"jeff_pattern_uncited_count",
    required_citation:"Source: Jeff <repo>:<file>:<line> + ZestStream adaptation",
    owner_bead:"flywheel-jhcd",
    subcommands:["doctor","health","validate","audit","why","repair","quickstart"],
    canonical_flags:["--info","--schema","--examples","--json","--apply","--dry-run","--idempotency-key","--doctor","--repo"],
    capabilities:[
      "uncited-jeff-pattern-detection",
      "file-line-evidence-requirement",
      "doctrine-skills-plans-scan-target",
      "L64-to-L56-promotion-path",
      "doctor-mode-zero-exit-with-count-signal"
    ],
    apply_supported:false,
    dry_run_supported:false,
    idempotency_key_required_for_apply:false,
    mutates_state:false,
    env_vars:["JEFF_PATTERN_CITATION_LEDGER"],
    exit_codes:{"0":"pass","1":"uncited-found","64":"bad-args"}
  }'
}

schema() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"schema",
    input_schema:{
      type:"object",
      properties:{
        repo:{type:"string",description:"flywheel repo root"},
        paths:{type:"array",items:{type:"string"},description:"explicit paths to scan; default = doctrine/skills/plans dirs"},
        doctor:{type:"boolean",description:"emit doctor envelope (always exit 0 with count signal)"}
      }
    },
    output_schema:{
      type:"object",
      required:["schema_version","status"],
      properties:{
        schema_version:{const:"jeff-pattern-citation/v1"},
        status:{enum:["pass","fail"]},
        jeff_pattern_uncited_count:{type:"integer",minimum:0},
        files_checked:{type:"integer",minimum:0},
        repo:{type:"string"},
        rows:{
          type:"array",
          items:{
            type:"object",
            required:["file","line","reason","text"],
            properties:{
              file:{type:"string"},
              line:{type:"integer",minimum:1},
              reason:{type:"string"},
              text:{type:"string"}
            }
          }
        }
      }
    },
    fields:["status","jeff_pattern_uncited_count","files_checked","rows"],
    row_fields:["file","line","reason","text"],
    status_values:["pass","fail"],
    doctor_mode:"exits zero and exposes jeff_pattern_uncited_count",
    exit_codes:{"0":"pass","1":"uncited-found","64":"bad-args"}
  }'
}

examples() {
  cat <<'EOF'
jeff-pattern-citation-probe.sh --json
jeff-pattern-citation-probe.sh --doctor --json
jeff-pattern-citation-probe.sh --json tests/fixtures/jeff-pattern-citation/valid.md
jeff-pattern-citation-probe.sh doctor --json
jeff-pattern-citation-probe.sh audit --json
EOF
}

examples_json() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"examples",
    examples:[
      {name:"default-scan",invocation:"jeff-pattern-citation-probe.sh --json",purpose:"scan doctrine/skills/plans for uncited Jeff pattern claims; exit 1 if any found"},
      {name:"doctor-flag-mode",invocation:"jeff-pattern-citation-probe.sh --doctor --json",purpose:"doctor mode: always exit 0, expose jeff_pattern_uncited_count for substrate consumers"},
      {name:"scan-specific-file",invocation:"jeff-pattern-citation-probe.sh --json tests/fixtures/jeff-pattern-citation/valid.md",purpose:"scan only the given paths instead of default scan set"},
      {name:"canonical-doctor",invocation:"jeff-pattern-citation-probe.sh doctor --json",purpose:"canonical doctor envelope with .checks shape"},
      {name:"audit",invocation:"jeff-pattern-citation-probe.sh audit --json",purpose:"tail recent probe ledger rows"}
    ]
  }'
}

emit_canonical_doctor() {
  local ts; ts="$(now_iso)"
  local jq_status="pass"; command -v jq >/dev/null 2>&1 || jq_status="fail"
  local repo_status="pass"; [[ -d "$REPO" ]] || repo_status="fail"
  local ledger_dir; ledger_dir="$(dirname "$LEDGER")"
  local ledger_status="pass"
  if [[ -e "$LEDGER" ]]; then
    [[ -w "$LEDGER" ]] || ledger_status="fail"
  else
    [[ -d "$ledger_dir" ]] || ledger_status="warn"
  fi
  local overall="pass"
  for s in "$jq_status" "$repo_status" "$ledger_status"; do
    case "$s" in
      fail) overall="fail" ;;
      warn) [[ "$overall" == "pass" ]] && overall="warn" ;;
    esac
  done
  jq -nc --arg sv "$SCHEMA_VERSION.doctor" --arg ts "$ts" --arg overall "$overall" \
    --arg jq_s "$jq_status" --arg repo_s "$repo_status" --arg repo "$REPO" \
    --arg ledger_s "$ledger_status" --arg ledger "$LEDGER" \
    '{
      schema_version:$sv,
      command:"doctor",
      ts:$ts,
      status:$overall,
      checks:[
        {name:"jq",status:$jq_s,detail:"jq required for envelope emission"},
        {name:"repo_dir",status:$repo_s,path:$repo,detail:"flywheel repo for scanning doctrine/skills/plans"},
        {name:"ledger_writable",status:$ledger_s,path:$ledger,detail:"append-only probe ledger"}
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
  jq -nc --arg sv "$SCHEMA_VERSION.health" --arg ts "$ts" \
    --arg ledger "$LEDGER" --argjson row_count "${row_count:-0}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:"pass",ledger:$ledger,ledger_row_count:$row_count}'
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
    '{schema_version:$sv,command:"validate",ts:$ts,status:$status,ledger:$ledger,row_count:$rows,invalid_row_count:$invalid,check:"every row has non-empty schema_version"}'
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
    ""|citation-requirement)
      body='Jeff-originated patterns imported into ZestStream substrate MUST cite the source: "Source: Jeff <repo>:<file>:<line> + ZestStream adaptation". This prevents pattern smuggling (lifting Jeff doctrine without attribution + adaptation notes) and supports the L64→L56 promotion path: surfaces flag uncited rows → flywheel triages → bead update OR adaptation receipt.'
      ;;
    L64-L56-promotion)
      body='Promotion path: L64 (uncited Jeff pattern detected) → triaged manually or by orchestrator → either (a) bead opened to add citation + adaptation, or (b) row marked as ZestStream-original (no Jeff lineage). After triage, L56 (citation present + adaptation noted) replaces the L64 signal in the ledger.'
      ;;
    doctor-mode-zero-exit)
      body='--doctor mode always exits 0 (vs default --json mode which exits 1 if any uncited rows exist). This is so flywheel-loop doctor probes can read jeff_pattern_uncited_count signal without false-firing on the global doctor surface. Mutating consumers should use default mode.'
      ;;
    *)
      body="unknown topic: $topic. known: citation-requirement, L64-L56-promotion, doctor-mode-zero-exit"
      ;;
  esac
  jq -nc --arg sv "$SCHEMA_VERSION" --arg topic "${topic:-citation-requirement}" --arg body "$body" \
    '{schema_version:$sv,command:"why",topic:$topic,body:$body}'
}

emit_quickstart() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"quickstart",
    status:"ok",
    steps:[
      {step:1,action:"check-doctor",command:"jeff-pattern-citation-probe.sh doctor --json"},
      {step:2,action:"scan-default",command:"jeff-pattern-citation-probe.sh --json"},
      {step:3,action:"interpret-uncited",command:"jq .rows"},
      {step:4,action:"audit-recent",command:"jeff-pattern-citation-probe.sh audit --json"}
    ],
    next_actions:["fix-citation-or-mark-as-zeststream-original","tail-ledger-via-audit"]
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

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="${2:?}"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --doctor) DOCTOR=1; JSON_OUT=1; shift ;;
    --schema) schema; exit 0 ;;
    --info) info; exit 0 ;;
    --examples)
      shift
      if [[ "${1:-}" == "--json" ]]; then examples_json; else examples; fi
      exit 0
      ;;
    --version) printf '%s\n' "jeff-pattern-citation-probe 1.0.0"; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    --) shift; break ;;
    -*) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
    *) PATHS+=("$1"); shift ;;
  esac
done
while [[ $# -gt 0 ]]; do
  PATHS+=("$1")
  shift
done

claim_line() {
  local line="$1" lower
  lower="$(printf '%s' "$line" | tr '[:upper:]' '[:lower:]')"
  [[ "$lower" =~ (jeff|dicklesworthstone) ]] || return 1
  # Existing whitelist of self-referential / canonical-mentor tokens.
  [[ "$lower" =~ (jeff-pattern-citation|jeff_pattern_uncited_count|feedback_meadows_jeff_mentors|reference_dicklesworthstone|dicklesworthstone-stack) ]] && return 1
  [[ "$line" == *"Source: Jeff <repo>:<file>:<line> + ZestStream adaptation"* ]] && return 1
  # bead flywheel-4rmc approved exclusion classes:
  #   1. Markdown section headers — they introduce a block; the
  #      citation is on a separate line within the block. Header
  #      lines themselves are metadata, not claims.
  #   2. Sanitized historical excerpts in MISSION.md / receipts /
  #      audit packs — these capture past state (e.g.
  #      `**sanitized_excerpt:** "...jeff_patterns_adopted=N..."`)
  #      and are not new pattern claims.
  #   3. References to Jeff-DERIVED SKILLS (`jeff-convergence-audit`,
  #      `jeff-issue-chain`, `jeff-corpus`, `jeff-intel`, etc.) when
  #      they appear as the substrate name rather than a pattern
  #      adopted from Jeff source. These are skill citations, not
  #      pattern imports.
  # See .flywheel/audit/flywheel-4rmc/compliance-pack.md for the
  # full rationale and approved-exclusion fixture.
  [[ "$line" =~ ^\#+[[:space:]] ]] && return 1
  [[ "$lower" == *"sanitized_excerpt:"* ]] && return 1
  [[ "$lower" =~ jeff-(convergence-audit|issue-chain|corpus|intel|substrate|clone-backups|patterns?|swarm-ops|status|philosophy)[[:space:]]+(phase|skill|directory|tool|loop|tracker|substrate) ]] && return 1
  [[ "$lower" == *"jeff-convergence-audit "* || "$lower" == *"jeff-convergence-audit."* || "$lower" == *"jeff-issue-chain "* || "$lower" == *"jeff-issue-chain."* ]] && return 1
  [[ "$lower" =~ (source:[[:space:]]*jeff|inspired[[:space:]]+by[[:space:]]+jeff|jeff[^[:alnum:]]+(pattern|method|doctrine|skill|origin|originated|mentor|style|prior[[:space:]]+art)|dicklesworthstone[^[:alnum:]]+(pattern|method|doctrine|origin|originated)|adopt[^[:alnum:]]+.*jeff|adapt[^[:alnum:]]+.*jeff|learn[^[:alnum:]]+.*jeff|jeff-originated) ]]
}

valid_citation() {
  local line="$1"
  # Canonical prose shape (per bead body):
  #   "Source: Jeff <repo>:<file>:<line> + ZestStream adaptation"
  if [[ "$line" =~ Source:[[:space:]]Jeff[[:space:]][^[:space:]:]+:[^[:space:]]+:[0-9]+[[:space:]]\+[[:space:]]ZestStream[[:space:]]adaptation ]]; then
    return 0
  fi
  # Alternative structured-key shape adopted in wire-or-explain plan
  # outputs (bead flywheel-4rmc approved exclusion class — see
  # .flywheel/audit/flywheel-4rmc/compliance-pack.md). Lines that
  # carry an explicit `jeff_evidence_path=<path>:<line-or-range>`
  # are properly cited in machine-readable form even when they
  # don't use the prose shape.
  if [[ "$line" =~ jeff_evidence_path=\`?[^[:space:]\`]+:[0-9]+(-[0-9]+)?\`? ]]; then
    return 0
  fi
  return 1
}

relative_path() {
  local path="$1"
  case "$path" in
    "$REPO"/*) printf '%s\n' "${path#"$REPO"/}" ;;
    *) printf '%s\n' "$path" ;;
  esac
}

collect_default_paths() {
  local p
  for p in "$REPO/AGENTS.md" "$REPO/README.md" "$REPO/.flywheel/AGENTS.md" "$REPO/.flywheel/MISSION.md"; do
    [[ -f "$p" ]] && printf '%s\n' "$p"
  done
  # Walk PLANS (canonical uppercase) and doctrine. Skip the lowercase
  # `.flywheel/plans/` duplicate when both trees exist with identical
  # content — every hit there is already counted under PLANS, so the
  # walk would otherwise double-count. This is one of the
  # bead flywheel-4rmc approved exclusion classes; see
  # .flywheel/audit/flywheel-4rmc/compliance-pack.md for the
  # rationale + fixture.
  for p in "$REPO/.flywheel/PLANS" "$REPO/.flywheel/doctrine"; do
    [[ -d "$p" ]] && find "$p" -type f -name '*.md' -print
  done
  if [[ -d "$REPO/.flywheel/plans" && ! -d "$REPO/.flywheel/PLANS" ]]; then
    find "$REPO/.flywheel/plans" -type f -name '*.md' -print
  fi
}

tmp_files="$(mktemp "${TMPDIR:-/tmp}/jeff-pattern-files.XXXXXX")"
tmp_rows="$(mktemp "${TMPDIR:-/tmp}/jeff-pattern-rows.XXXXXX")"
trap 'rm -f "$tmp_files" "$tmp_rows"' EXIT
: >"$tmp_rows"

if [[ "${#PATHS[@]}" -gt 0 ]]; then
  for p in "${PATHS[@]}"; do
    [[ -f "$p" ]] && printf '%s\n' "$p" >>"$tmp_files"
  done
else
  collect_default_paths | sort -u >"$tmp_files"
fi

files_checked=0
while IFS= read -r file; do
  [[ -f "$file" ]] || continue
  files_checked=$((files_checked + 1))
  set +e
  hits="$(rg -n -i --color never 'jeff|dicklesworthstone' "$file" 2>/dev/null)"
  hit_rc=$?
  set -e
  [[ "$hit_rc" -eq 0 ]] || continue
  while IFS= read -r hit || [[ -n "$hit" ]]; do
    line_no="${hit%%:*}"
    line="${hit#*:}"
    if claim_line "$line" && ! valid_citation "$line"; then
      rel="$(relative_path "$file")"
      jq -nc \
        --arg file "$rel" \
        --argjson line "$line_no" \
        --arg reason "missing_jeff_file_line_source" \
        --arg text "$line" \
        '{file:$file,line:$line,reason:$reason,text:$text}' >>"$tmp_rows"
    fi
  done <<<"$hits"
done <"$tmp_files"

uncited_count="$(jq -s 'length' "$tmp_rows")"
status="pass"
if [[ "$uncited_count" -gt 0 ]]; then
  status="fail"
fi

result="$(jq -nc \
  --arg schema_version "jeff-pattern-citation/v1" \
  --arg status "$status" \
  --arg repo "$REPO" \
  --argjson files_checked "$files_checked" \
  --argjson count "$uncited_count" \
  --slurpfile rows "$tmp_rows" \
  '{
    schema_version:$schema_version,
    status:$status,
    repo:$repo,
    files_checked:$files_checked,
    jeff_pattern_uncited_count:$count,
    rows:$rows,
    signals:[{
      name:"jeff_pattern_uncited_count",
      producer:"jeff-pattern-citation-probe.sh",
      measurement:"Jeff-originated pattern claims missing Source: Jeff <repo>:<file>:<line> + ZestStream adaptation",
      consumer:"worker closeout / flywheel-loop doctor-equivalent probe",
      promotion_path:"L64 -> L56 -> bead update for uncited Jeff imports"
    }]
  }')"

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$result"
else
  jq -r '"status=\(.status) jeff_pattern_uncited_count=\(.jeff_pattern_uncited_count) files_checked=\(.files_checked)"' <<<"$result"
  jq -r '.rows[]? | "\(.file):\(.line): \(.reason): \(.text)"' <<<"$result"
fi

if [[ "$DOCTOR" -eq 1 ]]; then
  exit 0
fi
[[ "$status" == "pass" ]]

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
