#!/usr/bin/env bash
set -euo pipefail

VERSION="skill-enhance-jsm-discipline/v1"
JSM_BIN="${JSM_BIN:-jsm}"
MODE=""
PACKET=""
JSM_LIST_JSON=""
SKILLS_CSV=""
JSON_OUT=0

usage() {
  cat <<'EOF'
usage: skill-enhance-jsm-discipline.sh (--audit | --validate-packet PATH) [flags]

Flags:
  --skills a,b,c          Audit these skill names.
  --jsm-list-json PATH    Read fixture/snapshot JSON instead of live jsm list.
  --json                  Emit JSON.

Exit codes:
  0 pass
  1 validation refused
  2 usage or input error
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
  if [[ -n "$JSM_LIST_JSON" ]]; then
    [[ -r "$JSM_LIST_JSON" ]] || die "cannot read --jsm-list-json: $JSM_LIST_JSON"
    cat "$JSM_LIST_JSON"
  else
    local tmp pid waited timeout rc
    tmp="$(mktemp -t skill-enhance-jsm-list.XXXXXX)"
    timeout="${JSM_LIST_TIMEOUT_SEC:-20}"
    "$JSM_BIN" list --json >"$tmp" &
    pid=$!
    waited=0
    while kill -0 "$pid" 2>/dev/null; do
      if [[ "$waited" -ge "$timeout" ]]; then
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
        rm -f "$tmp"
        die "jsm list --json timed out after ${timeout}s"
      fi
      sleep 1
      waited=$((waited + 1))
    done
    wait "$pid" || {
      rc=$?
      rm -f "$tmp"
      return "$rc"
    }
    cat "$tmp"
    rm -f "$tmp"
  fi
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
  local list managed=() unmanaged=() absent=() records=()
  list="$(load_jsm_list)"
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
  jq -nc \
    --arg schema "$VERSION" \
    --argjson managed "$managed_json" \
    --argjson unmanaged "$unmanaged_json" \
    --argjson absent "$absent_json" \
    --argjson records "$records_json" \
    '{schema_version:$schema,status:"pass",mode:"audit",managed_count:($managed|length),unmanaged_count:($unmanaged|length),absent_count:($absent|length),managed:$managed,unmanaged:$unmanaged,absent:$absent,skills:$records}'
}

validate_packet() {
  [[ -r "$PACKET" ]] || die "cannot read packet: $PACKET"
  local list skills=() errors=() reports=()
  list="$(load_jsm_list)"
  while IFS= read -r skill; do
    skills+=("$skill")
  done < <(extract_packet_skills "$PACKET")

  if ! grep -Fqi 'skill-enhance' "$PACKET" 2>/dev/null &&
    ! grep -Fqi '/.claude/skills/' "$PACKET" 2>/dev/null &&
    ! grep -Fqi '~/.claude/skills/' "$PACKET" 2>/dev/null &&
    ! grep -Fqi '/Users/josh/.claude/skills/' "$PACKET" 2>/dev/null; then
    jq -nc --arg schema "$VERSION" '{schema_version:$schema,status:"pass",mode:"validate-packet",reason:"not_skill_enhance"}'
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
    reports+=("$(jq -nc --arg skill "$skill" --argjson managed "$managed" --argjson direct "$direct" --argjson has_status "$has_status" --argjson has_push "$has_push" --argjson has_import "$has_import" '{skill:$skill,managed:($managed==1),direct_mutation:($direct==1),jsm_status_present:($has_status==1),push_ready_patch_present:($has_push==1),import_ready_patch_present:($has_import==1)}')")
  done

  local errors_json reports_json status
  errors_json="$(json_array "${errors[@]}")"
  reports_json="$(if [[ ${#reports[@]} -eq 0 ]]; then printf '[]'; else printf '%s\n' "${reports[@]}" | jq -s .; fi)"
  status="pass"
  [[ ${#errors[@]} -gt 0 ]] && status="refused"
  jq -nc --arg schema "$VERSION" --arg status "$status" --arg packet "$PACKET" --argjson errors "$errors_json" --argjson reports "$reports_json" \
    '{schema_version:$schema,status:$status,mode:"validate-packet",packet:$packet,errors:$errors,skills:$reports}'
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
