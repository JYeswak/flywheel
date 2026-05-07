#!/usr/bin/env bash
set -uo pipefail

VERSION="validate-callback-before-close.v1.1.0"
REPO="$PWD"
NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
NTM_SESSION="${NTM_SESSION:-flywheel}"
BEAD=""
EVIDENCE=""
STRICT=0
JSON_OUT=0
MODE="dry-run"

usage() {
  cat <<'EOF'
usage: validate-callback-before-close.sh [--repo PATH] --bead ID --evidence PATH [--dry-run|--apply] [--strict] [--json]
       validate-callback-before-close.sh ID PATH [--strict]

Blocks bead closeout when mechanical evidence or the four-lens bar fails.

Options:
  --repo PATH       repo whose bead DB and relative evidence paths are checked
  --bead ID         bead id being considered for close
  --evidence PATH   worker evidence file
  --dry-run         report verdict and planned rework bead only (default)
  --apply           create or reuse a repo-local rework bead on BLOCK_CLOSE
  --strict          treat warnings as close blockers
  --json            emit machine-readable JSON
  --help            show this help
  --info            show contract info
  --examples        show examples
  --version         show version
EOF
}

info() {
  cat <<EOF
name: validate-callback-before-close.sh
version: $VERSION
schema_version: four-lens-close-validator/v1
read_only_default: true
mutates_only_with: --apply
purpose: gate br close on evidence receipts plus brand/sniff/Jeff/public lens checks
EOF
}

examples() {
  cat <<'EOF'
validate-callback-before-close.sh flywheel-123a /tmp/flywheel-123a-evidence.md --strict
validate-callback-before-close.sh --repo /Users/josh/Developer/flywheel --bead flywheel-123a --evidence /tmp/flywheel-123a-evidence.md --json
validate-callback-before-close.sh --repo . --bead flywheel-123a --evidence /tmp/flywheel-123a-evidence.md --apply --json
EOF
}

fail_usage() {
  echo "ERR: $1" >&2
  usage >&2
  exit 2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      [ -n "${2:-}" ] || fail_usage "--repo requires PATH"
      REPO="$2"
      shift 2
      ;;
    --bead)
      [ -n "${2:-}" ] || fail_usage "--bead requires ID"
      BEAD="$2"
      shift 2
      ;;
    --evidence)
      [ -n "${2:-}" ] || fail_usage "--evidence requires PATH"
      EVIDENCE="$2"
      shift 2
      ;;
    --strict)
      STRICT=1
      shift
      ;;
    --json)
      JSON_OUT=1
      shift
      ;;
    --dry-run)
      MODE="dry-run"
      shift
      ;;
    --apply)
      MODE="apply"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --info)
      info
      exit 0
      ;;
    --examples)
      examples
      exit 0
      ;;
    --version)
      printf '%s\n' "$VERSION"
      exit 0
      ;;
    -*)
      fail_usage "unknown option: $1"
      ;;
    *)
      if [ -z "$BEAD" ]; then
        BEAD="$1"
      elif [ -z "$EVIDENCE" ]; then
        EVIDENCE="$1"
      else
        fail_usage "unexpected argument: $1"
      fi
      shift
      ;;
  esac
done

[ -n "$BEAD" ] || fail_usage "missing --bead"
[ -n "$EVIDENCE" ] || fail_usage "missing --evidence"

if ! REPO_ABS="$(cd "$REPO" 2>/dev/null && pwd -P)"; then
  echo "ERR: repo not found: $REPO" >&2
  exit 2
fi

if [ "${EVIDENCE#/}" = "$EVIDENCE" ]; then
  EVIDENCE_ABS="$REPO_ABS/$EVIDENCE"
else
  EVIDENCE_ABS="$EVIDENCE"
fi

