# flywheel-cz38q live coverage check

## Bead premise (auto-doctor claim)
Trauma class 'agent-mail-token-transcript-exposure' hit 3 times in last 7d with no INCIDENTS coverage.

## Canonical INCIDENTS.md state
  Section heading at line 5519:
5519:## agent-mail-token-transcript-exposure

  Total mentions:
3

## Promote script default scan paths (post flywheel-qnkj2 fix)
  Line 38-43 of doctrine-ladder-promote.sh:
default_incident_paths() {
  printf '%s\n' "$HOME/.claude/skills/.flywheel/INCIDENTS.md"
  printf '%s\n' "$HOME"/.claude/skills/*/references/INCIDENTS.md
  printf '%s\n' "$REPO/INCIDENTS.md"
  printf '%s\n' "$REPO/AGENTS.md"
}

## Live class_in_incidents() result
  FOUND in: /Users/josh/Developer/flywheel/INCIDENTS.md (rc=0)

## Conclusion
Bead premise is STALE — class IS canonically covered AND default scan finds it.
No propagation needed. The bead was likely filed by a previous tick before
flywheel-qnkj2's fix landed (which added $REPO/INCIDENTS.md to default_incident_paths).
