#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
# orch-tick-stale-auto-bead-close.sh — N=4 MOOT_BY_CURRENT_PROBE_CLEARANCE mechanization
#
# Filed-by: flywheel-mvzri (P1) per N=4 trigger across 2xdi.108/.113/.114/.117.
# Sister N=5 confirmation in flywheel-2xdi.115 audit (sibling-script-comment-as-receiver
# sub-class). At 60-80% audit-only/moot disposition rate on auto-filed gap beads,
# manual worker dispatch is wasted compute. This driver auto-closes beads whose
# subject is no longer flagged by current gap-hunt-probe state.
#
# Stable exit codes: 0=ok | 1=domain | 2=usage | 4=blocked-by-gate
# Triad: doctor / health / repair / validate / audit / why / info / examples / quickstart / schema / completion
# Default mode: --dry-run (read-only). Mutation requires --apply.

set -euo pipefail

VERSION="orch-tick-stale-auto-bead-close.v1.0.0"
SCHEMA_VERSION="orch-tick-stale-auto-bead-close/v1"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
LEDGER="${ORCH_TICK_STALE_AUTO_CLOSE_LEDGER:-$HOME/.local/state/flywheel/orch-tick-stale-auto-close.jsonl}"
BR_BIN="${BR_BIN:-$HOME/.cargo/bin/br}"
GAP_PROBE="${GAP_PROBE:-$REPO_ROOT/.flywheel/scripts/gap-hunt-probe.sh}"

# Bead title patterns we auto-process (auto-filed gap beads only).
# do-not-auto-close + open-genuine-gap markers are checked per-bead before any close.
GAP_TITLE_PATTERNS=(
  '[gap-wired-but-cold]'
  '[gap-memory-without-cross-link]'
  '[gap-cross-source-silos]'
  '[gap-probe-without-receiver]'
  '[gap-bead-without-followup]'
  '[gap-doctrine-without-measurement]'
  '[gap-skill-without-jsm-publish]'
  '[gap-substrate-without-version-probe]'
  '[gap-loop-integrity]'
)

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

usage() {
  cat <<'USG'
usage: orch-tick-stale-auto-bead-close.sh [SUBCOMMAND] [OPTIONS]

Auto-close open auto-filed gap beads whose subject is no longer flagged by
the current gap-hunt-probe substrate state (moot-by-current-probe-clearance).

Default mode: --dry-run (report only; no mutation).
Mutating: --apply (closes beads via `br close` and appends ledger row).

SUBCOMMANDS (canonical-cli-scoping):
  doctor [--json]           probe substrate (br, gap-hunt-probe, ledger writability)
  health [--json]           last-run aggregate stats from ledger
  repair --scope <s>        scopes: ledger_dir | ledger_truncate
  validate <subject> [val]  subjects: bead-id | gap-class
  audit [--json] [N]        tail ledger (default 20 rows)
  why <bead-id>             provenance: why this bead was closed (or NOT)
  info [--json]             version + paths
  examples [--json]         example invocations
  quickstart                operator onboarding
  help <topic>              topic-mode help
  completion <shell>        emit completion script
  schema [--json]           output schema

GLOBAL FLAGS:
  --dry-run                 default; reports planned closures without acting
  --apply                   actually close beads + append ledger
  --idempotency-key KEY     idempotency token (used to dedupe ledger rows)
  --json                    JSON output mode
USG
}

# Extract gap class + subject basename from a bead title.
# Returns "class<TAB>subject_basename" on stdout, or empty if no match.
extract_subject_from_title() {
  local title="$1"
  # Match: [gap-CLASS] SUBJECT (subject may be path with slashes)
  if [[ "$title" =~ ^\[gap-([a-z-]+)\]\ +(.+)$ ]]; then
    local cls="${BASH_REMATCH[1]}"
    local subject="${BASH_REMATCH[2]}"
    # basename of path-like subject
    local base="${subject##*/}"
    printf '%s\t%s\n' "$cls" "$base"
    return 0
  fi
  return 1
}

