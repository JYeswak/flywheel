#!/usr/bin/env bash
set -euo pipefail

VERSION="mission-lock-negative-invariants-validator/v1"
MISSION_PATH="${MISSION_LOCK_NEGATIVE_INVARIANTS_MISSION:-.flywheel/MISSION.md}"
JSON_OUT=0
QUIET=0

for arg in "$@"; do
  [[ "$arg" == "--json" ]] && JSON_OUT=1
done

usage() {
  cat <<'USAGE'
usage:
  mission-lock-negative-invariants-validator.sh [MISSION.md] [--json] [--quiet]
  mission-lock-negative-invariants-validator.sh --info|--help|--examples [--json]

Validates that a mission lock declares the security negative invariants required
by SEC-001..SEC-006.

Exit codes:
  0  all invariants declared
  1  one or more invariants missing
  2  usage or unreadable mission file
USAGE
}

examples() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc '{examples:[
      "mission-lock-negative-invariants-validator.sh --json",
      "mission-lock-negative-invariants-validator.sh .flywheel/MISSION.md --quiet",
      "MISSION_LOCK_NEGATIVE_INVARIANTS_MISSION=/tmp/fixture.md mission-lock-negative-invariants-validator.sh --json"
    ]}'
  else
    cat <<'EXAMPLES'
mission-lock-negative-invariants-validator.sh --json
mission-lock-negative-invariants-validator.sh .flywheel/MISSION.md --quiet
MISSION_LOCK_NEGATIVE_INVARIANTS_MISSION=/tmp/fixture.md mission-lock-negative-invariants-validator.sh --json
EXAMPLES
  fi
}

info() {
  jq -nc --arg version "$VERSION" '{
    name:"mission-lock-negative-invariants-validator.sh",
    version:$version,
    schema_version:"mission-lock-negative-invariants-validator/v1",
    purpose:"read-only SEC-001..SEC-006 negative-invariant declaration validator",
    mutates:false,
    canonical_cli_flags:["--info","--help","--examples","--json","--quiet"],
    exit_codes:{"0":"pass","1":"fail","2":"usage"}
  }'
}

die_usage() {
  printf 'ERR: %s\n' "$1" >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --info) info; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    --examples) examples; exit 0 ;;
    --*) die_usage "unknown argument: $1" ;;
    *) MISSION_PATH="$1"; shift ;;
  esac
done

[[ -r "$MISSION_PATH" ]] || die_usage "mission file not readable: $MISSION_PATH"
BODY="$(<"$MISSION_PATH")"
TMP="$(mktemp "${TMPDIR:-/tmp}/mission-lock-negative-invariants.XXXXXX")"
trap 'rm -f "$TMP"' EXIT

check_terms() {
  local id="$1" summary="$2"
  shift 2
  local missing=() term status missing_json
  for term in "$@"; do
    if ! grep -Fqi -- "$term" <<<"$BODY"; then
      missing+=("$term")
    fi
  done
  if [[ "${#missing[@]}" -eq 0 ]]; then
    status="pass"
  else
    status="fail"
  fi
  if [[ "${#missing[@]}" -eq 0 ]]; then
    missing_json="[]"
  else
    missing_json="$(printf '%s\n' "${missing[@]}" | jq -R -s -c 'split("\n")[:-1]')"
  fi
  jq -nc \
    --arg id "$id" \
    --arg status "$status" \
    --arg summary "$summary" \
    --argjson missing_terms "$missing_json" \
    '{id:$id,status:$status,summary:$summary,missing_terms:$missing_terms}' >>"$TMP"
}

check_terms "SEC-001" "dispatch packets ban credential-shaped payload values" \
  "secret_values_allowed=false" "token fragments" "raw env output" "Agent Mail bearer"
check_terms "SEC-002" "credential-touching skill receipts prove safe execution" \
  "credential_touch" "safe_wrapper" "secret_value_allowed=false" "rotation_approval_source"
check_terms "SEC-003" "cross-orchestrator transfer boundary is redacted-only" \
  "skillos" "redacted evidence only" "customer-private evidence" "raw pane captures"
check_terms "SEC-004" "close-validator cannot mutate credential substrates" \
  "close-validator" "may not rotate tokens" ".env" "write vault values"
check_terms "SEC-005" "per-surface least-privilege principal metadata is required" \
  "secret source of truth" "principal" "allowed operations" "forbidden principals"
check_terms "SEC-006" "missing touched security invariants block readiness" \
  "blocked readiness" "customer-trust" "no-touch"

payload="$(
  jq -s \
    --arg version "$VERSION" \
    --arg path "$MISSION_PATH" \
    --argjson line_count "$(wc -l <"$MISSION_PATH" | tr -d ' ')" '
      {
        schema_version:$version,
        mission_path:$path,
        status:(if all(.[]; .status == "pass") then "pass" else "fail" end),
        line_count:$line_count,
        checks:.,
        receipt_schema_additions:{
          dispatch_template:["secret_values_allowed=false","credential_touch","safe_wrapper_required","redaction_required","no_raw_pane_secret_evidence"],
          skill_receipts:["credential_touch","safe_wrapper","secret_value_allowed=false","rotation_approval_source","joshua_explicit_rotation_approval"],
          surface_metadata:["secret source of truth","principal type","allowed operations","forbidden principals","service-role/admin credential policy"]
        }
      }' "$TMP"
)"

status="$(jq -r '.status' <<<"$payload")"
if [[ "$QUIET" -eq 0 ]]; then
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    jq -r '"status=\(.status) failed=\([.checks[] | select(.status==\"fail\") | .id] | join(\",\")) mission=\(.mission_path)"' <<<"$payload"
  fi
fi

[[ "$status" == "pass" ]]