FAIL=0
WARN=0
FAILURES=""
WARNINGS=""
BRAND_STATUS="pass"
SNIFF_STATUS="pass"
JEFF_STATUS="pass"
PUBLIC_STATUS="pass"
BRAND_REASON=""
SNIFF_REASON=""
JEFF_REASON=""
PUBLIC_REASON=""
REWORK_BEAD=""
REWORK_ACTION="none"

append_line() {
  var_name="$1"
  line="$2"
  eval "old=\${$var_name}"
  if [ -n "$old" ]; then
    eval "$var_name=\$old\$'\\n'\$line"
  else
    eval "$var_name=\$line"
  fi
}

check_fail() {
  FAIL=$((FAIL + 1))
  append_line FAILURES "$1"
}

check_warn() {
  WARN=$((WARN + 1))
  append_line WARNINGS "$1"
}

append_reason() {
  var_name="$1"
  reason="$2"
  eval "old=\${$var_name}"
  if [ -n "$old" ]; then
    eval "$var_name=\$old,\$reason"
  else
    eval "$var_name=\$reason"
  fi
}

lens_fail() {
  lens="$1"
  reason="$2"
  case "$lens" in
    brand)
      BRAND_STATUS="fail"
      append_reason BRAND_REASON "$reason"
      ;;
    sniff)
      SNIFF_STATUS="fail"
      append_reason SNIFF_REASON "$reason"
      ;;
    jeff)
      JEFF_STATUS="fail"
      append_reason JEFF_REASON "$reason"
      ;;
    public)
      PUBLIC_STATUS="fail"
      append_reason PUBLIC_REASON "$reason"
      ;;
  esac
}

short_probe_text() {
  sed '/^$/d' "$@" 2>/dev/null | head -3 | tr '\n' ' ' | cut -c1-500
}

looks_like_db_busy() {
  grep -qiE 'database is locked|database busy|SQLITE_BUSY|OpenRead|malformed|b-tree|database disk image|resource busy'
}

check_br_dep_cycles() {
  cycles_json="$(mktemp "${TMPDIR:-/tmp}/br-dep-cycles.XXXXXX.json")"
  cycles_err="$(mktemp "${TMPDIR:-/tmp}/br-dep-cycles.XXXXXX.err")"
  set +e
  (cd "$REPO_ABS" && br dep cycles --json >"$cycles_json" 2>"$cycles_err")
  cycles_rc=$?
  set -e

  if jq -e . "$cycles_json" >/dev/null 2>&1; then
    if jq -e '.error.code == "CYCLE_DETECTED"' "$cycles_json" >/dev/null 2>&1; then
      summary="$(jq -c '.error.context // .error' "$cycles_json" | cut -c1-500)"
      check_fail "br_dep_cycles_not_empty: count=1 summary=$summary"
      rm -f "$cycles_json" "$cycles_err"
      return 0
    fi

    if [ "$cycles_rc" -ne 0 ]; then
      probe_text="$(short_probe_text "$cycles_json" "$cycles_err")"
      if printf '%s\n' "$probe_text" | looks_like_db_busy; then
        check_fail "br_dep_cycles_db_busy: $probe_text"
      else
        check_fail "br_dep_cycles_probe_failed: rc=$cycles_rc $probe_text"
      fi
      rm -f "$cycles_json" "$cycles_err"
      return 0
    fi

    cycle_count="$(jq -r '
      if (.count | type) == "number" then .count
      elif (.cycles | type) == "array" then (.cycles | length)
      elif type == "array" then length
      else empty end
    ' "$cycles_json")"
    if ! printf '%s\n' "$cycle_count" | grep -qE '^[0-9]+$'; then
      check_fail "br_dep_cycles_json_invalid_shape"
      rm -f "$cycles_json" "$cycles_err"
      return 0
    fi
    if [ "$cycle_count" -gt 0 ]; then
      summary="$(jq -c '.cycles // .' "$cycles_json" | cut -c1-500)"
      check_fail "br_dep_cycles_not_empty: count=$cycle_count cycles=$summary"
    fi
    rm -f "$cycles_json" "$cycles_err"
    return 0
  fi

  probe_text="$(short_probe_text "$cycles_json" "$cycles_err")"
  if [ "$cycles_rc" -ne 0 ] && printf '%s\n' "$probe_text" | looks_like_db_busy; then
    check_fail "br_dep_cycles_db_busy: $probe_text"
  elif [ "$cycles_rc" -ne 0 ]; then
    check_fail "br_dep_cycles_probe_failed: rc=$cycles_rc $probe_text"
  else
    check_fail "br_dep_cycles_json_invalid: $probe_text"
  fi
  rm -f "$cycles_json" "$cycles_err"
}