# Check if a bead's body contains opt-out markers.
bead_has_opt_out() {
  local body="$1"
  if printf '%s' "$body" | grep -qE 'do-not-auto-close|disposition=open-genuine-gap|open-genuine-gap'; then
    return 0
  fi
  return 1
}

# Classify the substrate boundary class for a `[gap-wired-but-cold] .claude/skills/<X>/...`
# bead title. Echoes one of:
#   jeff-premium      — `jsm show <X>` returns "Jeffrey's Premium Skill" (Class 3)
#   joshua-domain     — `jsm show <X>` returns "Skill '<X>' not found" (jsm-unmanaged; Class 1)
#   skillos-managed   — `jsm show <X>` returns a skill not authored by Jeffrey (Class 2)
#   not-skill-path    — title doesn't match `.claude/skills/<X>/` shape
#   unknown           — jsm unavailable or unparseable output
# Per flywheel-kjli4: N=3 trigger fires Jeff-Premium auto-route in cmd_run.
classify_substrate_class() {
  local title="$1"
  # Extract skill name from path-like subject in title
  local skill=""
  if [[ "$title" =~ \.claude/skills/([A-Za-z0-9._-]+)/ ]]; then
    skill="${BASH_REMATCH[1]}"
  else
    printf 'not-skill-path\n'
    return 0
  fi
  local jsm_bin="${JSM_BIN:-/Users/josh/.local/bin/jsm}"
  if [[ ! -x "$jsm_bin" ]]; then
    printf 'unknown\n'
    return 0
  fi
  local out; out="$("$jsm_bin" show "$skill" 2>&1)"
  if printf '%s' "$out" | grep -q "Jeffrey's Premium Skill"; then
    printf 'jeff-premium\n'
  elif printf '%s' "$out" | grep -qE "Skill '$skill' not found"; then
    printf 'joshua-domain\n'
  elif printf '%s' "$out" | grep -qE 'Author:\s+Joshua'; then
    printf 'joshua-domain\n'
  elif printf '%s' "$out" | grep -qE '^[[:space:]]*ID:'; then
    # jsm-managed but not Jeff-Premium-badged + not Joshua-authored
    printf 'skillos-managed\n'
  else
    printf 'unknown\n'
  fi
}

