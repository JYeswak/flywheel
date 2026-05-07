#!/usr/bin/env bash
set -euo pipefail

VERSION="dispatch-deferral-lint.v1"
REPO="$PWD"
SESSION="${SESSION:-flywheel}"
PANES="${PANES:-2,3,4}"
DRAFT="-"
SIGNALS=""
RECEIPT=""
JSON_OUT=0
THRESHOLD=3
REQUIRE_CANONICAL=0
NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
BR_BIN="${BR_BIN:-/Users/josh/.cargo/bin/br}"
BV_BIN="${BV_BIN:-/opt/homebrew/bin/bv}"
DOCTOR_BIN="${DOCTOR_BIN:-/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop}"

usage() {
  cat <<'EOF'
usage: dispatch-deferral-lint.sh [--draft FILE|-] [--repo PATH] [--session NAME] [--panes LIST] [--signals FILE] [--receipt FILE] [--require-canonical-dispatch] [--json]

Rejects question-shaped dispatch drafts when data already selects an action.
EOF
}

json_bool() {
  case "$1" in
    1|true|TRUE|yes|YES) printf 'true' ;;
    *) printf 'false' ;;
  esac
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --draft)
      DRAFT="${2:?--draft requires FILE}"
      shift 2
      ;;
    --repo)
      REPO="${2:?--repo requires PATH}"
      shift 2
      ;;
    --session)
      SESSION="${2:?--session requires NAME}"
      shift 2
      ;;
    --panes)
      PANES="${2:?--panes requires LIST}"
      shift 2
      ;;
    --signals)
      SIGNALS="${2:?--signals requires FILE}"
      shift 2
      ;;
    --receipt)
      RECEIPT="${2:?--receipt requires FILE}"
      shift 2
      ;;
    --threshold)
      THRESHOLD="${2:?--threshold requires INT}"
      shift 2
      ;;
    --require-canonical-dispatch)
      REQUIRE_CANONICAL=1
      shift
      ;;
    --json)
      JSON_OUT=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --version)
      printf '%s\n' "$VERSION"
      exit 0
      ;;
    *)
      printf 'ERR: unknown arg: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

TMP="$(mktemp -d -t deferral-lint.XXXXXX)"
trap 'rm -r "$TMP"' EXIT

if [ "$DRAFT" = "-" ]; then
  cat >"$TMP/draft.txt"
else
  [ -f "$DRAFT" ] || { printf 'ERR: draft not found: %s\n' "$DRAFT" >&2; exit 2; }
  cp "$DRAFT" "$TMP/draft.txt"
fi

draft_text="$(cat "$TMP/draft.txt")"
last_lines="$(awk 'NF { lines[++n]=$0 } END { start=n-4; if (start<1) start=1; for (i=start; i<=n; i++) print lines[i] }' "$TMP/draft.txt")"

question_shape=false
if printf '%s\n' "$last_lines" | grep -qiE '(^[[:space:]]*(Want me to|Should I|Do you want me to|Would you like me to|Can I|May I|What should I)\b.*\?$)|(^[[:space:]]*Joshua-decide between\b)|(^[[:space:]]*Which (one|option|path|bead|lane)\b.*\?$)|\?$'; then
  question_shape=true
fi

fail_reason=""
override_present=false

if printf '%s\n' "$draft_text" | grep -qE '(^|[[:space:]])evidence_missing([[:space:]]|$)'; then
  fail_reason="evidence_missing_named_datum_required"
fi

if printf '%s\n' "$draft_text" | grep -qE 'evidence_missing=[^[:space:]]+'; then
  override_present=true
fi

if printf '%s\n' "$draft_text" | grep -qE 'requires_joshua_decision=true'; then
  override_present=true
  blocker_reason="$(printf '%s\n' "$draft_text" | sed -nE 's/.*reason="([^"]+)".*/\1/p' | head -1)"
  case "$blocker_reason" in
    new-platform-or-vendor-not-in-mission-lock|secret-rotation-or-new-credential-creation|financial-commitment-above-mission-budget|legal-or-compliance-decision|destructive-irreversible-on-shared-state|paradigm-conflict-with-active-mission)
      ;;
    *)
      fail_reason="${fail_reason:-requires_joshua_decision_true_blocker_class_required}"
      ;;
  esac