if [ ! -f "$EVIDENCE_ABS" ]; then
  check_fail "evidence_missing: $EVIDENCE_ABS"
elif [ ! -s "$EVIDENCE_ABS" ]; then
  check_fail "evidence_empty: $EVIDENCE_ABS"
fi

if [ -f "$EVIDENCE_ABS" ]; then
  if ! grep -qE '\b(did|didnt|gaps)\b' "$EVIDENCE_ABS"; then
    check_warn "evidence_missing_did_didnt_gaps_tokens"
  fi

  GAPS=$(grep -oE '(^|[[:space:]])gaps=[a-z]+-[a-z0-9]+(\.[0-9]+)*(,[a-z]+-[a-z0-9]+(\.[0-9]+)*)*([[:space:]]|$)' "$EVIDENCE_ABS" | head -1 | sed -E 's/^[[:space:]]*gaps=//; s/[[:space:]]*$//' | tr ',' '\n' | grep -v '^none$' || true)
  for G in $GAPS; do
    if ! (cd "$REPO_ABS" && br show "$G" >/dev/null 2>&1); then
      check_fail "gap_bead_not_found: $G"
    fi
  done

  CREATED=$(grep -oE 'created=[a-z0-9,-]+' "$EVIDENCE_ABS" | head -1 | sed 's/^created=//' | tr ',' '\n' | grep -v '^none$' || true)
  for C in $CREATED; do
    if ! (cd "$REPO_ABS" && br show "$C" >/dev/null 2>&1); then
      check_fail "created_bead_not_found: $C"
    fi
  done

  PATHS=$(grep -oE '`(/[^`]+|\.flywheel/[^` ]+|tests/[^` ]+|templates/[^` ]+)`' "$EVIDENCE_ABS" | sed 's/`//g' | sort -u || true)
  while IFS= read -r P; do
    [ -z "$P" ] && continue
    if [ "${P#/}" = "$P" ]; then
      P="$REPO_ABS/$P"
    fi
    if [ ! -e "$P" ]; then
      check_warn "artifact_path_not_found: $P"
    fi
  done <<EOF
$PATHS
EOF

  if grep -qE 'tests=PASS|tests?[ _-]?(pass|passed)' "$EVIDENCE_ABS"; then
    SUSPICIOUS=$(grep -nE '\b(FAIL|FAILED|ERROR|error:)\b' "$EVIDENCE_ABS" | grep -vE '(no |not |_)(FAIL|FAILED|ERROR|error)' | head -3 || true)
    if [ -n "$SUSPICIOUS" ]; then
      check_warn "tests_PASS_but_evidence_mentions_FAIL_ERROR: $(printf '%s\n' "$SUSPICIOUS" | head -1)"
    fi
  fi
fi

if command -v br >/dev/null 2>&1; then
  CHILDREN=$(cd "$REPO_ABS" && br show "$BEAD" 2>&1 | grep -A 50 'Dependents:' | grep -oE 'flywheel-[a-z0-9]+(\.[0-9]+)*' | grep -v "^${BEAD}$" | head -20 || true)
  for C in $CHILDREN; do
    STATE=$(cd "$REPO_ABS" && br show "$C" 2>&1 | grep -oE '\[. (P[0-3]|--) · (OPEN|CLOSED|IN_PROGRESS|BLOCKED|READY)' | grep -oE '(OPEN|IN_PROGRESS|BLOCKED|READY)' | head -1 || true)
    if [ -n "$STATE" ] && [ "$STATE" != "CLOSED" ]; then
      check_fail "open_child_blocks_close: $C state=$STATE"
    fi
  done

  check_br_dep_cycles
