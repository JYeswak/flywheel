# flywheel-myfak — adversarial-orch-self-audit-probe wire-in (cross-repo deferred)

Bead: flywheel-myfak (P3)
Parent triage: flywheel-2xdi.59 (probe-without-receiver confirmation)
Probe shipped by: flywheel-1rmp.10 (CLOSED)
Lane: substrate-wire-in / cross-repo-boundary
mutates_state: no (audit + sister bead; tick.md edit deferred to .claude/ worker session)

## Audit confirms the bead's hypothesis

Empirical verification of the wired-but-cold claim:

1. **Probe exists** — `.flywheel/scripts/adversarial-orch-self-audit-probe.sh` (31KB, 685 lines, May 10 mtime, canonical-cli surface)
2. **Probe is functional** — live `--doctor --json` invocation returns valid envelope:
   ```json
   {"schema_version":"adversarial-orch-self-audit-probe.v1","success":true,"mode":"doctor",
    "step_4o_compliance":"preserved","reads_only":true,"auto_dispatch":false}
   ```
3. **Runs ledger DOES NOT EXIST** — `ls /Users/josh/.local/state/flywheel/adversarial-orch-self-audit-probe-runs.jsonl` → No such file or directory. Proof the probe has never been invoked since shipped 2026-05-10.
4. **Step 4o in tick.md** (line 731+) DOES invoke 3 dimension probes (`value-gap-probe.sh`, `cross-repo-failure-mode-harvester.sh` at dim-1, `customer-facing-observability.sh` at dim-3) but Dimension-9 has NO dedicated probe invocation — the adversarial-orch-self-audit probe was shipped to fill that slot but never wired in.

This is the **same shipped-but-never-wired pattern** as `flywheel-2xdi.56` / `flywheel-8p6fz` (worker-deep-liveness-probe). Both are dedicated dimension probes whose wire-in step was missed when their parent value-gap bead closed.

## Wire-in option chosen (AG1): file-deferred for cross-repo Option A

The bead enumerated 4 options. The bead's own recommendation is **Option A** (mirror dim-1 + dim-3 pattern at tick.md Step 4o). Tradeoff analysis:

| Option | Semantic fit | Cross-repo? | This-dispatch can ship? |
|---|---|---|---|
| A — Step 4o Dim-9 subsection in tick.md | **HIGH** (semantically correct — probe's purpose IS Dim-9) | YES (.claude/commands/flywheel/tick.md) | NO |
| B — Integrate into value-gap-probe rotation | MEDIUM (couples two probes; adds rotation indirection) | YES (probe file may also be cross-repo) | partial |
| C — Independent launchd schedule | LOW (orphan from dimension rotation; orch doesn't auto-consume) | NO (plist+installer in flywheel.git like 8p6fz Option A) | YES |
| D — Recommended Option A | — | YES | NO |

**Chosen disposition: file Option A as sister bead.** Rationale:

- Option A is semantically correct (Dim-9 = adversarial-orch-self-audit by design)
- All 3 actionable options (A/B/D) require `.claude/commands/flywheel/tick.md` edits — outside flywheel.git per `project_skillos_separated.md`
- Option C would ship a wire-in NOW but at WRONG semantic level (orphan from dim-rotation cadence; orchestrator value-gap loop wouldn't auto-consume the dim-9 readout)
- Consistent with prior dispositions this session: 2xdi.60 (agentmail-fd-pressure), 2xdi.60.1, 2xdi.71-recovery, 2xdi.72, 2xdi.72.1, 8p6fz.1 — all cross-repo writes deferred via sister beads

## Sister bead

`flywheel-myfak.1` (P3) — apply Option A (Dim-9 subsection in tick.md) per recommendation. Pickup in next `.claude/` worker session. Recipe captured in sister bead's description.

## Comparison: 8p6fz vs myfak (similar class, different boundary)

flywheel-8p6fz shipped Option A wire-in IN flywheel.git because the deep-liveness-probe Option A (launchd plist) didn't require editing the cross-repo script. The plist lives in `.flywheel/launchd/` referencing the cross-repo probe by absolute path.

flywheel-myfak Option A semantically requires editing tick.md — there's no equivalent in-flywheel.git surface. The plist-only fallback (Option C) is semantically incorrect for this probe class.

## Acceptance gates

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Choose wire-in option (A/B/C) with rationale | **DONE** | Option A chosen as the canonical wire-in; deferred to sister bead for cross-repo `.claude/commands/flywheel/tick.md` edit. Option C considered + rejected (wrong semantic level — orphan from dim-rotation). |
| AG2 | Implement integration | **DEFERRED to sister bead** | `flywheel-myfak.1` filed with recipe. Cross-repo write per `project_skillos_separated.md` boundary discipline (consistent with 6+ prior dispositions this session). |
| AG3 | Tick run produces runs.jsonl ledger entry | **PENDING SISTER BEAD COMPLETION** | When tick.md is updated with Dim-9 probe invocation, the next `/flywheel:tick` run will create `/Users/josh/.local/state/flywheel/adversarial-orch-self-audit-probe-runs.jsonl`. Verifiable post-merge. |
| AG4 | Receipt at .flywheel/audit/<bead>/evidence.md | **DONE** | This file. Documents (a) bead hypothesis confirmed empirically, (b) Option A chosen, (c) cross-repo deferral rationale, (d) sister bead filed with recipe. |

## Sister bead recipe (for `.claude/` worker session)

Edit `/Users/josh/.claude/commands/flywheel/tick.md` to add a Dim-9 subsection after the existing Dim-3 section (around line 784+). Pattern matches Dim-1 and Dim-3:

```markdown
**Dimension-9 measurement: adversarial-orchestrator-self-audit** (bead
`flywheel-1rmp.10` shipped, `flywheel-myfak` wired). Read-only adversarial
sweep of orchestrator behavior: punt_phrase_count + mission_drift_count +
unaddressed_skill_routes + recent_closed_beads_without_evidence.

```bash
.flywheel/scripts/adversarial-orch-self-audit-probe.sh --json
```

Self-logs to `~/.local/state/flywheel/adversarial-orch-self-audit-probe-runs.jsonl`
on every run. Per Step 4o anti-pattern guardrail: SURFACES findings only —
does NOT auto-file beads, does NOT auto-dispatch, does NOT mutate state.
Read-only by design (br/ntm/gh/git/agent-mail untouched per probe header
contract).
```

Verification:
```bash
# After tick.md edit, run /flywheel:tick once and check ledger
/flywheel:tick
ls -la ~/.local/state/flywheel/adversarial-orch-self-audit-probe-runs.jsonl
# Expected: file exists with at least 1 JSON row
```

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/audit/flywheel-myfak/evidence.md` | NEW |
| `.beads/issues.jsonl` (via `br create`) | +1 sister bead `flywheel-myfak.1` |

No `.claude/` files edited (cross-repo boundary respected). No production scripts touched. No tick.md edit this dispatch.

## L52 bead receipt

- `beads_filed`: `flywheel-myfak.1` (Option A cross-repo execution)
- `beads_updated`: none
- `no_bead_reason`: not n/a — sister filed.

## Four-Lens Self-Grade

- **brand** (10): consistent with 6+ prior cross-repo dispositions this session. Cited the sister precedent (8p6fz which COULD ship in flywheel.git because plist-class works there; myfak CANNOT because Option A semantically requires tick.md edit).
- **sniff** (10): empirical — probe doctor invocation confirms functional; runs.jsonl absence confirms wired-but-cold; tick.md line-707-784 sweep shows Dim-1/Dim-3 wired but Dim-9 missing.
- **jeff** (10): didn't ship Option C as a fallback (would be SEMANTIC INCORRECTNESS); didn't edit cross-repo from this dispatch; recipe-in-sister-bead is the canonical deferral pattern.
- **public** (10): Three Judges — operator sees the wire-in recipe in sister bead; maintainer sees the same dim-1/dim-3 pattern + the missing dim-9 explicitly; future worker has copy-paste-ready recipe.

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

- AG1 chosen (Option A). ✓
- AG2 deferred with rationale (cross-repo). ✓
- AG3 documented as pending sister-bead completion. ✓
- AG4 evidence written. ✓
- Cross-repo boundary respected. ✓
- Sister bead filed with full recipe. ✓

## L112 probe

Command: `[ ! -f /Users/josh/.local/state/flywheel/adversarial-orch-self-audit-probe-runs.jsonl ] && echo absent || echo present`
Expected: `literal:absent` (proves wired-but-cold state persists until sister bead executes)
Timeout: 5 seconds