fi

if printf '%s\n' "$draft_text" | grep -qE 'tie_between='; then
  override_present=true
  if ! printf '%s\n' "$draft_text" | grep -qE 'tie_between=[^[:space:],]+,[^[:space:]]+'; then
    fail_reason="${fail_reason:-tie_between_two_options_required}"
  elif ! printf '%s\n' "$draft_text" | grep -qE 'reason="[^"]+"' && ! printf '%s\n' "$draft_text" | grep -qE 'reason=[^[:space:]]+'; then
    fail_reason="${fail_reason:-tie_between_reason_required}"
  fi
fi

idle_worker_count=0
ready_work_count=0
pagerank_alignment=false
doctor_alignment=false
selected_action=""
doctor_status="unknown"

if [ -n "$SIGNALS" ]; then
  idle_worker_count="$(jq -r '.idle_worker_count // .idle_workers // 0' "$SIGNALS")"
  ready_work_count="$(jq -r '.ready_work_count // .ready_bead_count // 0' "$SIGNALS")"
  pagerank_alignment="$(jq -r 'if (.pagerank_alignment == true or (.pagerank_pick // "") != "") then "true" else "false" end' "$SIGNALS")"
  doctor_alignment="$(jq -r 'if (.doctor_alignment == true or .doctor_safe == true or (.doctor_action // "") != "") then "true" else "false" end' "$SIGNALS")"
  selected_action="$(jq -r '.selected_action // .suggested_action // .pagerank_pick // .doctor_action // empty' "$SIGNALS")"
  doctor_status="$(jq -r '.doctor_status // "fixture"' "$SIGNALS")"
else
  if command -v "$NTM_BIN" >/dev/null 2>&1; then
    "$NTM_BIN" --robot-activity="$SESSION" --panes="$PANES" >"$TMP/robot.json" 2>/dev/null || printf '{}\n' >"$TMP/robot.json"
    idle_worker_count="$(jq '[.agents[]? | select((.state == "WAITING") or (.activity == "idle"))] | length' "$TMP/robot.json" 2>/dev/null || printf '0')"
  fi
  if command -v "$BR_BIN" >/dev/null 2>&1; then
    (cd "$REPO" && "$BR_BIN" ready --json) >"$TMP/ready.json" 2>/dev/null || printf '[]\n' >"$TMP/ready.json"
    ready_work_count="$(jq 'length' "$TMP/ready.json" 2>/dev/null || printf '0')"
    selected_action="$(jq -r '.[0].id // empty' "$TMP/ready.json" 2>/dev/null || true)"
  fi
  if command -v "$BV_BIN" >/dev/null 2>&1; then
    (cd "$REPO" && "$BV_BIN" --robot-next) >"$TMP/bv.txt" 2>/dev/null || true
    if [ -s "$TMP/bv.txt" ]; then
      pagerank_alignment=true
      [ -n "$selected_action" ] || selected_action="$(head -1 "$TMP/bv.txt" | cut -c1-120)"
    fi
  fi
  if command -v "$DOCTOR_BIN" >/dev/null 2>&1; then
    "$DOCTOR_BIN" doctor --repo "$REPO" --json >"$TMP/doctor.json" 2>/dev/null || printf '{}\n' >"$TMP/doctor.json"
    doctor_status="$(jq -r '.status // .decision // "unknown"' "$TMP/doctor.json" 2>/dev/null || printf 'unknown')"
    if jq -e '(.status // "") | IN("pass","ok","warn","healthy")' "$TMP/doctor.json" >/dev/null 2>&1 || jq -e '(.action // .next_action // "") != ""' "$TMP/doctor.json" >/dev/null 2>&1; then
      doctor_alignment=true
    fi
  fi
fi

