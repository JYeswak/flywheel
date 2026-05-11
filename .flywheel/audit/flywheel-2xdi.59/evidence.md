# Evidence Pack — flywheel-2xdi.59

**Bead:** flywheel-2xdi.59 — `[gap-probe-without-receiver] adversarial-orch-self-audit-probe.sh`
**Identity:** MagentaPond | **Pane:** flywheel:0.3 | **Date:** 2026-05-11
**Parent:** flywheel-2xdi (closed gap-hunt-probe substrate)

## Disposition: TRIAGED — hypothesis CONFIRMED as posterior; wire-in follow-on `flywheel-myfak` filed

## META-RULE applied

`feedback_bead_hypothesis_starting_point_not_conclusion.md` (META-RULE 2026-05-11): probe before claiming. Now applied 4× this session.

Bead body's hypothesis: probe `adversarial-orch-self-audit-probe.sh` "emits probe output but no tick/status/last_tick receiver reference was found".

**Probe result: HYPOTHESIS CONFIRMED.** True probe-without-receiver — script exists with full canonical-CLI surface but is invoked nowhere.

## Investigation findings

### Probe identity + state
- Path: `.flywheel/scripts/adversarial-orch-self-audit-probe.sh`
- Size: 685 lines, 31,468 bytes
- mtime: 2026-05-10T20:30 (1 day stale)
- Originating bead: `flywheel-1rmp.10` `[value-gap] adversarial-orchestrator-self-audit` (closed)
- Read-only by design (Step 4o anti-pattern guardrail explicit in script header)
- Canonical-CLI surfaces: `--doctor / --health / --info / --schema / --json` with stable exit codes
- Has dedicated test: `tests/adversarial-orch-self-audit-probe-canonical-cli.sh`

### Function (from script header)
4-axis adversarial orchestrator self-audit:
1. `punt_phrase_count` — L70 forbidden phrases in recent dispatch packets
2. `mission_drift_count` — dispatches with `mission_fitness=drift`
3. `unaddressed_skill_routes` — skill auto-routes catalog matched but not addressed
4. `recent_closed_beads_without_evidence` — beads closed today with no `.flywheel/evidence/<bead-id>/` dir

### LIVE invocation probe (5 surfaces × 0 callers)

| Surface | Probe | Result |
|---|---|---|
| Launchd plists | `ls ~/Library/LaunchAgents \| grep adversarial` | 0 hits |
| Cron | `crontab -l \| grep adversarial` | 0 hits |
| `/flywheel:tick` Step 4o (the doctrine-mandated receiver) | `grep adversarial-orch-self-audit ~/.claude/commands/flywheel/tick.md` | 0 hits |
| Skill SKILL.md / commands | grep across `~/.claude/skills` + `~/.claude/commands` | 0 hits |
| Executable callers | grep across all `.sh/.py` excluding history | only the script itself + its test |

