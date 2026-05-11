# flywheel-2xdi.60 — probe-without-receiver: agentmail-fd-pressure-probe

Bead: flywheel-2xdi.60 (P3)
Parent: flywheel-2xdi (constant-gap-hunter, CLOSED)
Lane: audit / on-demand-classification
mutates_state: no (audit-only this tick; canonical fix is in a different repo)

## Bead claim vs reality

The bead flagged `.flywheel/scripts/agentmail-fd-pressure-probe.sh` as `probe-without-receiver` — "emits probe output but no tick/status/last_tick receiver reference was found".

Probed per the meta-rule from flywheel-2xdi.54 (probe before implementing):

**Parent bead context**: `flywheel-tvd9q` (P2, CLOSED 2026-05-10) — "agentmail-fd-pressure: daemon FD exhaustion under reservation traffic". Close note states verdict=`benign_no_action` across 5 baselines + 16-worker heavy stress. Daemon FD held at 14/4096 (0.34%) under all load shapes (kqueue+connection-pooled async server doesn't allocate per-request FDs). B2 ulimit bump UNNECESSARY.

**The probe IS intentionally on-demand diagnostic** — not a continuous-monitor surface:

1. Filed for flywheel-tvd9q as a decision tree (probe → verdict → action). The verdict (`benign_no_action`) settled the question.
2. Probe's `--doctor` mode emits `status:pass, verdict:doctor_pass` on invocation (live-probed 2026-05-11T08:35:03Z: fd_count=14, fd_pct=0.34).
3. The probe is kept as a diagnostic for future fd-pressure investigation, not as a continuous probe.
4. No launchd/cron scheduling exists — and none is needed given the verdict.

## Root cause classification

The gap is **classification-mismatch**, not actual missing-receiver:
- Probe shape: on-demand diagnostic (run when fd-pressure is suspected)
- gap-hunt-probe's heuristic: scans `*-probe.sh` files; expects them to appear in tick/status/last_tick receiver references
- Mismatch: the probe is classified by NAMING CONVENTION (`*-probe.sh`) as a continuous probe, but its INTENT is on-demand

## Canonical fix mechanism

`gap-hunt-probe.sh`'s `on_demand_script_allowlist()` (line ~823) reads from `~/.claude/skills/.flywheel/data/substrate-registry.json`. Adding an entry there with `kind` in `_ON_DEMAND_VALIDATOR_KINDS` (validator/scaffold-test/self-test/audit/scaffold) marks a script as intentionally on-demand and excludes it from `probe-without-receiver`.

The substrate-registry.json file lives in `.claude/skills/` repo, NOT in flywheel.git. Per `feedback_no_push_ntm_br` boundary discipline (memory rule), edits to `.claude/skills/*` are out-of-scope for flywheel-tick worker dispatches.

## Disposition: audit-only + file sister bead

Filing one sister bead for the canonical fix path. Not auto-fixing because the fix lives in a different repo.

| Sister bead | Action |
|---|---|
| `flywheel-2xdi.60.1` (filed below) | Add agentmail-fd-pressure-probe.sh to `~/.claude/skills/.flywheel/data/substrate-registry.json` with `kind=audit` (one-shot diagnostic class) — picks up next time someone touches the substrate-registry. |

This pattern (audit + sister-bead-for-canonical-fix-in-other-repo) is consistent with:
- `flywheel-2xdi.49` evidence: documented compat wrappers in SKILL.md → fixed via SKILL.md corpus extension
- `flywheel-2xdi.50` evidence: 3 substrate-doctor-*-test.sh files would benefit from registry allowlist (deferred)

## Acceptance gates

Auto-filed by gap-hunt-probe. Inferred AGs:

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Verify the probe's intent (continuous vs on-demand) | **DONE** | flywheel-tvd9q close note documents verdict=`benign_no_action`; probe kept as diagnostic. No launchd/cron schedule exists. Live `--doctor` invocation works (status:pass, verdict:doctor_pass). Probe is intentionally on-demand. |
| AG2 | Classify the gap correctly | **DONE** | classification-mismatch (probe is on-demand-class, gap-hunt expected continuous-receiver). NOT a real missing-receiver gap. |
| AG3 | Identify canonical fix mechanism | **DONE** | `on_demand_script_allowlist()` reads `~/.claude/skills/.flywheel/data/substrate-registry.json`. Adding entry with `kind=audit` marks the probe as intentionally on-demand and removes the flag. |
| AG4 | File sister bead for canonical fix (different repo, content-judgment required) | **DONE** | flywheel-2xdi.60.1 filed for the substrate-registry allowlist addition. |
| AG5 | Document re-trigger criteria | **DONE** | Sister bead acts when someone touches .claude/skills/.flywheel/data/substrate-registry.json. No flywheel-repo edits needed this tick. |

## Out of scope

- Edits to `.claude/skills/` repo (per `feedback_no_push_ntm_br` boundary)
- Adding the probe to flywheel-loop's doctor invariant set (overcorrection — probe is intentionally on-demand, not continuous)
- Extending gap-hunt-probe's class-detection heuristic to recognize doctor-mode probes as their own receiver (broad scope; would benefit from a class-level "is the probe self-reporting via --doctor" check, but that's a class-fix bead, not this instance)

## L52 bead receipt

- `beads_filed`: `flywheel-2xdi.60.1` (substrate-registry allowlist entry; P4 deferred to .claude/skills/ edit window)
- `beads_updated`: none
- `no_bead_reason`: not n/a — sister bead filed for the canonical fix that lives in a different repo.

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/audit/flywheel-2xdi.60/evidence.md` | NEW |
| `.beads/issues.jsonl` (via `br create`) | +1 sister bead |

No production scripts touched. No probe edits. No substrate changes.

## Four-Lens Self-Grade

- **brand** (10): respected `feedback_no_push_ntm_br` boundary (no edits to .claude/skills/). Applied META-RULE from 2xdi.54 (probe before implementing) recursively. Sister-bead pattern consistent with prior on-demand-class deferrals.
- **sniff** (10): live `--doctor` probe captured (fd_count=14, status:pass). tvd9q verdict cited verbatim (benign_no_action). No-launchd-scheduling verified empirically.
- **jeff** (10): didn't auto-fix; didn't extend gap-hunt-probe corpus a 6th time today; filed the canonical fix as a sister bead so it lands when a .claude/skills/ worker is active.
- **public** (10): Three Judges check —
  - Skeptical operator: tvd9q verdict + live --doctor probe both prove the probe is settled diagnostic.
  - Maintainer: sister bead provides clear canonical-fix path (one substrate-registry.json edit).
  - Future worker: when .claude/skills/ session is active, the sister bead picks up; the audit pack captures the rationale for future re-evaluation.

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

- AG1-AG5: all DONE. ✓
- Empirical verification (live `--doctor` probe). ✓
- Classification correct (on-demand diagnostic, not continuous-monitor). ✓
- Sister bead filed for the canonical fix path (one-line substrate-registry edit). ✓
- Boundary discipline respected (no .claude/skills/ writes). ✓

## L112 probe

Command: `.flywheel/scripts/agentmail-fd-pressure-probe.sh --doctor --json 2>&1 | jq -r '.status'`
Expected: `literal:pass`
Timeout: 30 seconds