fi

if [ -f "$EVIDENCE_ABS" ]; then
  if grep -qiE '\b(leverage synergies|robust solution|seamlessly|cutting-edge|best-in-class|world-class|game-changer|disrupt|revolutionize|paradigm shift|deep dive|circle back|move the needle|low-hanging fruit)\b' "$EVIDENCE_ABS"; then
    lens_fail brand "slop_words_present"
  fi
  if grep -qiE '\b(competitor[s]? (failed|cant|wont|lose)|defeat|crush them|outmaneuver)\b' "$EVIDENCE_ABS"; then
    lens_fail brand "enemy_framing"
  fi

  RECEIPT_COUNT=$(grep -oE '(`/[^`]+`|`\.flywheel/[^`]+`|flywheel-[a-z0-9]+|line [0-9]+|:[0-9]+)' "$EVIDENCE_ABS" | wc -l | tr -d ' ' || true)
  if [ "$RECEIPT_COUNT" -lt 3 ]; then
    lens_fail sniff "few_receipts_${RECEIPT_COUNT}_lt_3"
  fi
  if grep -qE '^(status|state|metric|gauge):' "$EVIDENCE_ABS" && ! grep -qiE '(outcome|impact|result|landed|shipped|reduces|prevents)' "$EVIDENCE_ABS"; then
    lens_fail sniff "status_without_outcome"
  fi

  if grep -qiE 'tests?[_ -]?(pass|passed)|tests=PASS' "$EVIDENCE_ABS"; then
    if ! grep -qE '(```|bash|\$ |zsh|run:|exec:)' "$EVIDENCE_ABS"; then
      lens_fail jeff "tests_PASS_claimed_no_executable_proof"
    fi
  fi
  if grep -qiE '(schema|contract|receipt|payload)' "$EVIDENCE_ABS" && ! grep -qiE '(v[0-9]+|version|schema_version)' "$EVIDENCE_ABS"; then
    lens_fail jeff "contract_without_version"
  fi

  EVIDENCE_LINES=$(wc -l < "$EVIDENCE_ABS" | tr -d ' ')
  if [ "$EVIDENCE_LINES" -lt 20 ]; then
    lens_fail public "too_thin_${EVIDENCE_LINES}_lt_20"
  fi
  if ! grep -qiE '(acceptance|gate|criterion|criteria)' "$EVIDENCE_ABS"; then
    lens_fail public "no_acceptance_gates_addressed"
  fi
  if ! grep -qiE '(three judges|publishability|brand voice|donella|jeff|meadows|four-lens|four lens)' "$EVIDENCE_ABS"; then
    lens_fail public "no_bar_self_grade"
  fi
fi

for lens in brand sniff jeff public; do
  case "$lens" in
    brand) status="$BRAND_STATUS"; reason="$BRAND_REASON" ;;
    sniff) status="$SNIFF_STATUS"; reason="$SNIFF_REASON" ;;
    jeff) status="$JEFF_STATUS"; reason="$JEFF_REASON" ;;
    public) status="$PUBLIC_STATUS"; reason="$PUBLIC_REASON" ;;
  esac
  if [ "$status" = "fail" ]; then
    check_fail "lens_${lens}_fail: $reason"
  fi
done

VERDICT="SAFE_TO_CLOSE"
if [ "$FAIL" -gt 0 ]; then
  VERDICT="BLOCK_CLOSE"
