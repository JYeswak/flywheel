#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/repo-hygiene-doctor.sh"
TMPDIR="$(mktemp -d)"
ASSERTIONS=0

cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

assert_eq() {
  local got="$1" expected="$2" label="$3"
  ASSERTIONS=$((ASSERTIONS + 1))
  if [[ "$got" != "$expected" ]]; then
    printf 'ASSERTION FAILED: %s\nexpected: %s\ngot: %s\n' "$label" "$expected" "$got" >&2
    exit 1
  fi
}

assert_nonempty() {
  local got="$1" label="$2"
  ASSERTIONS=$((ASSERTIONS + 1))
  if [[ -z "$got" || "$got" == "null" ]]; then
    printf 'ASSERTION FAILED: %s\nvalue was empty\n' "$label" >&2
    exit 1
  fi
}

git_init_repo() {
  local repo="$1"
  git init -q "$repo"
  git -C "$repo" config user.email "repo-hygiene-test@example.com"
  git -C "$repo" config user.name "Repo Hygiene Test"
  printf 'seed\n' > "$repo/README.md"
  git -C "$repo" add README.md
  git -C "$repo" commit -q -m "seed"
  git -C "$repo" branch -M main
}

WORKTREE_REPO="$TMPDIR/worktree-repo"
git_init_repo "$WORKTREE_REPO"
for n in 1 2 3 4; do
  git -C "$WORKTREE_REPO" worktree add -q -b "wt$n" "$TMPDIR/wt$n" main
done

THRESHOLDS="$TMPDIR/thresholds.yaml"
cat > "$THRESHOLDS" <<'YAML'
defaults:
  worktree_count_p2: 4
  worktree_count_p1: 10
  worktree_count_p0: 20
  stash_count_p2: 5
  stash_count_p1: 10
  stash_count_p0: 20
  local_only_merged_branch_count_p2: 10
  local_only_merged_branch_count_p1: 25
  local_only_merged_branch_count_p0: 50
  main_ff_drift_p2: 50
  main_ff_drift_p1: 100
  main_ff_drift_p0: 500
  tracked_substrate_bloat_mb_p2: 100
  tracked_substrate_bloat_mb_p1: 250
  tracked_substrate_bloat_mb_p0: 500
YAML

OUT="$("$SCRIPT" --repo "$WORKTREE_REPO" --thresholds "$THRESHOLDS" --json)"
assert_eq "$(jq -r '.metrics.worktree_count' <<<"$OUT")" "5" "synthetic repo N=5 worktrees metrics correct"
assert_eq "$(jq -r '.alerts[] | select(.class=="worktree-orphan") | .severity' <<<"$OUT")" "P2" "over-threshold alert fired"

REMOTE="$TMPDIR/remote.git"
DRIFT_REPO="$TMPDIR/drift-repo"
OTHER="$TMPDIR/other"
git_init_repo "$DRIFT_REPO"
git init -q --bare "$REMOTE"
git -C "$DRIFT_REPO" remote add origin "$REMOTE"
git -C "$DRIFT_REPO" push -q -u origin main
git clone -q -b main "$REMOTE" "$OTHER"
git -C "$OTHER" config user.email "repo-hygiene-test@example.com"
git -C "$OTHER" config user.name "Repo Hygiene Test"
printf 'remote\n' >> "$OTHER/README.md"
git -C "$OTHER" add README.md
git -C "$OTHER" commit -q -m "remote ahead"
git -C "$OTHER" push -q origin main
git -C "$DRIFT_REPO" fetch -q origin
DRIFT_OUT="$("$SCRIPT" --repo "$DRIFT_REPO" --thresholds "$THRESHOLDS" --json)"
assert_eq "$(jq -r '.metrics.main_ff_drift' <<<"$DRIFT_OUT")" "1" "synthetic repo main-FF-drift detected"

LEDGER="$TMPDIR/repo-hygiene.jsonl"
"$SCRIPT" --repo "$WORKTREE_REPO" --thresholds "$THRESHOLDS" --write-ledger --ledger "$LEDGER" --json >/dev/null
assert_eq "$(wc -l < "$LEDGER" | tr -d ' ')" "1" "tick ledger receives one envelope"

BR_STATE="$TMPDIR/br-state.json"
BR_LOG="$TMPDIR/br-create.log"
BR_STUB="$TMPDIR/br"
printf '{"issues":[]}\n' > "$BR_STATE"
touch "$BR_LOG"
cat > "$BR_STUB" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  list)
    cat "$BR_STUB_STATE"
    ;;
  create)
    title="${2:-}"
    printf '%s\n' "$title" >> "$BR_STUB_LOG"
    python3 - "$BR_STUB_STATE" "$title" <<'PY'
import json
import sys
from datetime import datetime, timezone

path, title = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as handle:
    payload = json.load(handle)
payload.setdefault("issues", []).append({
    "id": f"stub-{len(payload['issues']) + 1}",
    "title": title,
    "status": "open",
    "created_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
})
with open(path, "w", encoding="utf-8") as handle:
    json.dump(payload, handle)
print(json.dumps(payload["issues"][-1]))
PY
    ;;
  *)
    printf 'unsupported br stub call: %s\n' "$*" >&2
    exit 2
    ;;
esac
SH
chmod +x "$BR_STUB"

BR_STUB_STATE="$BR_STATE" BR_STUB_LOG="$BR_LOG" \
  "$SCRIPT" --repo "$WORKTREE_REPO" --thresholds "$THRESHOLDS" --auto-bead --br-bin "$BR_STUB" --json >/dev/null
assert_eq "$(wc -l < "$BR_LOG" | tr -d ' ')" "1" "auto-file triggers under breach -> bead created"

BR_STUB_STATE="$BR_STATE" BR_STUB_LOG="$BR_LOG" \
  "$SCRIPT" --repo "$WORKTREE_REPO" --thresholds "$THRESHOLDS" --auto-bead --br-bin "$BR_STUB" --json >/dev/null
assert_eq "$(wc -l < "$BR_LOG" | tr -d ' ')" "1" "idempotent rerun <24h -> no duplicate"

mkdir -p "$WORKTREE_REPO/.flywheel"
touch "$WORKTREE_REPO/.flywheel/hygiene-tick.disabled"
DISABLED_OUT="$(BR_STUB_STATE="$BR_STATE" BR_STUB_LOG="$BR_LOG" \
  "$SCRIPT" --repo "$WORKTREE_REPO" --thresholds "$THRESHOLDS" --auto-bead --br-bin "$BR_STUB" --json)"
assert_eq "$(jq -r '.status' <<<"$DISABLED_OUT")" "skipped" "disabled opt-out skips probe"
assert_eq "$(jq -r 'has("metrics")' <<<"$DISABLED_OUT")" "false" "disabled opt-out emits no metrics"
assert_eq "$(wc -l < "$BR_LOG" | tr -d ' ')" "1" "disabled opt-out creates no bead"

assert_nonempty "$ASSERTIONS" "assertion counter"
printf 'PASS repo-hygiene-tick-smoke assertions=%s\n' "$ASSERTIONS"
