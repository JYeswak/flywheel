# skillos-oar1m diagnosis — canonical-cli-checker recurses into / when flywheel-loop doctor called without --repo from cwd=/

**From:** skillos:1
**To:** flywheel
**Real-word prefix:** DIAGNOSIS
**Mission anchor (sender):** `unknown`
**Companion plan:** none
**Posture:** ASK
**Block:** none
**Schema version:** `skillos.oar1m_diagnosis_handoff.v1`

## Summary

SkillOS pane 3 produced a diagnosis-only finding for `skillos-oar1m` at 2026-05-19T22:49Z. Please ratify the diagnosis and file Flywheel-side beads for the five fixes below.

## Full diagnosis from latest `br show skillos-oar1m` comment

Diagnosis 2026-05-19T22:49Z (diagnosis-only; no fix shipped):

Observed live process state:
- PIDs 1737/2254/4546 are not kernel zombies: ps reports STAT=S, not Z/<defunct>. They are long-lived sleeping bash processes in process group 946.
- Parent chain is 946 -> 1731 -> 1737 -> 2254 -> 4546 -> 4547 -> 4551/4552. The root is /Users/josh/Developer/flywheel/.flywheel/scripts/w10-mission-lock-cadence-tick.sh tick.
- Leaf command is bash ~/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh //bin/wait4path, with children `//bin/wait4path --help` and `grep -E -- --dry-run` running since Mon May 18 11:36. `sample 4551` shows wait4path blocked in kevent.

Codepath:
1. w10-mission-lock-cadence-tick.sh computes age_hours with: `age_hours="$($DOCTOR doctor 2>/dev/null | grep -oE "age_hours=[0-9.]+" | head -1 | sed "s/age_hours=//" || echo 0)"`.
2. Because no `--repo "$REPO_ROOT"` is passed and the stuck process cwd is `/`, flywheel-loop doctor treats REPO_ABS as `/`.
3. portable_doctor calls `repo_local_cli_floor_json`; that sets `bin_dir="$REPO_ABS/bin"`, so in this case `//bin`.
4. repo_local_cli_floor_json loops every executable in `//bin` and runs `bash "$checker" "$cli" 2>&1` with no timeout.
5. check-cli-scoping.sh then runs probes like `$CLI --help | grep ...` with no timeout. For `//bin/wait4path`, `--help` does not return and the whole pipeline/process tree remains alive.

Hypothesis result:
- `flywheel outcome --manual` is not implicated by this evidence.
- The concrete hang source is unbounded canonical-cli checker execution over system `/bin` caused by `flywheel-loop doctor` being invoked without an explicit repo from a cwd of `/`.

Proposed fix (not shipped today):
1. In w10-mission-lock-cadence-tick.sh, call `"$DOCTOR" doctor --repo "$REPO_ROOT"` (preferably `--json`) and parse the mission_lock_age field from JSON rather than grepping human output.
2. In repo_local_cli_floor_json, add a guard refusing to scan when `REPO_ABS` is `/`, empty, or not a git worktree owned by the target repo. It should return a warn/fail envelope instead of scanning host `/bin`.
3. Wrap each checker invocation with timeout, e.g. `${FLYWHEEL_REPO_LOCAL_CLI_CHECK_TIMEOUT_SECONDS:-5}` via `timeout`/`gtimeout`, and classify rc=124 as `canonical_cli_checker_timeout`.
4. Defense in depth: check-cli-scoping.sh should wrap every probed CLI command (`--help`, subcommand `--help`, `--info`, examples) in a per-probe timeout so one bad CLI cannot wedge the checker.
5. Optional cleanup primitive can list long-lived `flywheel-loop doctor` descendants and only terminate with explicit --apply, but it should match sleeping stale process trees, not only PPID=1 zombies.

No process was killed and `flywheel outcome --manual` was not run.

## Requested Flywheel actions

Please file beads and ratify or correct this diagnosis for these five Flywheel-owned fixes:

1. `w10-mission-lock-cadence-tick.sh`: pass `--repo "$REPO_ROOT"`, prefer `--json`, and parse mission-lock age from JSON instead of grepping human output.
2. `repo_local_cli_floor_json`: refuse `/`, empty repo roots, and non-target git worktrees before scanning `bin`; emit a structured warn/fail envelope.
3. Checker invocation timeout: wrap each canonical-cli checker call with a bounded timeout and classify timeout as `canonical_cli_checker_timeout`.
4. `check-cli-scoping.sh`: add per-probe timeout around every probed CLI command (`--help`, subcommand help, `--info`, examples).
5. Cleanup primitive: add an explicit-apply tool for stale sleeping `flywheel-loop doctor` descendant trees; match the sleeping stale tree class, not only PPID=1 zombies.

## SkillOS disposition

- Diagnosis only; no Flywheel files were modified from SkillOS.
- No process was killed.
- `flywheel outcome --manual` was not run.
- This handoff was rendered with `.flywheel/scripts/cross-orch-handoff-send.sh` to dogfood the cross-orch handoff primitive.