elif [ "$STRICT" -eq 1 ] && [ "$WARN" -gt 0 ]; then
  VERDICT="BLOCK_CLOSE"
fi

create_rework_bead() {
  [ "$VERDICT" = "BLOCK_CLOSE" ] || return 0
  command -v br >/dev/null 2>&1 || {
    REWORK_ACTION="blocked_no_br"
    return 0
  }
  title="[four-lens-rework] ${BEAD} close validation"
  existing=$(cd "$REPO_ABS" && br list --json 2>/dev/null | jq -r --arg title "$title" '(if type == "object" and has("issues") then .issues else . end)[]? | select(.title == $title and (.status | ascii_downcase) != "closed") | .id' | head -1 2>/dev/null || true)
  if [ -n "$existing" ]; then
    REWORK_BEAD="$existing"
    REWORK_ACTION="reused"
    return 0
  fi
  if [ "$MODE" != "apply" ]; then
    REWORK_ACTION="would_create"
    return 0
  fi
  desc_file="$(mktemp "${TMPDIR:-/tmp}/four-lens-rework.XXXXXX")"
  {
    printf 'Parent bead: %s\n' "$BEAD"
    printf 'Close validator: validate-callback-before-close/v1\n'
    printf 'Evidence: %s\n\n' "$EVIDENCE_ABS"
    printf 'Validator blocked close with %s failures and %s warnings.\n\n' "$FAIL" "$WARN"
    printf 'Failures:\n'
    printf '%s\n' "$FAILURES" | sed '/^$/d; s/^/- /'
    printf '\nAcceptance:\n'
    printf 'AG1: Rework evidence or implementation until validate-callback-before-close.sh returns SAFE_TO_CLOSE.\n'
    printf 'AG2: Preserve did/didnt/gaps, executable test proof, acceptance-gate mapping, and Four-Lens Self-Grade.\n'
  } >"$desc_file"
  created=$(cd "$REPO_ABS" && br create "$title" --priority 1 --type task --description "$(cat "$desc_file")" --json 2>/dev/null | jq -r '.id // empty' || true)
  rm -f "$desc_file"
  if [ -n "$created" ]; then
    REWORK_BEAD="$created"
    REWORK_ACTION="created"
  else
    REWORK_ACTION="create_failed"
  fi
}

create_rework_bead

NTM_CHANGES_JSON="$("$NTM_BIN" changes "$NTM_SESSION" --json 2>/dev/null || printf 'null\n')"
NTM_CONFLICTS_JSON="$("$NTM_BIN" conflicts "$NTM_SESSION" --json --limit 50 2>/dev/null || printf 'null\n')"

emit_json() {
  python3 - "$FAILURES" "$WARNINGS" <<PY
import json
import os
import sys

failures = [line for line in sys.argv[1].splitlines() if line]
warnings = [line for line in sys.argv[2].splitlines() if line]
payload = {
    "schema_version": "four-lens-close-validator/v1",
    "version": os.environ["FW_VCBC_VERSION"],
    "repo": os.environ["FW_VCBC_REPO"],
    "bead": os.environ["FW_VCBC_BEAD"],
    "evidence": os.environ["FW_VCBC_EVIDENCE"],
    "mode": os.environ["FW_VCBC_MODE"],
    "verdict": os.environ["FW_VCBC_VERDICT"],
    "failures_count": int(os.environ["FW_VCBC_FAIL"]),
    "warnings_count": int(os.environ["FW_VCBC_WARN"]),
    "failures": failures,
    "warnings": warnings,
    "four_lens": {
        "brand": {"status": os.environ["FW_VCBC_BRAND_STATUS"], "reason": os.environ["FW_VCBC_BRAND_REASON"]},
        "sniff": {"status": os.environ["FW_VCBC_SNIFF_STATUS"], "reason": os.environ["FW_VCBC_SNIFF_REASON"]},
        "jeff": {"status": os.environ["FW_VCBC_JEFF_STATUS"], "reason": os.environ["FW_VCBC_JEFF_REASON"]},
        "public": {"status": os.environ["FW_VCBC_PUBLIC_STATUS"], "reason": os.environ["FW_VCBC_PUBLIC_REASON"]},
    },
    "auto_rework": {
        "action": os.environ["FW_VCBC_REWORK_ACTION"],
        "bead": os.environ["FW_VCBC_REWORK_BEAD"] or None,
    },
    "ntm_changes": json.loads(os.environ["FW_VCBC_NTM_CHANGES"]),
    "ntm_conflicts": json.loads(os.environ["FW_VCBC_NTM_CONFLICTS"]),
}
print(json.dumps(payload, sort_keys=True))
PY
}

