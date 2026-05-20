#!/usr/bin/env bash
set -euo pipefail

SOURCE="${SKILLOS_NTM_SEND_VERIFIED_SOURCE:-/Users/josh/Developer/skillos/.flywheel/scripts/ntm-send-verified.sh}"
CFS="${CFS_REPO:-/Users/josh/Developer/clutterfreespaces}"
PICOZ="${PICOZ_REPO:-/Users/josh/Developer/picoz}"
AUTH="${CROSS_REPO_AUTH:-/Users/josh/.flywheel/cross-repo-authorized-writes.json}"

pass_count=0
fail_count=0

pass() {
  pass_count=$((pass_count + 1))
  printf 'ok %d - %s\n' "$pass_count" "$1"
}

fail() {
  fail_count=$((fail_count + 1))
  printf 'not ok %d - %s\n' "$((pass_count + fail_count))" "$1" >&2
}

assert_file() {
  local path="$1" label="$2"
  if [[ -f "$path" ]]; then
    pass "$label"
  else
    fail "$label"
  fi
}

assert_executable() {
  local path="$1" label="$2"
  if [[ -x "$path" ]]; then
    pass "$label"
  else
    fail "$label"
  fi
}

assert_sha_match() {
  local path="$1" label="$2"
  local source_sha target_sha
  source_sha="$(shasum -a 256 "$SOURCE" | awk '{print $1}')"
  target_sha="$(shasum -a 256 "$path" | awk '{print $1}')"
  if [[ "$source_sha" == "$target_sha" ]]; then
    pass "$label"
  else
    fail "$label"
  fi
}

assert_text() {
  local path="$1" pattern="$2" label="$3"
  if rg -F -q "$pattern" "$path"; then
    pass "$label"
  else
    fail "$label"
  fi
}

assert_auth() {
  local repo="$1" label="$2"
  if jq -e --arg repo "$repo" '
    .authorizations[]
    | select(.session_repo == "/Users/josh/Developer/flywheel")
    | select(.peer_repo == $repo)
    | select((.scope_paths | index(".flywheel/scripts/ntm-send-verified.sh")) != null)
  ' "$AUTH" >/dev/null; then
    pass "$label"
  else
    fail "$label"
  fi
}

cfs_mirror="$CFS/.flywheel/scripts/ntm-send-verified.sh"
picoz_mirror="$PICOZ/.flywheel/scripts/ntm-send-verified.sh"
cfs_dispatch="$CFS/.flywheel/scripts/dispatch-and-verify.sh"
picoz_dispatch="$PICOZ/.flywheel/scripts/dispatch-and-verify.sh"
verifier_decl="NTM_SEND_VERIFIED=\"\${NTM_SEND_VERIFIED:-\$SCRIPT_DIR/ntm-send-verified.sh}\""
verified_send="\"\$NTM_SEND_VERIFIED\" \"\$SESSION\" --pane=\"\$PANE\" --no-cass-check -- \"\$PROMPT\""

assert_file "$SOURCE" "skillos canonical exists"
assert_file "$cfs_mirror" "clutterfreespaces mirror exists"
assert_file "$picoz_mirror" "picoz mirror exists"
assert_executable "$cfs_mirror" "clutterfreespaces mirror executable"
assert_executable "$picoz_mirror" "picoz mirror executable"
assert_sha_match "$cfs_mirror" "clutterfreespaces mirror sha-matches skillos"
assert_sha_match "$picoz_mirror" "picoz mirror sha-matches skillos"
assert_text "$cfs_dispatch" "$verifier_decl" "clutterfreespaces dispatch declares verifier"
assert_text "$cfs_dispatch" "$verified_send" "clutterfreespaces initial send uses verifier"
assert_text "$picoz_dispatch" "$verifier_decl" "picoz dispatch declares verifier"
assert_text "$picoz_dispatch" "$verified_send" "picoz initial send uses verifier"
assert_auth "/Users/josh/Developer/clutterfreespaces" "clutterfreespaces cross-repo write authorized"
assert_auth "/Users/josh/Developer/picoz" "picoz cross-repo write authorized"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