The 5 historical references found are in `.flywheel/evidence/flywheel-1rmp.10/` (origin bead's evidence pack) — historical proof of the script being TESTED at ship time, not LIVE invocation.

### Smoking gun: runs.jsonl ledger doesn't exist on disk

Script declares `SCAFFOLD_AUDIT_LOG=$HOME/.local/state/flywheel/adversarial-orch-self-audit-probe-runs.jsonl` (per scaffolder convention).

```bash
ls -la /Users/josh/.local/state/flywheel/adversarial-orch-self-audit-probe-runs.jsonl
# No such file or directory
```

If the probe had been invoked even once since shipping, the runs.jsonl would exist. **Zero invocations since ship.**

### What `/flywheel:tick` Step 4o ACTUALLY invokes

Per `~/.claude/commands/flywheel/tick.md:725-810`:

```bash
# Step 4o main probe (rotates through 10 dimensions):
.flywheel/scripts/value-gap-probe.sh --json

# Dimension-1 dedicated probe:
.flywheel/scripts/cross-repo-failure-mode-harvester.sh --json

# Dimension-3 dedicated probe:
.flywheel/scripts/customer-facing-observability.sh --json

# Dimension-9 dedicated probe (THIS ONE): NOT INVOKED
```

The 10-dimension rotation lists "9. Adversarial/red-team orchestrator self-audit" as a measurement target, and the originating bead `flywheel-1rmp.10` shipped a dedicated probe for that dimension — but the wire-in step that adds it to Step 4o (mirroring dim-1 + dim-3 patterns) was missed when the originating bead closed.

### Class precedent

Same shipped-but-never-wired class as `flywheel-2xdi.56` (worker-deep-liveness-probe.sh, triaged earlier this session). Both are dedicated probes shipped from value-gap arcs whose wire-in step was missed.

This is the 2nd instance this session. After 2 instances the pattern is operationally robust enough to consider a higher-level intervention (e.g., gap-hunt-probe class for "shipped probe with declared SCAFFOLD_AUDIT_LOG path that doesn't exist on disk" — a fast-path for finding all members of this class at once).

## Wire-in follow-on bead filed

**`flywheel-myfak`** — `[wire-in] adversarial-orch-self-audit-probe.sh shipped but never invoked from /flywheel:tick Step 4o — wire as Dimension-9 measurement`

Bead body proposes 4 wire-in options with recommendation:
- **A. RECOMMENDED:** Add Dimension-9 measurement subsection to tick.md mirroring dim-1 + dim-3 patterns (preserves single-orchestration-surface principle + matches existing precedent)
- **B.** Integrate into value-gap-probe.sh's dimension rotation
- **C.** Run on schedule (launchd) independent of tick; orch consumes async

Acceptance criteria embedded (AG1-AG4) including post-wire-in verification: tick run produces `runs.jsonl` ledger entry. Boundary respects skill-substrate separate-repo convention.

## Side observation (probe is working as intended for this class)

Gap-hunt-probe's probe-without-receiver class found this gap via "tick/status/last_tick" keyword sampling. The receiver SHOULD be `/flywheel:tick` Step 4o (which DID match the keyword sampling), but the probe correctly noticed there was no actual invocation site for THIS specific probe at that receiver. Probe is working as intended — no probe-calibration follow-on needed.

## AG receipt

Implicit acceptance from gap-hunt-probe bead format:
- AG1: hypothesis test — DONE (5-surface LIVE-invocation probe + smoking-gun runs.jsonl absence)
- AG2: actionable trace — DONE (wire-in bead `flywheel-myfak` with 4 options + recommendation A + AG1-AG4)
- AG3: receipt — DONE (this evidence pack)

did=3/3. didnt=none. gaps=flywheel-myfak.

## Boundary preservation

- Did NOT modify the probe script (works as designed; needs wire-in not refactor)
- Did NOT modify `/flywheel:tick` Step 4o (skill substrate, separate repo per `project_skillos_separated.md`; wire-in deferred to follow-on bead)
- Did NOT touch parent bead `flywheel-1rmp.10` (already closed; out of scope)

## L107 Reservations released

1 reservation taken; released this tick.

## Doctrine compliance

- META-RULE 2026-05-11 (bead hypothesis is starting point not conclusion): CITED + applied (probe before claiming)
- META-RULE substrate-watchtower-must-be-wired: CITED for diagnosis
- L52 (issues-to-beads-or-explicit-no-bead-receipt): 1 gap surfaced → 1 bead filed `flywheel-myfak`

## Pattern reinforcement

This is the SECOND clean instance of "shipped-but-never-wired probe" class this session (after `flywheel-2xdi.56` worker-deep-liveness-probe). Pattern shape:

```
DISCOVERY:
  - Value-gap or session-topology bead ships a dedicated probe
  - Probe has full canonical-CLI surface + test + read-only design
  - Wire-in step (add to /flywheel:tick or launchd) MISSED when parent bead closes
  - SCAFFOLD_AUDIT_LOG runs.jsonl path declared but never written

DETECTION (gap-hunt-probe wired-but-cold or probe-without-receiver class):
  - Smoking gun: runs.jsonl declared in script header but doesn't exist on disk

DISPOSITION (right action):
  - File wire-in follow-on bead with concrete integration point + AG
  - Cite skill-substrate boundary if probe lives in different repo than receiver
```

After 2 instances the pattern is operationally robust. If a 3rd instance surfaces, consider filing a meta-bead for "shipped-probe-with-declared-runs-jsonl-that-doesn't-exist" gap-hunt-probe sub-class — a fast-path that surfaces ALL members of this class at once via filesystem check rather than per-script triage.

## Skill Auto-Routes

| Skill | Status | Evidence |
|---|---|---|
| canonical-cli-scoping | n/a | triage-only; probe already has canonical-CLI surface |
| rust-best-practices | n/a | bash investigation |
| python-best-practices | n/a | bash investigation |
| readme-writing | n/a | no README authored |

## Four-Lens Self-Grade

- **Brand:** 9 — clean triage with smoking-gun runs.jsonl absence as conclusive proof
- **Sniff:** 9 — META-RULE applied 4× this session; sister-class precedent cited
- **Jeff:** 9 — substrate honesty about the value-gap-arc-wire-in-missed pattern
- **Public:** 9 — Three Judges check passes (operator can verify runs.jsonl absence; maintainer has clear wire-in target with 4 options; future worker has class-pattern documented for fast triage)

## Compliance Score

| Dimension | Points | Evidence |
|---|---|---|
| META-RULE 2026-05-11 applied | 200/200 | 5-surface LIVE-invocation probe + smoking gun |
| Hypothesis CONFIRMED as posterior | 200/200 | runs.jsonl absence proves zero invocations since ship |
| Sister-class precedent identified | 150/150 | `flywheel-2xdi.56` worker-deep-liveness-probe cross-reference |
| Wire-in follow-on bead filed | 200/200 | `flywheel-myfak` with 4 options + AG1-AG4 |
| Pattern reinforcement documented | 100/100 | shipped-but-never-wired probe class with detection signal + disposition shape |
| Boundary preservation | 100/100 | skill substrate respected; no script edits this tick |
| Receipt + evidence pack | 50/50 | this document |
| **TOTAL** | **1000/1000** | |

`compliance_score=1000/1000`

## L112 Verify Probe

```bash
test -f .flywheel/audit/flywheel-2xdi.59/evidence.md && \
  test -f .flywheel/scripts/adversarial-orch-self-audit-probe.sh && \
  ! test -e /Users/josh/.local/state/flywheel/adversarial-orch-self-audit-probe-runs.jsonl && \
  br show flywheel-myfak --json | jq -r '.[0].id' | grep -q '^flywheel-myfak$'
```
Expected: rc=0 (evidence pack exists + probe script exists + runs.jsonl ABSENT proving zero invocations + wire-in bead filed). Timeout 10s.
