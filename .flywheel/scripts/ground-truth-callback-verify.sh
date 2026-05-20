#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
#
# ground-truth-callback-verify.sh
# Orchestrator-side ground-truth probe for worker DONE callbacks.
#
# Implements Duty 5b of flywheel:1's five-duty mission contract (bead
# flywheel-vy1yz). Born from the CFS:1 phantom-bead-creation incident
# 2026-05-20T19:38Z, where a Phase 4 DECOMPOSE callback claimed "10 beads
# created + 5 deps" and Phase 5 POLISH claimed "3 sweeps + 12 br updates + 26
# br comments" — but `br list` confirmed NONE existed. The plan-space
# artifacts (04-BEADS-DAG.md, 05-POLISH-FINAL.md) were substantive but
# described a DB state never realized. LLM workers produce convincing
# callback prose; the model is not the world.
#
# Input: a callback JSON envelope (or a file containing one). Either a strict
# JSON object, or a raw "DONE ... key=value" callback line — the parser
# accepts both.
#
# Operations probed (claim → ground-truth check):
#   beads_filed / beads_updated → `br show <id> --json`
#   commit_sha                  → `git log <sha> -1`
#   evidence (path)             → [[ -f <path> ]] && size > 0
#   files_reserved/released     → realpath exists (reservation history out of
#                                  scope: agent-mail records are append-only
#                                  and may have rotated)
#   pr_url                      → `gh pr view <num> --json state`
#
# Output: JSON
#   {
#     "schema_version": "ground-truth-callback-verify/v1",
#     "verified": true|false,
#     "per_op_results": [
#       {"op": "...", "claimed_value": "...", "actual_value": "...",
#        "verified": true|false, "reason": "..."}
#     ],
#     "reasons_for_failure": [...]
#   }
#
# Exit 0 = verified, 1 = drift detected, 2 = parse error.
#
# Read-only against the world; never mutates state.

set -euo pipefail

VERSION="ground-truth-callback-verify.v1.0.0"
SCHEMA_VERSION="ground-truth-callback-verify/v1"

CALLBACK_FILE=""
CALLBACK_INLINE=""
JSON_OUT=1   # JSON is the canonical surface; --human flips it off

usage() {
  cat <<'EOF'
usage:
  ground-truth-callback-verify.sh --callback-file PATH [--human]
  ground-truth-callback-verify.sh --callback "DONE bead-id key=val ..."

exit codes:
  0  every claimed op verified against ground truth
  1  drift detected — one or more claims unverifiable
  2  parse error or missing required tool

emits JSON receipt on stdout (schema: ground-truth-callback-verify/v1).
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --callback-file) CALLBACK_FILE="$2"; shift 2 ;;
    --callback)      CALLBACK_INLINE="$2"; shift 2 ;;
    --human)         JSON_OUT=0; shift ;;
    --json)          JSON_OUT=1; shift ;;
    -h|--help)       usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if ! command -v jq >/dev/null 2>&1; then
  echo "FATAL: jq is required" >&2
  exit 2
fi

# Load callback text
CB_TEXT=""
if [[ -n "$CALLBACK_FILE" ]]; then
  if [[ ! -f "$CALLBACK_FILE" ]]; then
    echo "FATAL: callback file not found: $CALLBACK_FILE" >&2
    exit 2
  fi
  CB_TEXT="$(cat "$CALLBACK_FILE")"
elif [[ -n "$CALLBACK_INLINE" ]]; then
  CB_TEXT="$CALLBACK_INLINE"
else
  echo "FATAL: --callback-file or --callback required" >&2
  usage >&2
  exit 2
fi

# Extract key=value pairs. Accept both JSON-object form and raw "key=val ..."
# DONE/BLOCKED lines.
extract_field() {
  # $1 = field name. Echo value (possibly empty). Newline-stripped.
  local key="$1"
  local val=""
  # Try JSON first
  if val="$(printf '%s' "$CB_TEXT" | jq -r --arg k "$key" 'if type=="object" then (.[$k] // empty) else empty end' 2>/dev/null)"; then
    if [[ -n "$val" && "$val" != "null" ]]; then
      printf '%s' "$val"
      return 0
    fi
  fi
  # Fall back to "key=value" extraction.
  # Match key=<value-without-spaces> OR key="quoted value".
  # Use awk for portable extraction.
  printf '%s' "$CB_TEXT" | awk -v key="$key" '
    {
      n = length($0)
      i = 1
      while (i <= n) {
        idx = index(substr($0, i), key "=")
        if (idx == 0) break
        start = i + idx - 1
        # Must be at line start or preceded by whitespace
        if (start > 1) {
          prev = substr($0, start-1, 1)
          if (prev != " " && prev != "\t") { i = start + length(key) + 1; continue }
        }
        vstart = start + length(key) + 1
        c = substr($0, vstart, 1)
        if (c == "\"") {
          # quoted
          rest = substr($0, vstart+1)
          q = index(rest, "\"")
          if (q == 0) exit
          print substr(rest, 1, q-1)
          exit
        }
        # unquoted: read up to whitespace
        rest = substr($0, vstart)
        m = match(rest, /[ \t\n]/)
        if (m == 0) { print rest; exit }
        print substr(rest, 1, m-1)
        exit
      }
    }'
}

