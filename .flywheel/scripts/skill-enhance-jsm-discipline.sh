#!/usr/bin/env bash
set -euo pipefail

VERSION="skill-enhance-jsm-discipline/v1"
JSM_BIN="${JSM_BIN:-jsm}"
MODE=""
PACKET=""
JSM_LIST_JSON=""
SKILLS_CSV=""
JSON_OUT=0
# JSM list availability state — set by load_jsm_list. Values:
#   live    — `jsm list` returned within the timeout
#   fixture — read from --jsm-list-json or JSM_LIST_JSON env
#   unavailable — timeout, command missing, or non-JSON output
#   offline — JSM_OFFLINE=1 set; live call skipped intentionally
JSM_LIST_STATUS=""
JSM_LIST_REASON=""

usage() {
  cat <<'EOF'
usage: skill-enhance-jsm-discipline.sh (--audit | --validate-packet PATH) [flags]

Flags:
  --skills a,b,c          Audit these skill names.
  --jsm-list-json PATH    Read fixture/snapshot JSON instead of live jsm list.
  --json                  Emit JSON.

Env:
  JSM_BIN                 jsm binary (default: jsm)
  JSM_LIST_TIMEOUT_SEC    bound on live `jsm list --json` (default: 10)
  JSM_LIST_JSON           same as --jsm-list-json
  JSM_OFFLINE=1           skip the live call, emit status=skipped/jsm_list_status=offline

Exit codes:
  0 pass | skipped (JSM unavailable/offline — distinguishable via jsm_list_status)
  1 validation refused
  2 usage or input error

JSM availability is surfaced on every emission as `jsm_list_status` ∈
{live, fixture, unavailable, offline} so workers never have to guess
whether a missing managed/unmanaged classification means "ok" or
"could not determine".
EOF
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 2
}

json_array() {
  if [[ "$#" -eq 0 ]]; then
    printf '[]\n'
  else
    printf '%s\n' "$@" | jq -R . | jq -s .
  fi
}

load_jsm_list() {
  # Always emits valid JSON on stdout. Sets $JSM_LIST_STATUS to one of
  # live|fixture|unavailable|offline so the caller can distinguish a
  # successful classification from "we could not determine". Never
  # exits the worker on JSM transport failure — workers must not hang
  # on substrate flake (bead flywheel-odugq).
  if [[ "${JSM_OFFLINE:-0}" == "1" ]]; then
    JSM_LIST_STATUS="offline"
    JSM_LIST_REASON="JSM_OFFLINE=1"
    printf '{"skills":[]}\n'
    return 0
  fi
  if [[ -n "$JSM_LIST_JSON" ]]; then
    if [[ -r "$JSM_LIST_JSON" ]]; then
      JSM_LIST_STATUS="fixture"
      JSM_LIST_REASON="--jsm-list-json=$JSM_LIST_JSON"
      cat "$JSM_LIST_JSON"
    else
      JSM_LIST_STATUS="unavailable"
      JSM_LIST_REASON="cannot read --jsm-list-json: $JSM_LIST_JSON"
      printf '{"skills":[]}\n'
    fi
    return 0
  fi
  if ! command -v "$JSM_BIN" >/dev/null 2>&1; then
    JSM_LIST_STATUS="unavailable"
    JSM_LIST_REASON="jsm binary not on PATH"
    printf '{"skills":[]}\n'
    return 0
  fi
  local tmp pid waited timeout rc=0
  tmp="$(mktemp -t skill-enhance-jsm-list.XXXXXX)"
  timeout="${JSM_LIST_TIMEOUT_SEC:-10}"
  "$JSM_BIN" list --json >"$tmp" 2>/dev/null &
  pid=$!
  waited=0
  while kill -0 "$pid" 2>/dev/null; do
    if [[ "$waited" -ge "$timeout" ]]; then
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      rm -f "$tmp"
      JSM_LIST_STATUS="unavailable"
      JSM_LIST_REASON="jsm list --json timed out after ${timeout}s"
      printf '{"skills":[]}\n'
      return 0
    fi
    sleep 1
    waited=$((waited + 1))
  done
  wait "$pid" || rc=$?
  if [[ "$rc" -ne 0 ]]; then
    rm -f "$tmp"
    JSM_LIST_STATUS="unavailable"
    JSM_LIST_REASON="jsm list --json exited ${rc}"
    printf '{"skills":[]}\n'
    return 0
  fi
  if ! jq -e . >/dev/null 2>&1 <"$tmp"; then
    rm -f "$tmp"
    JSM_LIST_STATUS="unavailable"
    JSM_LIST_REASON="jsm list --json returned non-JSON"
    printf '{"skills":[]}\n'
    return 0
  fi
  JSM_LIST_STATUS="live"
  JSM_LIST_REASON="jsm list --json (${waited}s)"
  cat "$tmp"
  rm -f "$tmp"
}

