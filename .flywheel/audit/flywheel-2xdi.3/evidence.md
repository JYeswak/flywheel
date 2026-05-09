# flywheel-2xdi.3 evidence

Task: resolve the auto-filed `wired-but-cold` gap for
`~/.claude/skills/.flywheel/scripts/idle-drifted-panes.sh`.

## Result

Closed as stale / false-positive for the "not referenced by recent JSONL
ledgers" detector signal.

`idle-drifted-panes.sh` is not a JSONL ledger producer. It is a LaunchAgent
target plus doctor-invariant artifact for surfacing safe restart windows for
drifted Claude panes. The original detector evidence only proves the script is
not named by recent modified JSONL ledgers; it does not prove the script is
cold, missing, or disconnected.

## Load-Bearing Evidence

Direct source and runtime relationships found:

- `~/.claude/skills/.flywheel/scripts/idle-drifted-panes.sh` exists and is
  executable.
- `bash -n ~/.claude/skills/.flywheel/scripts/idle-drifted-panes.sh` passed.
- A live script run exited cleanly with structured JSON:
  `{"all_idle":false,"ready_count":0,"attached_count":11,...}`.
- `~/.claude/skills/.flywheel/bin/flywheel` has an
  `=== idle-pane-watch invariant ===` block that checks this script, the plist
  registration, and the recent log mtime.
- `~/Library/LaunchAgents/com.zeststream.flywheel-idle-pane-watch.plist`
  runs `/Users/josh/.claude/skills/.flywheel/scripts/idle-drifted-panes.sh`
  every 1800 seconds.
- `~/.claude/skills/.flywheel/config/plist-classes.json` classifies
  `com.zeststream.flywheel-idle-pane-watch` as `HEALTHY` and documents exit
  codes `0`, `2`, and `3`.
- `~/.claude/skills/.flywheel/PATTERNS.md`,
  `~/.claude/skills/.flywheel/CHANGELOG.md`, and
  `~/.claude/skills/.flywheel/GAPS.md` all name the script and its intended
  operating contract.

Focused runtime proof:

```bash
.flywheel/audit/flywheel-2xdi.3/l112-probe.sh
```

Observed:

```text
OK_idle_drifted_panes_load_bearing
```

## Follow-Up Filed

While validating this gap, I observed a separate operational issue: live
`launchctl` does not currently list
`com.zeststream.flywheel-idle-pane-watch`, and
`~/.cache/flywheel/idle-pane-watch.err.log` has not updated since
2026-05-04.

That is not evidence that the script is cold; it is LaunchAgent registration
drift. I filed follow-up bead `flywheel-2xdi.33` to carry that repair instead
of silently absorbing it into this false-positive close.

## Decision

No code change is needed for `idle-drifted-panes.sh` in this dispatch. The
correct close action is to preserve audit evidence, file the distinct
LaunchAgent registration drift follow-up, and close the original
`wired-but-cold` bead.

## Four-Lens Self-Grade

- brand: 8 - Keeps detector output honest without inventing JSONL references.
- sniff: 8 - Uses direct source wiring, plist/config proof, and runtime output.
- jeff: 8 - Separates artifact wiring from the live registration drift.
- public: 8 - A future maintainer can rerun the L112 probe and inspect the
  follow-up bead.