# Per-op result accumulator (JSON array fragment list)
RESULTS_JSON='[]'
FAIL_REASONS_JSON='[]'

add_result() {
  # $1 op, $2 claimed, $3 actual, $4 verified (true|false), $5 reason
  local op="$1" claimed="$2" actual="$3" verified="$4" reason="$5"
  RESULTS_JSON="$(jq -c --arg op "$op" --arg cv "$claimed" --arg av "$actual" \
    --argjson verified "$verified" --arg reason "$reason" \
    '. + [{op:$op, claimed_value:$cv, actual_value:$av, verified:$verified, reason:$reason}]' \
    <<<"$RESULTS_JSON")"
  if [[ "$verified" != "true" ]]; then
    FAIL_REASONS_JSON="$(jq -c --arg r "$op: $reason" '. + [$r]' <<<"$FAIL_REASONS_JSON")"
  fi
}

split_csv() {
  # Echo each comma-separated value on its own line, trim spaces, skip
  # sentinel "none"/"NONE_*"/"UNAVAILABLE:*" tokens.
  local s="$1"
  printf '%s\n' "$s" | tr ',' '\n' | while IFS= read -r item; do
    item="${item## }"; item="${item%% }"
    [[ -z "$item" ]] && continue
    case "$item" in
      none|NONE_*|UNAVAILABLE:*|null) continue ;;
    esac
    printf '%s\n' "$item"
  done
}

###############################################################################
# Probe: beads_filed / beads_updated
###############################################################################
probe_beads() {
  local op="$1" raw="$2"
  if [[ -z "$raw" || "$raw" == "none" || "$raw" == "null" ]]; then
    return 0
  fi
  if ! command -v br >/dev/null 2>&1; then
    add_result "$op" "$raw" "br_not_on_PATH" "false" "br CLI unavailable; cannot verify"
    return 0
  fi
  local id
  while IFS= read -r id; do
    [[ -z "$id" ]] && continue
    local br_json br_err actual_status
    br_json="$(br show "$id" --json 2>/dev/null || true)"
    br_err="$(printf '%s' "$br_json" | jq -r '.error.code // ""' 2>/dev/null || true)"
    if [[ -z "$br_json" || "$br_err" == "ISSUE_NOT_FOUND" || "$br_err" != "" ]]; then
      add_result "$op:$id" "$id" "missing" "false" "bead not found via br show (error=${br_err:-empty})"
    else
      actual_status="$(printf '%s' "$br_json" | jq -r '.status // "unknown"' 2>/dev/null || echo unknown)"
      add_result "$op:$id" "$id" "$actual_status" "true" "bead exists"
    fi
  done < <(split_csv "$raw")
}

###############################################################################
# Probe: commit_sha
###############################################################################
probe_commit_sha() {
  local sha="$1"
  if [[ -z "$sha" || "$sha" == "none" || "$sha" == "null" || "$sha" == "skipped" ]]; then
    return 0
  fi
  if ! command -v git >/dev/null 2>&1; then
    add_result "commit_sha" "$sha" "git_not_on_PATH" "false" "git unavailable"
    return 0
  fi
  if git log -1 --format=%H "$sha" >/dev/null 2>&1; then
    local actual
    actual="$(git log -1 --format=%H "$sha" 2>/dev/null)"
    add_result "commit_sha" "$sha" "$actual" "true" "commit reachable"
  else
    add_result "commit_sha" "$sha" "missing" "false" "commit SHA not found in repo history"
  fi
}

