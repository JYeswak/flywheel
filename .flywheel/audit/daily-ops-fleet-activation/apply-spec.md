# Daily-ops fleet activation apply spec

Joshua signoff 2026-05-10: "do we have daily ops reports coming from all repos —
logs of how & what they are doing and ensure they are working on task in a
flywheel worthy manner?" Two-bead chain: A activates infrastructure, B adds
quality grading on top.

## Bead A: fleet-wide daily-report activation

### AG1: enabled-repos enumeration

- Source: `.flywheel/scripts/daily-report-enabled-repos.sh` already iterates
  `~/Developer/<repo>` looking for `.flywheel/` subdirs (flywheel-installed marker)
- Verify: dry-run produces a list of all flywheel-installed repos under `~/Developer`
- Expected coverage: flywheel, alpsinsurance, mobile-eats, vrtx, skillos,
  zesttube, zeststream-infra, picoz/polymarket-pico-z if installed
- If any repo missing a `.flywheel/` install, surface in evidence (don't
  auto-install, just list)

### AG2: launchd plist for daily run

- File: `.flywheel/launchd/ai.zeststream.flywheel-fleet-daily-report.plist`
- Schedule: daily at 08:00 local (StartCalendarInterval Hour=8 Minute=0)
- Program: `/Users/josh/Developer/flywheel/.flywheel/scripts/daily-report-enabled-repos.sh`
- Arguments: `--notify` (or `--no-notify` if Joshua hasn't decided notification path)
- KeepAlive false; runs once per day
- StandardOutPath/ErrorPath under `~/.local/state/flywheel/`
- Register via `flywheel-watchers register --label ai.zeststream.flywheel-fleet-daily-report --owner flywheel-1`

### AG3: bootstrap launchctl

- `cp <repo>/.flywheel/launchd/ai.zeststream.flywheel-fleet-daily-report.plist ~/Library/LaunchAgents/`
- `launchctl bootstrap gui/$(id -u) <plist>`
- Verify load: `launchctl print gui/$(id -u)/ai.zeststream.flywheel-fleet-daily-report` shows valid registration

### AG4: smoke run

- Run the script once manually to produce TODAY's report set
- Verify each enabled repo produces `<repo>/.flywheel/reports/daily-2026-05-10.md`
- Aggregate any errors per-repo (e.g., ntm summary fails) into evidence

### AG5: report

- Receipt at `.flywheel/audit/daily-ops-fleet-activation/evidence.md`
- List of repos that produced reports (with line counts as a sanity proxy)
- List of repos that failed (with error class)
- Plist path + bootstrap status

## Bead B: quality grading layer (chains on A)

### AG-B1: extend daily-report.py with quality dimensions

- New section in per-repo report markdown:
  - **Compliance distribution**: from dispatch-log.jsonl callbacks closed today,
    avg/median/p25/p75 of compliance_score
  - **Four-lens distribution**: per-axis (brand, sniff, jeff, public) avg + count<8
  - **Mission fitness**: count of `infrastructure | adjacent | drift` from callbacks
  - **BLOCKED/ESCALATE rate**: ratio vs total closes
  - **Identity attribution**: per-worker close count + avg compliance (CloudyMill 12, MagentaPond 18, etc.)

### AG-B2: fleet-wide aggregator

- New script: `.flywheel/scripts/fleet-daily-rollup.py`
- Reads each `<repo>/.flywheel/reports/daily-<date>.md` produced by Bead A
- Aggregates into `~/.local/state/flywheel/fleet-daily-<date>.md`
- Surfaces RED FLAGS:
  - Any repo with median compliance <850 today
  - Any worker with consistent <800 closes (window: 7d)
  - Any repo with BLOCKED/ESCALATE rate >20%
  - Mission fitness drift count >5
- TOP-LINE summary at the top: "Fleet shipped X closes at Y avg compliance,
  Z red flags, W blockers cleared"

### AG-B3: aggregator launchd

- Run aggregator at 08:30 local (after the per-repo reports complete at 08:00)
- Plist: `.flywheel/launchd/ai.zeststream.flywheel-fleet-daily-rollup.plist`

### AG-B4: smoke + receipt

- Manual run to produce today's first rollup
- Receipt at `.flywheel/audit/daily-ops-fleet-quality/evidence.md`

## Boundary

- Bead A has zero new code — just wires existing daily-report.sh into launchd.
  Smoke is "did each repo produce a report at expected path?"
- Bead B is the substantive change — extending the renderer + adding rollup.
  Don't start B until A's smoke confirms data is being collected.
- Notification: don't yet auto-post the rollup to any inbox/agentmail; human
  Joshua reads the markdown directly first 1-2 days, then we pick a delivery channel.

## Replaces / chains

- Bead A is independent (infrastructure-only)
- Bead B `dep-add` on Bead A

## Canonical structure (post-hoc backfill, flywheel-at83y)

This apply-spec was authored before the F7 canonical structure rule (filesystem-as-rag doctrine).
The body above contains the substantive content; the H2 stubs below satisfy the mechanical lint without rewriting the prose.

## Goal

See body above (typically the opening paragraph or first H1 section).

## Acceptance gate

See body above (typically near the end, named Acceptance or per-AG numbered).
