#!/usr/bin/env bash
# fleet-rotate-all-sessions.sh
#
# THE EASY BUTTON for codex key rollover across ALL ntm sessions.
#
# Usage:
#   fleet-rotate-all-sessions.sh                    # dry-run all sessions
#   fleet-rotate-all-sessions.sh --apply            # actually rotate everything
#   fleet-rotate-all-sessions.sh --apply --profile chiefzester
#                                                    # also activate the profile first
#
# What it does:
#   1. (optional) caam activate codex <profile>
#   2. For every ntm session: respawn all codex panes with the new key
#      (skips human_pane / orchestrator_pane / callback_pane per topology)
#   3. Prints a per-session summary
#
# Wraps fleet-rotate-on-caam-swap.sh — adds the per-session loop.

set -uo pipefail

APPLY=0
PROFILE=""
EXCLUDE_SESSIONS="${EXCLUDE_SESSIONS:-}"  # comma-separated, e.g. "skillos,vrtx"
ROTATOR="$HOME/Developer/flywheel/.flywheel/scripts/fleet-rotate-on-caam-swap.sh"

usage() {
  cat <<EOF
Usage: fleet-rotate-all-sessions.sh [options]

Options:
  --apply             actually rotate (default is dry-run)
  --profile NAME      activate codex profile NAME first
  --exclude S1,S2     comma-separated sessions to skip
  -h, --help          show this

Examples:
  # Dry-run, all sessions, current profile:
  fleet-rotate-all-sessions.sh

  # Activate chiefzester and rotate everything:
  fleet-rotate-all-sessions.sh --apply --profile chiefzester

  # Only flywheel + alps, skip the rest:
  EXCLUDE_SESSIONS=skillos,vrtx,mobile-eats,clutterfreespaces \\
    fleet-rotate-all-sessions.sh --apply
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --exclude) EXCLUDE_SESSIONS="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

if [ ! -x "$ROTATOR" ]; then
  echo "ERROR: rotator not found or not executable: $ROTATOR" >&2
  exit 1
fi

echo "================================================================"
echo "  fleet-rotate-all-sessions.sh"
echo "================================================================"
echo ""

# Step 1: profile activation
if [ -n "$PROFILE" ]; then
  echo "=== Activating codex profile: $PROFILE ==="
  if [ "$APPLY" -eq 1 ]; then
    caam activate codex "$PROFILE"
    caam status | head -10
  else
    echo "  [dry-run] would: caam activate codex $PROFILE"
  fi
  echo ""
fi

# Step 2: enumerate sessions
echo "=== Enumerating ntm sessions ==="
SESSIONS=$(/Users/josh/.local/bin/ntm list 2>/dev/null | awk -F: '/[a-z].*windows/ {gsub(/^ +/,"",$1); print $1}' | sort -u)
if [ -z "$SESSIONS" ]; then
  echo "ERROR: no ntm sessions found" >&2
  exit 1
fi
echo "  found:"
echo "$SESSIONS" | sed 's/^/    /'
echo ""

# Step 3: filter excludes
EXCLUDE_FILTER=""
if [ -n "$EXCLUDE_SESSIONS" ]; then
  EXCLUDE_FILTER=$(echo "$EXCLUDE_SESSIONS" | tr ',' '|')
  echo "  excluding: $EXCLUDE_SESSIONS"
fi

# Step 4: per-session loop
MODE="--dry-run"
[ "$APPLY" -eq 1 ] && MODE="--apply"

OK=0
FAIL=0
SKIPPED=0

for sess in $SESSIONS; do
  if [ -n "$EXCLUDE_FILTER" ] && echo "$sess" | grep -qE "^($EXCLUDE_FILTER)$"; then
    echo "=== [SKIP] $sess (excluded) ==="
    SKIPPED=$((SKIPPED + 1))
    continue
  fi
  echo "=== [$sess] rotating codex panes ($MODE) ==="
  if "$ROTATOR" --session="$sess" --panes=all-codex $MODE --json 2>&1 | tail -5; then
    OK=$((OK + 1))
  else
    echo "  [WARN] rotator returned non-zero for $sess"
    FAIL=$((FAIL + 1))
  fi
  echo ""
done

# Summary
echo "================================================================"
echo "  SUMMARY"
echo "================================================================"
echo "  ok:      $OK"
echo "  fail:    $FAIL"
echo "  skipped: $SKIPPED"
echo "  mode:    $MODE"
[ -n "$PROFILE" ] && echo "  profile: $PROFILE"
echo ""

if [ "$APPLY" -eq 0 ]; then
  echo "This was a DRY RUN. Re-run with --apply to actually rotate."
fi

exit 0
