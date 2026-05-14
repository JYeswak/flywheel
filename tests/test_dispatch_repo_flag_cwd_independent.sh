#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
NTM="${NTM_BIN:-$HOME/.local/bin/ntm}"
TMP="$(mktemp -d -t dispatch-repo.XXXXXX)"
trap 'chmod -R u+w "$TMP" 2>/dev/null || true; find "$TMP" -depth -mindepth 1 -delete 2>/dev/null || true; rmdir "$TMP" 2>/dev/null || true' EXIT

if [[ ! -x "$NTM" ]]; then
  printf 'SKIP ntm_missing path=%s\n' "$NTM" >&2
  exit 77
fi

run_assign() {
  local cwd="$1" out="$2"
  (
    cd "$cwd"
    "$NTM" assign flywheel --repo "$ROOT" --dry-run --limit=5 --json
  ) >"$out"
}

normalize() {
  jq -S '{
    success,
    assignments: [(.data.assignments // [])[] | {bead_id, bead_title}],
    summary: {
      total_bead_count: .data.summary.total_bead_count,
      actionable_count: .data.summary.actionable_count,
      blocked_count: .data.summary.blocked_count
    }
  }' "$1"
}

run_assign / "$TMP/from-root.json"
run_assign "$TMP" "$TMP/from-tmp.json"

normalize "$TMP/from-root.json" >"$TMP/from-root.normalized.json"
normalize "$TMP/from-tmp.json" >"$TMP/from-tmp.normalized.json"

diff -u "$TMP/from-root.normalized.json" "$TMP/from-tmp.normalized.json" >/dev/null
jq -e '.success == true and (.assignments | type == "array") and (.summary.total_bead_count | type == "number")' "$TMP/from-root.normalized.json" >/dev/null

printf 'PASS dispatch_repo_flag_cwd_independent\n'
