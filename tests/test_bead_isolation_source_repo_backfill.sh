#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/scripts/backfill-source-repo.sh"
WRAPPER="$ROOT/.flywheel/scripts/br-create-validated.sh"
BR_BIN="${BR_BIN:-/Users/josh/.cargo/bin/br}"
TMP="$(mktemp -d -t ejw94-source-repo.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

repo="$TMP/flywheel"
mkdir -p "$repo"
repo="$(cd "$repo" && pwd -P)"
git -C "$repo" init -q
(cd "$repo" && "$BR_BIN" init --prefix flywheel >/dev/null)

id_basename="$(cd "$repo" && "$BR_BIN" create "basename source_repo fixture" --type task --priority P2 --description fixture --json | jq -r '.id')"
id_other="$(cd "$repo" && "$BR_BIN" create "foreign source_repo fixture" --type task --priority P2 --description fixture --json | jq -r '.id')"

sqlite3 "$repo/.beads/beads.db" "UPDATE issues SET source_repo = 'flywheel' WHERE id = '$id_basename';"
sqlite3 "$repo/.beads/beads.db" "UPDATE issues SET source_repo = '/Users/josh/Developer/alpsinsurance' WHERE id = '$id_other';"

dry="$TMP/dry.json"
"$SCRIPT" --repo "$repo" --dry-run --json >"$dry"
jq -e '.dry_run == true and .scanned == 1 and .databases_needing_update == 1 and .repos[0].needs_update == 1' "$dry" >/dev/null || {
  jq . "$dry" >&2
  fail "dry-run did not classify basename source_repo"
}
[[ "$(sqlite3 "$repo/.beads/beads.db" "SELECT COUNT(*) FROM issues WHERE source_repo='flywheel';")" == "1" ]] || fail "dry-run mutated basename row"

apply="$TMP/apply.json"
"$SCRIPT" --repo "$repo" --json >"$apply"
jq -e '.dry_run == false and .scanned == 1 and .databases_needing_update == 1 and .repos[0].remaining_leaks == 1' "$apply" >/dev/null || {
  jq . "$apply" >&2
  fail "apply did not leave only true foreign leak"
}
[[ "$(sqlite3 "$repo/.beads/beads.db" "SELECT COUNT(*) FROM issues WHERE id = '$id_basename' AND source_repo = '$repo';")" == "1" ]] || fail "basename row not canonicalized"
[[ "$(sqlite3 "$repo/.beads/beads.db" "SELECT COUNT(*) FROM issues WHERE source_repo='/Users/josh/Developer/alpsinsurance';")" == "1" ]] || fail "foreign row should remain for doctor leakage"

wrapper_body="$TMP/wrapper-body.md"
cat >"$wrapper_body" <<'EOF'
Acceptance gates
AG1: tests assert wrapper source_repo stays canonical.
EOF
id_wrapper="$(cd "$repo" && "$WRAPPER" --title "post-backfill wrapper source_repo fixture" --type task --priority P2 --description-file "$wrapper_body" --json | jq -r '.id // .issue.id')"
[[ -n "$id_wrapper" && "$id_wrapper" != "null" ]] || fail "wrapper did not return created id"
[[ "$(sqlite3 "$repo/.beads/beads.db" "SELECT source_repo FROM issues WHERE id = '$id_wrapper';")" == "$repo" ]] || fail "wrapper-created row source_repo not canonical"
[[ "$(jq -r --arg id "$id_wrapper" 'select(.id == $id) | .source_repo' "$repo/.beads/issues.jsonl" | tail -1)" == "$repo" ]] || fail "wrapper-created JSONL source_repo not canonical"
[[ "$(sqlite3 "$repo/.beads/beads.db" "SELECT COUNT(*) FROM issues WHERE source_repo IS NULL OR source_repo != '$repo';")" == "1" ]] || fail "wrapper create reintroduced basename leakage after backfill"

printf 'PASS bead_isolation_source_repo_backfill\n'