###############################################################################
# Probe: evidence path (file exists + non-empty)
###############################################################################
probe_evidence_path() {
  local p="$1"
  if [[ -z "$p" || "$p" == "none" || "$p" == "null" ]]; then
    return 0
  fi
  if [[ -f "$p" ]]; then
    local size
    size="$(wc -c < "$p" 2>/dev/null | tr -d ' ')"
    if [[ -n "$size" && "$size" -gt 0 ]]; then
      add_result "evidence" "$p" "exists size=${size}" "true" "file exists and non-empty"
    else
      add_result "evidence" "$p" "exists size=0" "false" "file exists but empty"
    fi
  else
    add_result "evidence" "$p" "missing" "false" "evidence path does not exist on disk"
  fi
}

###############################################################################
# Probe: files_reserved / files_released — existence check only.
# Reservation history is append-only in agent-mail and may have rotated;
# verifying paths exist (or existed when written) is the most we can
# reliably claim post-hoc. We surface this limitation in `reason`.
###############################################################################
probe_files() {
  local op="$1" raw="$2"
  if [[ -z "$raw" || "$raw" == "none" || "$raw" == "null" ]]; then
    return 0
  fi
  local p
  while IFS= read -r p; do
    [[ -z "$p" ]] && continue
    if [[ -e "$p" ]]; then
      add_result "$op:$p" "$p" "exists" "true" "path exists on disk"
    else
      add_result "$op:$p" "$p" "missing" "false" "claimed path does not exist (may have been deleted post-release)"
    fi
  done < <(split_csv "$raw")
}

###############################################################################
# Probe: pr_url
###############################################################################
probe_pr_url() {
  local url="$1"
  if [[ -z "$url" || "$url" == "none" || "$url" == "null" ]]; then
    return 0
  fi
  if ! command -v gh >/dev/null 2>&1; then
    add_result "pr_url" "$url" "gh_not_on_PATH" "false" "gh CLI unavailable; cannot verify"
    return 0
  fi
  # Extract PR number from URL (.../pull/<n>) — let gh resolve owner/repo
  if gh pr view "$url" --json state,number >/dev/null 2>&1; then
    local state
    state="$(gh pr view "$url" --json state -q .state 2>/dev/null)"
    add_result "pr_url" "$url" "state=$state" "true" "PR exists on GitHub"
  else
    add_result "pr_url" "$url" "missing" "false" "gh pr view failed for URL"
  fi
}

###############################################################################
# Drive the probes
###############################################################################
BEADS_FILED="$(extract_field beads_filed)"
BEADS_UPDATED="$(extract_field beads_updated)"
COMMIT_SHA="$(extract_field commit_sha)"
EVIDENCE="$(extract_field evidence)"
FILES_RESERVED="$(extract_field files_reserved)"
FILES_RELEASED="$(extract_field files_released)"
PR_URL="$(extract_field pr_url)"
GIT_COMMITTED="$(extract_field git_committed)"

probe_beads "beads_filed" "$BEADS_FILED"
probe_beads "beads_updated" "$BEADS_UPDATED"
probe_commit_sha "$COMMIT_SHA"
probe_evidence_path "$EVIDENCE"
probe_files "files_reserved" "$FILES_RESERVED"
probe_files "files_released" "$FILES_RELEASED"
probe_pr_url "$PR_URL"

# If git_committed=yes but no commit_sha was provided, surface that gap.
if [[ "$GIT_COMMITTED" == "yes" && -z "$COMMIT_SHA" ]]; then
  add_result "git_committed" "yes" "no_commit_sha_in_envelope" "false" \
    "callback asserts git_committed=yes but supplied no commit_sha to verify"
fi

ANY_FAILED="$(jq 'any(.[]; .verified == false)' <<<"$RESULTS_JSON")"
if [[ "$ANY_FAILED" == "true" ]]; then
  VERIFIED="false"
else
  VERIFIED="true"
fi

RECEIPT="$(jq -n \
  --arg schema "$SCHEMA_VERSION" \
  --arg version "$VERSION" \
  --argjson verified "$VERIFIED" \
  --argjson per_op "$RESULTS_JSON" \
  --argjson reasons "$FAIL_REASONS_JSON" \
  '{schema_version:$schema, tool_version:$version, verified:$verified, per_op_results:$per_op, reasons_for_failure:$reasons}')"

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$RECEIPT"
else
  printf 'verified=%s\n' "$VERIFIED"
  printf '%s\n' "$RECEIPT" | jq -r '.per_op_results[] | "  \(.op): claimed=\(.claimed_value) actual=\(.actual_value) verified=\(.verified) reason=\(.reason)"'
fi

if [[ "$VERIFIED" == "true" ]]; then
  exit 0
fi
exit 1