skill_names_from_csv() {
  tr ',' '\n' <<<"$SKILLS_CSV" | sed '/^[[:space:]]*$/d' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

extract_packet_skills() {
  local packet="$1"
  {
    grep -Eo '/Users/josh/\.claude/skills/[^/[:space:]`"]+' "$packet" 2>/dev/null |
      sed -E 's#^/Users/josh/\.claude/skills/##'
    grep -Eo '~/\.claude/skills/[^/[:space:]`"]+' "$packet" 2>/dev/null |
      sed -E 's#^~/\.claude/skills/##'
    grep -Eo '\.claude/skills/[^/[:space:]`"]+' "$packet" 2>/dev/null |
      sed -E 's#^\.claude/skills/##'
    awk -F'`' '/^Skill:[[:space:]]*`[^`]+`/ {print $2}' "$packet" 2>/dev/null
    awk -F'[: ]+' '/^Skill:[[:space:]]*[A-Za-z0-9._-]+/ {print $2}' "$packet" 2>/dev/null
  } | sed '/^[[:space:]]*$/d' | sort -u
}

skill_record() {
  local skill="$1" list="$2"
  jq -c --arg name "$skill" '(.skills // []) | map(select(.name == $name)) | .[0] // {}' <<<"$list"
}

skill_is_managed() {
  jq -e '
    (.name? != null)
    and (((.is_saved // false) == true)
      or ((.is_jeffreys // false) == true)
      or ((.installed_at // "") != ""))
  ' >/dev/null
}

packet_has_direct_mutation() {
  local packet="$1" skill="$2"
  grep -Eiq "(edit|modify|mutate|patch|write|update).*${skill}/SKILL[.]md" "$packet" 2>/dev/null ||
    grep -Eiq "direct (live )?(skill )?mutation" "$packet" 2>/dev/null
}

packet_has_jsm_status() {
  local packet="$1" skill="$2"
  grep -Fqi "jsm status $skill" "$packet" 2>/dev/null ||
    grep -Fqi "jsm show $skill" "$packet" 2>/dev/null ||
    grep -Fqi "jsm status <skill-name>" "$packet" 2>/dev/null
}

packet_has_push_ready_patch() {
  local packet="$1"
  grep -Eiq 'jsm[-_ ]push[-_ ]ready|push-ready patch|jsm push ready' "$packet" 2>/dev/null
}

packet_has_import_ready_patch() {
  local packet="$1"
  grep -Eiq 'jsm[-_ ]import[-_ ]ready|import-ready artifact|jsm import ready' "$packet" 2>/dev/null
}

packet_forbids_live_mutation() {
  local packet="$1"
  grep -Eiq 'do not mutate live|do not edit JSM-managed|direct mutation forbidden|rather than direct unmanaged mutation|patch artifact, do not mutate live' "$packet" 2>/dev/null
}

emit_audit() {
  local list managed=() unmanaged=() absent=() records=() jsm_buf
  jsm_buf="$(mktemp -t skill-enhance-jsm-buf.XXXXXX)"
  load_jsm_list >"$jsm_buf"
  list="$(cat "$jsm_buf")"
  rm -f "$jsm_buf"
  while IFS= read -r skill; do
    [[ -n "$skill" ]] || continue
    local rec
    rec="$(skill_record "$skill" "$list")"
    if jq -e '.name? == null' <<<"$rec" >/dev/null; then
      absent+=("$skill")
      unmanaged+=("$skill")
    elif skill_is_managed <<<"$rec"; then
      managed+=("$skill")
    else
      unmanaged+=("$skill")
    fi
    records+=("$(jq -nc --arg skill "$skill" --argjson record "$rec" '{skill:$skill,record:$record,managed:(($record.name? != null) and (($record.is_saved // false) or ($record.is_jeffreys // false) or (($record.installed_at // "") != "")))}')")
  done < <(skill_names_from_csv)

  local managed_json unmanaged_json absent_json records_json
  managed_json="$(json_array "${managed[@]}")"
  unmanaged_json="$(json_array "${unmanaged[@]}")"
  absent_json="$(json_array "${absent[@]}")"
  records_json="$(if [[ ${#records[@]} -eq 0 ]]; then printf '[]'; else printf '%s\n' "${records[@]}" | jq -s .; fi)"
  local status_value="pass"
  if [[ "$JSM_LIST_STATUS" == "unavailable" || "$JSM_LIST_STATUS" == "offline" ]]; then
    status_value="skipped"
  fi
  jq -nc \
    --arg schema "$VERSION" \
    --arg status_value "$status_value" \
    --arg jsm_list_status "$JSM_LIST_STATUS" \
    --arg jsm_list_reason "$JSM_LIST_REASON" \
    --argjson managed "$managed_json" \
    --argjson unmanaged "$unmanaged_json" \
    --argjson absent "$absent_json" \
    --argjson records "$records_json" \
    '{schema_version:$schema,status:$status_value,mode:"audit",jsm_list_status:$jsm_list_status,jsm_list_reason:$jsm_list_reason,managed_count:($managed|length),unmanaged_count:($unmanaged|length),absent_count:($absent|length),managed:$managed,unmanaged:$unmanaged,absent:$absent,skills:$records}'
}

validate_packet() {
  [[ -r "$PACKET" ]] || die "cannot read packet: $PACKET"
  local list skills=() errors=() reports=() jsm_buf
  jsm_buf="$(mktemp -t skill-enhance-jsm-buf.XXXXXX)"
  load_jsm_list >"$jsm_buf"
  list="$(cat "$jsm_buf")"
  rm -f "$jsm_buf"
  while IFS= read -r skill; do
    skills+=("$skill")
  done < <(extract_packet_skills "$PACKET")

  if ! grep -Fqi 'skill-enhance' "$PACKET" 2>/dev/null &&
    ! grep -Fqi '/.claude/skills/' "$PACKET" 2>/dev/null &&
    ! grep -Fqi '~/.claude/skills/' "$PACKET" 2>/dev/null &&
    ! grep -Fqi '/Users/josh/.claude/skills/' "$PACKET" 2>/dev/null; then
    jq -nc --arg schema "$VERSION" --arg jsm_list_status "$JSM_LIST_STATUS" --arg jsm_list_reason "$JSM_LIST_REASON" \
      '{schema_version:$schema,status:"pass",mode:"validate-packet",reason:"not_skill_enhance",jsm_list_status:$jsm_list_status,jsm_list_reason:$jsm_list_reason}'
    return 0
  fi

  # If JSM is unavailable or explicitly offline, we cannot classify
  # managed-vs-unmanaged. Emit a stable skipped status so the worker
  # has a single, distinguishable signal it can route on without
  # hanging or guessing. The skill list and direct-mutation
  # observations are still surfaced for evidence.
  if [[ "$JSM_LIST_STATUS" == "unavailable" || "$JSM_LIST_STATUS" == "offline" ]]; then
    local skipped_skills_json
    if [[ ${#skills[@]} -eq 0 ]]; then
      skipped_skills_json='[]'
    else
      skipped_skills_json="$(printf '%s\n' "${skills[@]}" \
        | jq -R '{skill:., jsm_status:"unavailable", managed:null, direct_mutation:null}' \
        | jq -s .)"
    fi
    jq -nc --arg schema "$VERSION" --arg packet "$PACKET" \
      --arg jsm_list_status "$JSM_LIST_STATUS" --arg jsm_list_reason "$JSM_LIST_REASON" \
      --argjson skills "$skipped_skills_json" \
      '{schema_version:$schema,status:"skipped",mode:"validate-packet",packet:$packet,reason:"jsm_unavailable",jsm_list_status:$jsm_list_status,jsm_list_reason:$jsm_list_reason,errors:[],skills:$skills}'
    return 0
  fi

  if [[ ${#skills[@]} -eq 0 ]]; then
    errors+=("skill-enhance packet names no skill path")
  fi

  local skill rec managed direct has_status has_push has_import forbids
  for skill in "${skills[@]}"; do
    rec="$(skill_record "$skill" "$list")"
    managed=0
    if skill_is_managed <<<"$rec"; then managed=1; fi
    direct=0
    if packet_has_direct_mutation "$PACKET" "$skill"; then direct=1; fi
    has_status=0
    if packet_has_jsm_status "$PACKET" "$skill"; then has_status=1; fi
    has_push=0
    if packet_has_push_ready_patch "$PACKET"; then has_push=1; fi
    has_import=0
    if packet_has_import_ready_patch "$PACKET"; then has_import=1; fi
    forbids=0
    if packet_forbids_live_mutation "$PACKET"; then forbids=1; fi

    [[ "$has_status" -eq 1 ]] || errors+=("$skill missing pre-flight jsm status")
    if [[ "$managed" -eq 1 ]]; then
      [[ "$has_push" -eq 1 ]] || errors+=("$skill is JSM-managed and missing jsm-push-ready patch artifact")
      if [[ "$direct" -eq 1 && "$forbids" -ne 1 ]]; then
        errors+=("$skill is JSM-managed but packet allows direct live mutation")
      fi
    else
      [[ "$has_import" -eq 1 || "$has_push" -eq 1 ]] || errors+=("$skill is unmanaged and missing jsm-import-ready patch artifact")
    fi
    local jsm_status="unmanaged"
    [[ "$managed" -eq 1 ]] && jsm_status="managed"
    reports+=("$(jq -nc --arg skill "$skill" --arg jsm_status "$jsm_status" --argjson managed "$managed" --argjson direct "$direct" --argjson has_status "$has_status" --argjson has_push "$has_push" --argjson has_import "$has_import" '{skill:$skill,jsm_status:$jsm_status,managed:($managed==1),direct_mutation:($direct==1),jsm_status_present:($has_status==1),push_ready_patch_present:($has_push==1),import_ready_patch_present:($has_import==1)}')")
  done

  local errors_json reports_json status
  errors_json="$(json_array "${errors[@]}")"
  reports_json="$(if [[ ${#reports[@]} -eq 0 ]]; then printf '[]'; else printf '%s\n' "${reports[@]}" | jq -s .; fi)"
  status="pass"
  [[ ${#errors[@]} -gt 0 ]] && status="refused"
  jq -nc --arg schema "$VERSION" --arg status "$status" --arg packet "$PACKET" \
    --arg jsm_list_status "$JSM_LIST_STATUS" --arg jsm_list_reason "$JSM_LIST_REASON" \
    --argjson errors "$errors_json" --argjson reports "$reports_json" \
    '{schema_version:$schema,status:$status,mode:"validate-packet",packet:$packet,jsm_list_status:$jsm_list_status,jsm_list_reason:$jsm_list_reason,errors:$errors,skills:$reports}'
  [[ "$status" == "pass" ]]
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --audit) MODE="audit"; shift ;;
    --validate-packet) MODE="validate-packet"; PACKET="$2"; shift 2 ;;
    --skills) SKILLS_CSV="$2"; shift 2 ;;
    --jsm-list-json) JSM_LIST_JSON="$2"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; die "unknown arg: $1" ;;
  esac
done

command -v jq >/dev/null 2>&1 || die "jq not found"
case "$MODE" in
  audit)
    [[ -n "$SKILLS_CSV" ]] || die "--skills required for --audit"
    emit_audit
    ;;
  validate-packet)
    validate_packet
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
