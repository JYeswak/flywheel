# flywheel-bv8zn Compliance Pack

## Scope
- Stage B mission-fidelity substrate ratification for flywheel.
- L70 no-punt canonical shard update with forbidden phrase catalog, false-premise debunks, three-predicate dispatch check, detector pointer, and flywheel-oq267 shard cross-link.
- Daily report integration for recent L70 punt phrase events.

## Acceptance Evidence
- AG1: L70 authored in canonical shard `.flywheel/rules/L024-L70-orch-no-punt-next-actionable-runs-same-tick-not-next-tick.md`; AGENTS mirrors verified by `agents-md-shard-extract.sh --dry-run --json` with `status=in_sync`.
- AG2: `.flywheel/doctrine/mission-fidelity-substrate.md` added.
- AG3: `.flywheel/scripts/punt-phrase-detector.py` added and wired into `.flywheel/scripts/daily-report.py`.
- AG4: Stage B handoff delivered to `alpsinsurance:1` and `vrtx:1`; `picoz` session was absent, and follow-up bead `flywheel-ae8aq` records the recovery path.
- AG5: L70 shard includes the `flywheel-oq267` shard extraction cross-link.

## Validation
- `python3 -m py_compile .flywheel/scripts/punt-phrase-detector.py .flywheel/scripts/daily-report.py`
- `bash -n tests/punt-phrase-detector.sh tests/daily-report.sh`
- `tests/punt-phrase-detector.sh`
- `.flywheel/scripts/punt-phrase-detector.py doctor --repo "$PWD" --json`
- `.flywheel/scripts/punt-phrase-detector.py scan --repo "$PWD" --json`
- `.flywheel/scripts/agents-md-shard-extract.sh --dry-run --json`
- `.flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-bv8zn-825b2d.md`
- Targeted daily-report fixture confirmed `l70_punt_phrase_events_24h: 2` in generated report.

## Known Deviations
- Full `tests/daily-report.sh` is not a clean pass in this local environment: it reports missing `~/Library/LaunchAgents/ai.zeststream.flywheel-daily-report.plist` and later hangs in an existing `flywheel-loop doctor` fixture path. The new punt-report assertion executed and passed before the hang.
- `picoz:1` handoff delivery could not execute because NTM reported `session "picoz" not found`; follow-up bead `flywheel-ae8aq` was created.

## Skill Routes
- canonical-cli-scoping: yes
- python-best-practices: yes
- readme-writing: n/a
- rust-best-practices: n/a
