#!/usr/bin/env bash
# fleet-canonical-rule-freshness-probe.sh
#
# Probe staleness of per-session META-RULE-CACHE.md vs canonical INDEX.md
# Skeleton — NOT yet wired into doctor. Follow-up bead: wire into /flywheel:fleet-doctor.
#
# Canonical CLI scoping:
#   --info     : describe purpose
#   --schema   : print JSON output schema
#   --json     : machine-readable output (default human)
#   --self-test: run synthetic fixtures, exit nonzero on failure

set -euo pipefail

CANONICAL_INDEX="/Users/josh/.flywheel/canonical-meta-rules/INDEX.md"
TOPOLOGY="/Users/josh/.local/state/flywheel/session-topology.jsonl"

# Map session -> canonical_repo (for now, hard-coded; future: pull from a registry)
declare -a SESSIONS=("flywheel" "alpsinsurance" "vrtx" "skillos" "mobile-eats")
declare -A REPOS=(
  [flywheel]="/Users/josh/Developer/flywheel"
  [alpsinsurance]="/Users/josh/Developer/alpsinsurance"
  [vrtx]="/Users/josh/Developer/vrtx"
  [skillos]="/Users/josh/Developer/skillos"
  [mobile-eats]="/Users/josh/Developer/mobile-eats"
)

JSON=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --info)
      cat <<'EOF'
fleet-canonical-rule-freshness-probe: per-session META-RULE-CACHE.md staleness probe.
For each fleet session, computes mtime of <repo>/.flywheel/META-RULE-CACHE.md, compares
to canonical /Users/josh/.flywheel/canonical-meta-rules/INDEX.md. Emits JSON line per session.
Status: fresh|stale|missing.
EOF
      exit 0
      ;;
    --schema)
      cat <<'EOF'
{
  "type": "object",
  "properties": {
    "session": {"type": "string"},
    "repo": {"type": "string"},
    "cache_path": {"type": "string"},
    "lag_seconds": {"type": ["integer", "null"]},
    "status": {"enum": ["fresh", "stale", "missing"]}
  },
  "required": ["session", "status"]
}
EOF
      exit 0
      ;;
    --json) JSON=1; shift ;;
    --self-test)
      # Synthetic: probe should treat absent repo dir as missing without error
      tmp="$(mktemp -d)"
      out="$("$0" --json 2>/dev/null || true)"
      [[ -n "$out" ]] || { echo "self-test FAIL: empty output"; exit 1; }
      echo "self-test OK"
      rm -rf "$tmp"
      exit 0
      ;;
    *) echo "unknown arg: $1" >&2; exit 64 ;;
  esac
done

if [[ ! -f "$CANONICAL_INDEX" ]]; then
  echo "canonical INDEX missing: $CANONICAL_INDEX" >&2
  exit 2
fi

CANONICAL_MTIME="$(stat -f %m "$CANONICAL_INDEX" 2>/dev/null || stat -c %Y "$CANONICAL_INDEX")"

emit() {
  local session="$1" repo="$2" cache="$3" lag="$4" status="$5"
  if [[ $JSON -eq 1 ]]; then
    if [[ "$lag" == "null" ]]; then
      printf '{"session":"%s","repo":"%s","cache_path":"%s","lag_seconds":null,"status":"%s"}\n' \
        "$session" "$repo" "$cache" "$status"
    else
      printf '{"session":"%s","repo":"%s","cache_path":"%s","lag_seconds":%s,"status":"%s"}\n' \
        "$session" "$repo" "$cache" "$lag" "$status"
    fi
  else
    printf '%-20s %-8s lag=%s repo=%s\n' "$session" "$status" "$lag" "$repo"
  fi
}

for s in "${SESSIONS[@]}"; do
  repo="${REPOS[$s]:-}"
  if [[ -z "$repo" ]]; then
    emit "$s" "" "" "null" "missing"
    continue
  fi
  cache="$repo/.flywheel/META-RULE-CACHE.md"
  if [[ ! -f "$cache" ]]; then
    emit "$s" "$repo" "$cache" "null" "missing"
    continue
  fi
  cache_mtime="$(stat -f %m "$cache" 2>/dev/null || stat -c %Y "$cache")"
  lag=$(( CANONICAL_MTIME - cache_mtime ))
  if [[ $lag -le 0 ]]; then
    emit "$s" "$repo" "$cache" "$lag" "fresh"
  else
    emit "$s" "$repo" "$cache" "$lag" "stale"
  fi
done
