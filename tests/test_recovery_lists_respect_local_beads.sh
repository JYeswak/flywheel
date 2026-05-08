#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
NTM_REPO="${NTM_REPO:-/Users/josh/Developer/ntm}"
TMPDIR="$(mktemp -d -t recovery-lists.XXXXXX)"
PARENT="$TMPDIR/parent"
CHILD="$PARENT/child"
TEST_FILE="$NTM_REPO/internal/cli/recovery_local_beads_flywheel_test.go"

cleanup() {
  rm -f "$TEST_FILE"
}
trap cleanup EXIT

mkdir -p "$CHILD"

(
  cd "$PARENT"
  br init --prefix tvy --json >/dev/null
  br create "synthetic parent in progress" \
    --type task \
    --priority 1 \
    --status in_progress \
    --assignee recovery-test \
    --json >/dev/null
)

cat >"$TEST_FILE" <<GO
package cli

import "testing"

func TestFlywheelRecoveryListsRespectLocalBeads(t *testing.T) {
	parent := "$PARENT"
	child := "$CHILD"

	childInProgress, childCompleted, childBlocked, err := loadRecoveryBeads(child)
	if err != nil {
		t.Fatalf("child loadRecoveryBeads returned error: %v", err)
	}
	if len(childInProgress) != 0 || len(childCompleted) != 0 || len(childBlocked) != 0 {
		t.Fatalf("child without local .beads surfaced parent rows: in_progress=%d completed=%d blocked=%d",
			len(childInProgress), len(childCompleted), len(childBlocked))
	}

	parentInProgress, _, _, err := loadRecoveryBeads(parent)
	if err != nil {
		t.Fatalf("parent loadRecoveryBeads returned error: %v", err)
	}
	if len(parentInProgress) == 0 {
		t.Fatalf("parent with local .beads returned no in-progress rows")
	}
	if parentInProgress[0].Title != "synthetic parent in progress" {
		t.Fatalf("parent in-progress title = %q, want synthetic parent in progress", parentInProgress[0].Title)
	}
}
GO

(
  cd "$NTM_REPO"
  go test ./internal/cli -run TestFlywheelRecoveryListsRespectLocalBeads -count=1
)

printf 'PASS recovery_lists_respect_local_beads\n'