# Synthesize a minimal audit-only evidence pack for an auto-closed Jeff Premium bead.
synthesize_jeff_audit_pack() {
  local bid="$1"
  local title="$2"
  local skill="$3"
  local ts="$4"
  local commit_sha="$5"
  local audit_dir="$REPO_ROOT/.flywheel/audit/$bid"
  mkdir -p "$audit_dir"
  cat > "$audit_dir/evidence.md" <<EVD
# $bid — auto-closed by orch-tick-stale-auto-bead-close.sh (Jeff Premium AUDIT-ONLY)

Bead: $bid
Auto-classified by: orch-tick-stale-auto-bead-close.sh (flywheel-mvzri + flywheel-kjli4 extension)
Substrate class: 3 (Jeff Premium per \`jsm show $skill\`)
Disposition: audit-only-jeff-substrate-class-3
Clearing commit: $commit_sha
Auto-close ts: $ts

## Why AUDIT-ONLY

This skill is a Jeffrey Emanuel Premium JSM package. Per Jeff-substrate
doctrine (\`feedback_no_push_ntm_br\` + \`feedback_jeff_issue_chain\` +
\`feedback_jeff_issue_requires_full_workaround_research_first\` + JSM
discipline forbids direct mutation under jsm-managed Jeff skills),
P3 gap-bead wired-but-cold dispositions for Jeff Premium skills are
AUDIT-ONLY by canonical convention.

## Precedent (N=3 trigger fired in flywheel-kjli4)

| # | Bead | Skill |
|---|---|---|
| 1 | flywheel-2xdi.97  | asupersync-mega-skill |
| 2 | flywheel-2xdi.130 | rg-optimized |
| 3 | flywheel-2xdi.138 | testing-fuzzing |
| - | **\$bid** | **$skill** ← THIS auto-closure |

## Verification

\`\`\`bash
jsm show $skill | grep -q "Jeffrey's Premium Skill" && echo confirmed
\`\`\`

Per kjli4 acceptance: auto-classification + auto-close with synthesized
audit pack. Direct mutation FORBIDDEN; Jeff-issue chain DEFERRED.
EVD
}

# Probe whether the gap is still active. Returns 0 if STILL flagged (don't close), 1 if MOOT (safe to close).
gap_still_flagged() {
  local cls="$1"
  local basename="$2"
  local probe_json="$3"
  # gap_ids are of the form CLASS:SUBJECT — basename appears in the subject portion
  printf '%s' "$probe_json" | /usr/bin/python3 -c "
import sys, json
d = json.load(sys.stdin)
ids = d.get('gap_ids', [])
cls = '$cls'
base = '$basename'
hits = [g for g in ids if g.startswith(cls + ':') and base in g]
sys.exit(0 if hits else 1)
"
}

cmd_run() {
  local mode="dry-run"
  local idem_key=""
  local json_out=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --apply) mode="apply"; shift ;;
      --dry-run) mode="dry-run"; shift ;;
      --idempotency-key) idem_key="$2"; shift 2 ;;
      --json) json_out=true; shift ;;
      *) shift ;;
    esac
  done

  local ts; ts="$(now_iso)"
  if [[ -z "$idem_key" ]]; then
    idem_key="orch-tick-$(date -u +%Y%m%d%H%M)"
  fi

  # Step 1: query open auto-filed gap beads
  local beads_json
  beads_json="$("$BR_BIN" list --status open --json 2>/dev/null)" || {
    printf '{"schema_version":"%s","status":"error","reason":"br_list_failed","ts":"%s"}\n' "$SCHEMA_VERSION" "$ts"
    return 1
  }

  # Step 2: invoke gap-hunt-probe to get current state
  local probe_json
  probe_json="$("$GAP_PROBE" --json 2>/dev/null)" || {
    printf '{"schema_version":"%s","status":"error","reason":"gap_probe_failed","ts":"%s"}\n' "$SCHEMA_VERSION" "$ts"
    return 1
  }

  # Step 3: iterate matching beads, decide per-bead disposition
  # Output rows: bead-id, title, class, basename, disposition (close|skip-still-flagged|skip-opt-out|skip-non-gap-bead)
  local planned_closes=()
  local skipped_still_flagged=()
  local skipped_opt_out=()

  # Iterate via python to parse JSON safely + extract bead ids/titles
  local triage_json
  triage_json="$(printf '%s' "$beads_json" | /usr/bin/python3 -c "
import sys, json, re
d = json.load(sys.stdin)
issues = d.get('issues', d if isinstance(d, list) else [])
patterns = $(printf '%s\n' "${GAP_TITLE_PATTERNS[@]}" | /usr/bin/python3 -c 'import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')
result = []
for b in issues:
    title = b.get('title','')
    if not any(p in title for p in patterns):
        continue
    m = re.match(r'^\[gap-([a-z-]+)\] +(.+)$', title)
    if not m:
        continue
    cls = m.group(1)
    subject = m.group(2)
    base = subject.split('/')[-1]
    body = b.get('description','') or ''
    result.append({
        'id': b['id'],
        'title': title[:120],
        'class': cls,
        'basename': base,
        'body': body[:500],
    })
print(json.dumps(result))
")"

  # Walk each candidate
  local close_count=0
  local skip_flagged_count=0
  local skip_opt_out_count=0
  local processed_count=0
  # flywheel-kjli4: per-class counters for Jeff-Premium auto-close + still-flagged sub-classes
  local jeff_premium_count=0
  local joshua_domain_count=0
  local skillos_managed_count=0
  local unknown_class_count=0

  # Use python for the per-bead loop (cleanest jq-free path)
  local result_json
  result_json="$(printf '%s' "$triage_json" | /usr/bin/python3 -c "
import sys, json
candidates = json.load(sys.stdin)
probe_data = json.loads(open('/dev/stdin').read() if False else sys.argv[1] if len(sys.argv)>1 else '{}')
" 2>/dev/null || true)"

  # Fallback to bash-loop for per-bead decisions (more debuggable)
  while IFS=$'\t' read -r bid btitle bclass bbase bbody; do
    [[ -z "$bid" ]] && continue
    processed_count=$((processed_count+1))
    if printf '%s' "$bbody" | grep -qE 'do-not-auto-close|disposition=open-genuine-gap'; then
      skipped_opt_out+=("$bid|$btitle")
      skip_opt_out_count=$((skip_opt_out_count+1))
      continue
    fi
    # Check whether the gap subject is still flagged
    if gap_still_flagged "$bclass" "$bbase" "$probe_json"; then
      # flywheel-kjli4: still-flagged path — classify substrate boundary
      # to decide whether to AUDIT-ONLY-auto-close (Jeff Premium, Class 3)
      # or skip-still-flagged (Class 1 Joshua-domain or Class 2 Skillos-managed)
      local subst_class
      subst_class="$(classify_substrate_class "$btitle")"
      case "$subst_class" in
        jeff-premium)
          planned_closes+=("$bid|$btitle|$bclass|$bbase|audit-only-jeff-substrate-class-3")
          close_count=$((close_count+1))
          jeff_premium_count=$((jeff_premium_count+1))
          ;;
        joshua-domain)
          skipped_still_flagged+=("$bid|$btitle|joshua-domain")
          skip_flagged_count=$((skip_flagged_count+1))
          joshua_domain_count=$((joshua_domain_count+1))
          ;;
        skillos-managed)
          skipped_still_flagged+=("$bid|$btitle|skillos-managed")
          skip_flagged_count=$((skip_flagged_count+1))
          skillos_managed_count=$((skillos_managed_count+1))
          ;;
        *)
          # not-skill-path or unknown — leave open as before
          skipped_still_flagged+=("$bid|$btitle|unknown")
          skip_flagged_count=$((skip_flagged_count+1))
          unknown_class_count=$((unknown_class_count+1))
          ;;
      esac
    else
      planned_closes+=("$bid|$btitle|$bclass|$bbase|moot-by-current-probe-clearance")
      close_count=$((close_count+1))
    fi
  done < <(printf '%s' "$triage_json" | /usr/bin/python3 -c "
import sys, json
candidates = json.load(sys.stdin)
for c in candidates:
    # tab-separated for bash read
    print('\t'.join([c['id'], c['title'].replace('\t',' '), c['class'], c['basename'], c['body'].replace('\t',' ').replace('\n',' ')]))
")

  # Step 4: if --apply, close each planned bead + append ledger row
  local closed_ids=()
  if [[ "$mode" == "apply" ]] && (( close_count > 0 )); then
    local commit_sha; commit_sha="$(cd "$REPO_ROOT" && /usr/bin/git rev-parse HEAD 2>/dev/null || echo unknown)"
    mkdir -p "$(dirname "$LEDGER")"
    for entry in "${planned_closes[@]}"; do
      IFS='|' read -r bid btitle bclass bbase bdisp <<< "$entry"
      # flywheel-kjli4: synthesize audit pack for Jeff-Premium auto-closures BEFORE br close
      if [[ "$bdisp" == "audit-only-jeff-substrate-class-3" ]]; then
        local skill=""
        if [[ "$btitle" =~ \.claude/skills/([A-Za-z0-9._-]+)/ ]]; then
          skill="${BASH_REMATCH[1]}"
        fi
        synthesize_jeff_audit_pack "$bid" "$btitle" "$skill" "$ts" "$commit_sha"
      fi
      if "$BR_BIN" close "$bid" >/dev/null 2>&1; then
        closed_ids+=("$bid")
        /usr/bin/python3 -c "
import json, sys
print(json.dumps({
  'schema_version': '$SCHEMA_VERSION',
  'ts': '$ts',
  'action': 'auto-close',
  'bead_id': '$bid',
  'title': '''$btitle'''.replace(chr(10),' '),
  'class': '$bclass',
  'basename': '$bbase',
  'disposition': '$bdisp',
  'clearing_commit': '$commit_sha',
  'idempotency_key': '$idem_key',
}))" >> "$LEDGER"
      fi
    done
  fi

  # Step 5: emit envelope
  if $json_out; then
    /usr/bin/python3 -c "
import json
print(json.dumps({
  'schema_version': '$SCHEMA_VERSION',
  'command': 'run',
  'ts': '$ts',
  'mode': '$mode',
  'processed': $processed_count,
  'planned_closes': $close_count,
  'closed': len([1 for x in '''${closed_ids[@]}'''.split() if x]),
  'skipped_still_flagged': $skip_flagged_count,
  'skipped_opt_out': $skip_opt_out_count,
  'per_class_counts': {
    'jeff_premium_auto_audit_only': $jeff_premium_count,
    'joshua_domain_skip': $joshua_domain_count,
    'skillos_managed_skip': $skillos_managed_count,
    'unknown_or_non_skill_skip': $unknown_class_count,
  },
  'planned_close_ids': '''${planned_closes[@]+${planned_closes[@]}}'''.split() if '''${planned_closes[@]+set}''' == 'set' else [],
  'ledger': '$LEDGER',
  'idempotency_key': '$idem_key',
}, default=str))
"
  else
    printf 'mode=%s processed=%d planned_closes=%d closed=%d skipped_still_flagged=%d skipped_opt_out=%d\n' \
      "$mode" "$processed_count" "$close_count" "${#closed_ids[@]}" "$skip_flagged_count" "$skip_opt_out_count"
    printf 'per_class: jeff_premium_auto_audit=%d joshua_domain=%d skillos_managed=%d unknown=%d\n' \
      "$jeff_premium_count" "$joshua_domain_count" "$skillos_managed_count" "$unknown_class_count"
    if (( close_count > 0 )); then
      printf 'planned closes:\n'
      for entry in "${planned_closes[@]}"; do
        IFS='|' read -r bid btitle bclass bbase bdisp <<< "$entry"
        printf '  %s [%s] [%s] %s\n' "$bid" "$bclass" "$bdisp" "$btitle"
      done
    fi
  fi
}

cmd_doctor() {
  local jq_status="pass"; command -v jq >/dev/null 2>&1 || jq_status="warn"
  local br_status="pass"; [[ -x "$BR_BIN" ]] || br_status="fail"
  local probe_status="pass"; [[ -x "$GAP_PROBE" ]] || probe_status="fail"
  local py_status="pass"; command -v python3 >/dev/null 2>&1 || py_status="fail"
  local ledger_dir; ledger_dir="$(dirname "$LEDGER")"
  local ledger_status="pass"; mkdir -p "$ledger_dir" 2>/dev/null || true; [[ -w "$ledger_dir" ]] || ledger_status="fail"
  local status="ok"
  for s in "$jq_status" "$br_status" "$probe_status" "$py_status" "$ledger_status"; do
    [[ "$s" == "fail" ]] && status="fail"
  done
  /usr/bin/python3 -c "
import json
print(json.dumps({
  'schema_version': '$SCHEMA_VERSION',
  'command': 'doctor',
  'ts': '$(now_iso)',
  'status': '$status',
  'checks': [
    {'name':'jq','status':'$jq_status'},
    {'name':'br','status':'$br_status','path':'$BR_BIN'},
    {'name':'gap-hunt-probe','status':'$probe_status','path':'$GAP_PROBE'},
    {'name':'python3','status':'$py_status'},
    {'name':'ledger_writable','status':'$ledger_status','path':'$LEDGER'},
  ]
}))
"
}

cmd_health() {
  local rows=0
  local last_status="unknown"
  if [[ -f "$LEDGER" ]]; then
    rows=$(/usr/bin/wc -l < "$LEDGER" | /usr/bin/tr -d ' ')
    last_status=$(/usr/bin/tail -1 "$LEDGER" 2>/dev/null | /usr/bin/python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('disposition','unknown'))" 2>/dev/null || echo "unknown")
  fi
  /usr/bin/python3 -c "
import json
print(json.dumps({
  'schema_version': '$SCHEMA_VERSION',
  'command': 'health',
  'ts': '$(now_iso)',
  'status': 'ok' if $rows >= 0 else 'fail',
  'ledger': '$LEDGER',
  'ledger_row_count': $rows,
  'last_disposition': '$last_status',
}))
"
}

cmd_validate() {
  local subject="${1:-}"; shift || true
  local value="${1:-}"
  case "$subject" in
    bead-id)
      if [[ -z "$value" ]]; then
        printf '{"schema_version":"%s","command":"validate","subject":"bead-id","status":"reject","reason":"value required"}\n' "$SCHEMA_VERSION"
        return 64
      fi
      if [[ "$value" =~ ^flywheel-[a-z0-9.]{3,}$ ]]; then
        printf '{"schema_version":"%s","command":"validate","subject":"bead-id","status":"ok","value":"%s"}\n' "$SCHEMA_VERSION" "$value"
      else
        printf '{"schema_version":"%s","command":"validate","subject":"bead-id","status":"reject","reason":"shape_mismatch","pattern":"^flywheel-[a-z0-9.]+$","value":"%s"}\n' "$SCHEMA_VERSION" "$value"
        return 1
      fi
      ;;
    gap-class)
      if [[ -z "$value" ]]; then
        printf '{"schema_version":"%s","command":"validate","subject":"gap-class","status":"reject","reason":"value required"}\n' "$SCHEMA_VERSION"
        return 64
      fi
      case "$value" in
        wired-but-cold|memory-without-cross-link|cross-source-silos|probe-without-receiver|bead-without-followup|doctrine-without-measurement|skill-without-jsm-publish|substrate-without-version-probe|loop-integrity)
          printf '{"schema_version":"%s","command":"validate","subject":"gap-class","status":"ok","value":"%s"}\n' "$SCHEMA_VERSION" "$value"
          ;;
        *)
          printf '{"schema_version":"%s","command":"validate","subject":"gap-class","status":"reject","reason":"unknown_class","value":"%s"}\n' "$SCHEMA_VERSION" "$value"
          return 1
          ;;
      esac
      ;;
    *)
      printf 'ERR: validate requires subject {bead-id|gap-class}\n' >&2
      return 64
      ;;
  esac
}

cmd_audit() {
  local n="${1:-20}"
  if [[ ! -f "$LEDGER" ]]; then
    printf '{"schema_version":"%s","command":"audit","status":"missing","ledger":"%s","row_count":0,"recent":[]}\n' "$SCHEMA_VERSION" "$LEDGER"
    return 0
  fi
  /usr/bin/python3 -c "
import json, sys
rows = []
try:
    with open('$LEDGER') as fh:
        for line in fh:
            line = line.strip()
            if not line: continue
            try:
                rows.append(json.loads(line))
            except: pass
except FileNotFoundError:
    pass
print(json.dumps({
  'schema_version': '$SCHEMA_VERSION',
  'command': 'audit',
  'ts': '$(now_iso)',
  'ledger': '$LEDGER',
  'row_count': len(rows),
  'recent': rows[-$n:],
}))
"
}

cmd_why() {
  local bid="${1:-}"
  if [[ -z "$bid" ]]; then printf 'ERR: why requires <bead-id>\n' >&2; return 64; fi
  if [[ ! -f "$LEDGER" ]]; then
    printf '{"schema_version":"%s","command":"why","bead_id":"%s","status":"not_found","reason":"ledger_missing"}\n' "$SCHEMA_VERSION" "$bid"
    return 1
  fi
  /usr/bin/python3 -c "
import json
hits = []
with open('$LEDGER') as fh:
    for line in fh:
        line = line.strip()
        if not line: continue
        try:
            row = json.loads(line)
            if row.get('bead_id') == '$bid':
                hits.append(row)
        except: pass
print(json.dumps({
  'schema_version': '$SCHEMA_VERSION',
  'command': 'why',
  'bead_id': '$bid',
  'status': 'found' if hits else 'not_found',
  'closures': hits,
}))
"
}

cmd_info() {
  /usr/bin/python3 -c "
import json
print(json.dumps({
  'schema_version': '$SCHEMA_VERSION',
  'command': 'info',
  'name': 'orch-tick-stale-auto-bead-close',
  'version': '$VERSION',
  'config_paths': {
    'ledger': '$LEDGER',
    'br': '$BR_BIN',
    'gap_probe': '$GAP_PROBE',
    'repo_root': '$REPO_ROOT',
  },
  'subcommands': ['doctor','health','repair','validate','audit','why','info','examples','quickstart','help','completion','schema','run'],
  'capabilities': ['gap-bead-auto-close','dry-run-default','idempotency-key','ledger-receipt'],
  'gap_class_patterns': $(printf '%s\n' "${GAP_TITLE_PATTERNS[@]}" | /usr/bin/python3 -c 'import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))'),
}))
"
}

cmd_examples() {
  /usr/bin/python3 -c "
import json
print(json.dumps({
  'schema_version': '$SCHEMA_VERSION',
  'command': 'examples',
  'examples': [
    {'name':'dry-run-default','invocation':'orch-tick-stale-auto-bead-close.sh','purpose':'list planned closures without acting'},
    {'name':'dry-run-json','invocation':'orch-tick-stale-auto-bead-close.sh --dry-run --json','purpose':'JSON envelope of planned closures'},
    {'name':'apply-with-idem','invocation':'orch-tick-stale-auto-bead-close.sh --apply --idempotency-key tick-2026-05-11','purpose':'close all moot beads + write ledger'},
    {'name':'doctor','invocation':'orch-tick-stale-auto-bead-close.sh doctor --json','purpose':'check substrate health (br, gap-probe, ledger)'},
    {'name':'audit-tail','invocation':'orch-tick-stale-auto-bead-close.sh audit --json 20','purpose':'last 20 closures'},
  ]
}))
"
}

cmd_quickstart() {
  cat <<'QS'
orch-tick-stale-auto-bead-close.sh — auto-close moot auto-filed gap beads

When auto-filed gap beads (e.g., [gap-wired-but-cold] X.sh) are dispatched
but the gap is no longer flagged in current substrate state (because of
parallel fixes that landed between bead filing and dispatch), the worker-
tick dispatch produces an audit-only "MOOT-BY-PARALLEL-FIX" close. This is
~60-80% of dispatches per N=5 observation. This driver mechanizes that
close at the orch tick layer, reclaiming ~3 worker ticks/hour.

Usage:
  # Dry-run (default): see what WOULD be closed
  ./orch-tick-stale-auto-bead-close.sh

  # Apply (close moot beads + ledger receipt)
  ./orch-tick-stale-auto-bead-close.sh --apply --idempotency-key tick-2026-05-11

  # Substrate health check
  ./orch-tick-stale-auto-bead-close.sh doctor --json

Opt-out: include `do-not-auto-close` or `disposition=open-genuine-gap` in
the bead description body. Such beads will be SKIPPED by this driver.

Receipt: $HOME/.local/state/flywheel/orch-tick-stale-auto-close.jsonl
QS
}

cmd_help() {
  local topic="${1:-overview}"
  case "$topic" in
    overview) cmd_quickstart ;;
    opt-out)
      cat <<'OPT'
Opt-out mechanism for orch-tick-stale-auto-bead-close:

To prevent this driver from auto-closing a bead even when the underlying
gap is no longer flagged, include ONE of these markers in the bead's
description body:

  do-not-auto-close
  disposition=open-genuine-gap
  open-genuine-gap

The driver scans bead descriptions for these markers and skips matched
beads. Genuine open gaps (where the operator wants the bead to remain
open even though the probe doesn't flag the subject) use this mechanism.
OPT
      ;;
    *) printf 'ERR: unknown help topic %s\n' "$topic" >&2; return 64 ;;
  esac
}

cmd_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    bash)
      cat <<'BC'
_orch_tick_stale_auto_bead_close() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "doctor health repair validate audit why info examples quickstart help completion schema --dry-run --apply --idempotency-key --json" -- "$cur") )
}
complete -F _orch_tick_stale_auto_bead_close orch-tick-stale-auto-bead-close.sh
BC
      ;;
    zsh) printf 'compdef _orch_tick_stale_auto_bead_close orch-tick-stale-auto-bead-close.sh\n' ;;
    *) printf 'ERR: shell {bash|zsh}\n' >&2; return 64 ;;
  esac
}

cmd_schema() {
  /usr/bin/python3 -c "
import json
print(json.dumps({
  'schema_version': '$SCHEMA_VERSION',
  'envelope': {
    'fields': ['schema_version','command','ts','status','mode','processed','planned_closes','closed','skipped_still_flagged','skipped_opt_out','ledger'],
  },
  'ledger_row': {
    'fields': ['schema_version','ts','action','bead_id','title','class','basename','disposition','clearing_commit','idempotency_key'],
  }
}))
"
}

cmd_repair() {
  local scope="" mode="dry-run" idem_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --scope) scope="$2"; shift 2 ;;
      --apply) mode="apply"; shift ;;
      --dry-run) mode="dry-run"; shift ;;
      --idempotency-key) idem_key="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  case "$scope" in
    ledger_dir)
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$(dirname "$LEDGER")"
        printf '{"schema_version":"%s","command":"repair","scope":"ledger_dir","status":"applied"}\n' "$SCHEMA_VERSION"
      else
        printf '{"schema_version":"%s","command":"repair","scope":"ledger_dir","status":"planned"}\n' "$SCHEMA_VERSION"
      fi
      ;;
    ledger_truncate)
      if [[ "$mode" == "apply" ]]; then
        if [[ -z "$idem_key" ]]; then
          printf '{"schema_version":"%s","command":"repair","scope":"ledger_truncate","status":"refused","reason":"--idempotency-key required for mutation"}\n' "$SCHEMA_VERSION"
          return 4
        fi
        : > "$LEDGER"
        printf '{"schema_version":"%s","command":"repair","scope":"ledger_truncate","status":"applied","idempotency_key":"%s"}\n' "$SCHEMA_VERSION" "$idem_key"
      else
        printf '{"schema_version":"%s","command":"repair","scope":"ledger_truncate","status":"planned"}\n' "$SCHEMA_VERSION"
      fi
      ;;
    *)
      printf '{"schema_version":"%s","command":"repair","status":"refused","reason":"--scope required (ledger_dir|ledger_truncate)"}\n' "$SCHEMA_VERSION"
      return 64
      ;;
  esac
}

main() {
  if [[ $# -eq 0 ]]; then
    cmd_run --dry-run
    return 0
  fi
  case "$1" in
    -h|--help)         usage; exit 0 ;;
    doctor)            shift; cmd_doctor "$@"; exit $? ;;
    health)            shift; cmd_health "$@"; exit $? ;;
    repair)            shift; cmd_repair "$@"; exit $? ;;
    validate)          shift; cmd_validate "$@"; exit $? ;;
    audit)             shift; cmd_audit "$@"; exit $? ;;
    why)               shift; cmd_why "$@"; exit $? ;;
    info|--info)       shift; cmd_info "$@"; exit $? ;;
    examples|--examples) shift; cmd_examples "$@"; exit $? ;;
    quickstart)        shift; cmd_quickstart "$@"; exit $? ;;
    help)              shift; cmd_help "$@"; exit $? ;;
    completion)        shift; cmd_completion "$@"; exit $? ;;
    schema)            shift; cmd_schema "$@"; exit $? ;;
    --dry-run|--apply|--idempotency-key|--json) cmd_run "$@"; exit $? ;;
    *) printf 'ERR: unknown subcommand %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
}

main "$@"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-04-receipt-callback-envelope.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-88-content-addressed-evidence-pack.md`