if [ "$JSON_OUT" -eq 1 ]; then
  export FW_VCBC_VERSION="$VERSION"
  export FW_VCBC_REPO="$REPO_ABS"
  export FW_VCBC_BEAD="$BEAD"
  export FW_VCBC_EVIDENCE="$EVIDENCE_ABS"
  export FW_VCBC_MODE="$MODE"
  export FW_VCBC_VERDICT="$VERDICT"
  export FW_VCBC_FAIL="$FAIL"
  export FW_VCBC_WARN="$WARN"
  export FW_VCBC_BRAND_STATUS="$BRAND_STATUS"
  export FW_VCBC_BRAND_REASON="$BRAND_REASON"
  export FW_VCBC_SNIFF_STATUS="$SNIFF_STATUS"
  export FW_VCBC_SNIFF_REASON="$SNIFF_REASON"
  export FW_VCBC_JEFF_STATUS="$JEFF_STATUS"
  export FW_VCBC_JEFF_REASON="$JEFF_REASON"
  export FW_VCBC_PUBLIC_STATUS="$PUBLIC_STATUS"
  export FW_VCBC_PUBLIC_REASON="$PUBLIC_REASON"
  export FW_VCBC_REWORK_ACTION="$REWORK_ACTION"
  export FW_VCBC_REWORK_BEAD="$REWORK_BEAD"
  export FW_VCBC_NTM_CHANGES="$NTM_CHANGES_JSON"
  export FW_VCBC_NTM_CONFLICTS="$NTM_CONFLICTS_JSON"
  emit_json
else
  echo "=== validate-callback-before-close: $BEAD ==="
  echo "repo: $REPO_ABS"
  echo "evidence: $EVIDENCE_ABS"
  echo "mode: $MODE"
  echo "failures: $FAIL"
  echo "warnings: $WARN"
  echo "four_lens: brand=$BRAND_STATUS sniff=$SNIFF_STATUS jeff=$JEFF_STATUS public=$PUBLIC_STATUS"
  echo "ntm_changes: $(printf '%s\n' "$NTM_CHANGES_JSON" | jq -c '{status:(.status // "ok"), changed_count:(.changed_count // .count // (.changes // [] | length) // 0)}' 2>/dev/null || printf 'null')"
  echo "ntm_conflicts: $(printf '%s\n' "$NTM_CONFLICTS_JSON" | jq -c '{status:(.status // "ok"), conflict_count:(.conflict_count // .count // (.conflicts // [] | length) // 0)}' 2>/dev/null || printf 'null')"
  [ -n "$FAILURES" ] && { echo "FAIL:"; printf '%s\n' "$FAILURES" | sed '/^$/d; s/^/  - /'; }
  [ -n "$WARNINGS" ] && { echo "WARN:"; printf '%s\n' "$WARNINGS" | sed '/^$/d; s/^/  - /'; }
  [ "$REWORK_ACTION" != "none" ] && echo "auto_rework: action=$REWORK_ACTION bead=${REWORK_BEAD:-none}"
  echo "VERDICT: $VERDICT"
fi

if [ "$VERDICT" = "BLOCK_CLOSE" ]; then
  exit 1
fi
exit 0