idle_point=0
ready_point=0
pagerank_point=0
doctor_point=0
[ "${idle_worker_count:-0}" -ge 1 ] 2>/dev/null && idle_point=1
[ "${ready_work_count:-0}" -ge 1 ] 2>/dev/null && ready_point=1
[ "$pagerank_alignment" = "true" ] && pagerank_point=1
[ "$doctor_alignment" = "true" ] && doctor_point=1
alignment_score=$((idle_point + ready_point + pagerank_point + doctor_point))

data_answers=false
if [ "$idle_point" -eq 1 ] && [ "$ready_point" -eq 1 ] && [ "$alignment_score" -ge "$THRESHOLD" ]; then
  data_answers=true
fi

canonical_ok=true
if [ "$REQUIRE_CANONICAL" -eq 1 ]; then
  canonical_ok=false
  if printf '%s\n' "$draft_text" | grep -q 'dispatch_skill_version=flywheel-dispatch/v2' \
    && printf '%s\n' "$draft_text" | grep -q 'callback_delivery_verified=true' \
    && printf '%s\n' "$draft_text" | grep -qE 'socraticode_queries=[0-9]+' \
    && printf '%s\n' "$draft_text" | grep -qE 'indexed_chunks_observed=[0-9]+' \
    && printf '%s\n' "$draft_text" | grep -qE 'files_reserved=' \
    && printf '%s\n' "$draft_text" | grep -qE 'files_released='; then
    canonical_ok=true
  else
    fail_reason="${fail_reason:-canonical_dispatch_contract_missing}"
  fi
fi

status="pass"
reason="ok"
if [ -n "$fail_reason" ]; then
  status="fail"
  reason="$fail_reason"
elif [ "$question_shape" = "true" ] && [ "$data_answers" = "true" ] && [ "$override_present" = "false" ]; then
  status="fail"
  reason="data_backed_deferral_violation"
elif [ "$question_shape" = "true" ] && [ "$override_present" = "true" ]; then
  reason="question_allowed_with_named_override"
elif [ "$data_answers" = "true" ]; then
  reason="data_answers_dispatch_directly"
fi

out="$(jq -nc \
  --arg schema_version "dispatch-deferral-lint/v1" \
  --arg version "$VERSION" \
  --arg status "$status" \
  --arg reason "$reason" \
  --arg selected_action "$selected_action" \
  --arg doctor_status "$doctor_status" \
  --argjson question_shape "$(json_bool "$question_shape")" \
  --argjson data_answers "$(json_bool "$data_answers")" \
  --argjson override_present "$(json_bool "$override_present")" \
  --argjson canonical_ok "$(json_bool "$canonical_ok")" \
  --argjson idle_worker_count "${idle_worker_count:-0}" \
  --argjson ready_work_count "${ready_work_count:-0}" \
  --argjson pagerank_alignment "$(json_bool "$pagerank_alignment")" \
  --argjson doctor_alignment "$(json_bool "$doctor_alignment")" \
  --argjson alignment_score "$alignment_score" \
  --argjson threshold "$THRESHOLD" \
  '{schema_version:$schema_version,version:$version,status:$status,reason:$reason,question_shape:$question_shape,data_answers:$data_answers,override_present:$override_present,idle_worker_count:$idle_worker_count,ready_work_count:$ready_work_count,pagerank_alignment:$pagerank_alignment,doctor_alignment:$doctor_alignment,doctor_status:$doctor_status,alignment_score:$alignment_score,threshold:$threshold,selected_action:$selected_action,canonical_dispatch_required:true,canonical_dispatch_contract_ok:$canonical_ok,flywheel_28v_selected_action:($selected_action != ""),flywheel_8i5_canonical_required:true}')"

if [ -n "$RECEIPT" ]; then
  mkdir -p "$(dirname "$RECEIPT")"
  printf '%s\n' "$out" >"$RECEIPT"
fi

if [ "$JSON_OUT" -eq 1 ]; then
  printf '%s\n' "$out"
else
  printf '%s %s\n' "$status" "$reason"
fi

[ "$status" = "pass" ]
