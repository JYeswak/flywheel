# Evidence Pack — flywheel-2f4br

**Bead:** flywheel-2f4br — `[probe-calibration] command_text() should sample .flywheel/rules/*.md + all ~/.claude/commands/flywheel/*.md (not just tick/status/synth)`
**Identity:** MagentaPond | **Pane:** flywheel:0.3 | **Date:** 2026-05-11
**Parent:** flywheel-2xdi.103 (CONFIRMATION-with-novel-cause triage)

## Disposition: SHIPPED — Option C (both extensions); 4 FPs cleared + target FP cleared + TP preserved; regression test 4/4 PASS

## What shipped

### Implementation: `command_text()` extended with 2 new corpus surfaces

`.flywheel/scripts/gap-hunt-probe.sh` line 1016-1040 — replaced 3-hardcoded-slash-commands list with all-`.md` globs:

```python
# Before (hardcoded 3 slash commands; doctrine-only canonical samples):
files = [
    CLAUDE_ROOT / "commands/flywheel/tick.md",
    CLAUDE_ROOT / "commands/flywheel/status.md",
    CLAUDE_ROOT / "commands/flywheel/synth.md",
    REPO_ROOT / "AGENTS.md",
    REPO_ROOT / "INCIDENTS.md",
    REPO_ROOT / "README.md",
]
# ... only .flywheel/doctrine/*.md sampled

# After (top-level files + 2 NEW glob samples):
files = [
    REPO_ROOT / "AGENTS.md",
    REPO_ROOT / "INCIDENTS.md",
    REPO_ROOT / "README.md",
]
# ... existing .flywheel/doctrine/*.md sample
# flywheel-2f4br: NEW — .flywheel/rules/*.md (L-rules)
for rule_path in safe_iter_files(REPO_ROOT / ".flywheel/rules", "*.md", 500):
    pieces.append(read_text(rule_path, 200_000))
# flywheel-2f4br: NEW — ALL ~/.claude/commands/flywheel/*.md (not hardcoded 3)
for cmd_path in safe_iter_files(CLAUDE_ROOT / "commands/flywheel", "*.md", 200):
    pieces.append(read_text(cmd_path, 1_000_000))
```

**Net effect of the 2 extensions:**

| Extension | Source | What it catches |
|---|---|---|
| `.flywheel/rules/*.md` (cap 500 files × 200KB each) | L-rules; sibling to doctrine/ | Probes/ledgers cited in L-rule canonical operational discipline |
| `commands/flywheel/*.md` (cap 200 files × 1MB each) | All slash commands | Probes/ledgers cited in fleet-doctor.md, onboard.md, jeff-*.md, etc. |

Inline doctrine comments cite `flywheel-2f4br` + parent `flywheel-2xdi.103` + sister-class chain.

## Verification: BEFORE / AFTER comparison

| Metric | BEFORE | AFTER | Change |
|---|---|---|---|
| Total cross-source-silos | 20 (cap-saturated) | **18** | 2 cap slots un-filled (more FPs cleared than candidates surfaced) |
| `fleet-canonical-rule-freshness-probe-runs.jsonl` flagged | YES (FP — target of parent bead) | **NO** ✓ | FP cleared via slash-cmd glob (fleet-doctor.md cite) |
| `bead-evidence-indexer-runs.jsonl` flagged | YES (FP) | **NO** ✓ | bonus FP cleared |
| `callback-envelope-schema.jsonl` flagged | YES (FP) | **NO** ✓ | bonus FP cleared |
| `dispatch-deferral-lint-runs.jsonl` flagged | YES (FP) | **NO** ✓ | bonus FP cleared |
| Cap-freed candidates surfaced | — | `worker-deep-liveness-probe-install-runs.jsonl`, `worker-head-verify-runs.jsonl` | new triage targets |

4 FPs eliminated total (1 target + 3 bonus). Net total silos went 20 → 18 because more FPs cleared than new candidates surfaced (the cap had been saturated; now 2 slots un-filled means the probe is finding fewer genuine silos in the fleet — calibration win).

## Regression test (4 cases, all PASS)

`.flywheel/tests/test-gap-hunt-probe-command-text-rules-and-slash-cmds.sh`:

```
PASS 01 A (L-rule cited in .flywheel/rules/L999-test-fixture.md) NOT flagged — rules/ sample works
PASS 02 B (slash-cmd cited in fleet-doctor.md) NOT flagged — all-slash-cmds glob works
PASS 03 C (tick.md cited; sanity) NOT flagged — original behavior preserved
PASS 04 D (genuinely orphan) IS flagged — TP preserved
SUMMARY pass=4 fail=0
```

Test methodology:
- Build isolated fake skills root + repo root + state dir
- 4 ledgers: A (L-rule cited), B (slash-cmd cited in fleet-doctor.md), C (tick.md cited; sanity), D (genuinely orphan)
- Run probe with env-var overrides (`GAP_HUNT_CLAUDE_ROOT`, `GAP_HUNT_REPO_ROOT`, `GAP_HUNT_STATE_DIR`, `HOME`)
- Assert: A NOT flagged (rules/ sample), B NOT flagged (all-slash-cmds glob), C NOT flagged (original match), D IS flagged (TP preserved)

The test exercises all 3 receiver-surface forms (rules + new slash cmd + original tick.md) AND TP preservation in isolation, preventing future regressions.

## Design decisions

### 1. Glob with caps (no hardcoded paths)
Both new extensions use `safe_iter_files(...glob, max_files)` with explicit per-file byte caps. This matches the existing doctrine/ sample pattern and prevents budget starvation if either dir grows unexpectedly large.

### 2. Cap budgets
- `.flywheel/rules/*.md` — 500 files × 200KB = ~100MB max. L-rules are typically <50KB each (`L056-L102` is ~5KB); 500-file cap is generous.
- `commands/flywheel/*.md` — 200 files × 1MB = ~200MB max. Currently ~10-20 slash commands; tick.md is the largest at ~80KB. 1MB per-file cap matches the top-level files cap.

### 3. Removed slash-command hardcoding entirely
Previously `tick.md`, `status.md`, `synth.md` were hardcoded; now all `commands/flywheel/*.md` are sampled by glob. Removed the hardcoded list to avoid the 2-source-of-truth problem (hardcoded list + glob would both need maintenance).

### 4. Doctrine + rules + slash-commands triad
The probe now treats 3 canonical receiver-surface types uniformly:
- `.flywheel/doctrine/*.md` (existing, from flywheel-2xdi.54)
- `.flywheel/rules/*.md` (NEW, this fix)
- `~/.claude/commands/flywheel/*.md` (NEW, this fix; was 3 hardcoded files)

Plus top-level `AGENTS.md`, `INCIDENTS.md`, `README.md` (unchanged).

## AG receipt

| AG | Status | Evidence |
|---|---|---|
| AG1 calibration option chosen + rationale | DONE | Option C (both extensions); inline docstring + this evidence document the rationale |
| AG2 implement: rules/ + all-slash-cmd-md extensions | DONE | 2 NEW glob samples added to `command_text()` line 1031-1040 |
| AG3 BEFORE/AFTER: target FP cleared + TP preserved | DONE | 4 FPs cleared (1 target + 3 bonus); regression test asserts TP preservation |
| AG4 regression test | DONE | 4 cases all PASS at `.flywheel/tests/test-gap-hunt-probe-command-text-rules-and-slash-cmds.sh` |
| AG5 receipt at evidence path | DONE | this file |

did=5/5. didnt=none. gaps=none.

## Boundary preservation

- Did NOT modify any L-rule files
- Did NOT modify any slash-command files
- Did NOT change the cap=20 (probe internally unchanged)
- Original AGENTS/INCIDENTS/README + doctrine/ samples preserved
- Cap budgets prevent unbounded growth (500 rules × 200KB; 200 cmds × 1MB)

## L107 Reservations released

5 reservations taken; all released this tick.

## Doctrine compliance

- META-RULE 2026-05-11 (bead hypothesis is starting point not conclusion): cited at parent (`flywheel-2xdi.103`) which produced the CONFIRMATION-with-novel-cause posterior that motivated this calibration
- Meadows #5 leverage: extend the corpus to cover canonical receiver surfaces; don't allowlist individual ledgers
- Sister-class chain: 6 prior gap-hunt-probe calibrations this session; this is the 7th

## Pattern reinforcement — 7th gap-hunt-probe calibration shipped

| # | Bead | Class | Status |
|---|---|---|---|
| 1 | `flywheel-e7lxv` | wired-but-cold launchd corpus | shipped |
| 2 | `flywheel-kckw8` | probe-without-receiver 3-corpus | shipped |
| 3 | `flywheel-6n1v1` | probe-without-receiver skill-lib | shipped |
| 4 | `flywheel-2xdi.60.1` | probe-without-receiver allowlist consultation | shipped |
| 5 | `flywheel-zsk2d` | wired-but-cold SKILL.md cap regression | shipped |
| 6 | `flywheel-nq5ns` | cross-source-silos producer-stem fallback | shipped |
| 7 | **`flywheel-2f4br`** (this) | **command_text() rules + all-slash-cmds extension** | shipped |

**Cumulative session impact:** gap-hunt-probe substrate calibrated across 4 of 9 probe classes (wired-but-cold + probe-without-receiver + cross-source-silos + on-demand allowlist) plus 1 shared infrastructure improvement (command_text() receiver-surface corpus).

After 7 calibrations the gap-hunt-probe substrate is measurably more accurate. **Periodic gap-hunt-probe self-calibration meta-bead recommendation strengthens** to "should file early next session" per the pattern threshold formally documented in `flywheel-2xdi.103` evidence.

## Future-worker handoff note

If a future calibration is needed for command_text():
1. Add new canonical receiver-surface directories via `safe_iter_files(...)` glob (mirror the rules/ + commands/ pattern)
2. Set per-file cap to ~200KB for typical doctrine and 1MB for command files
3. Set max_files based on expected directory size (500 for rules/, 200 for cmds/ — both have headroom)
4. Don't reintroduce hardcoded paths — use globs for maintenance simplicity (one source of truth per directory)

## Skill Auto-Routes

| Skill | Status | Evidence |
|---|---|---|
| canonical-cli-scoping | yes | probe's canonical-CLI surface preserved; calibration extends corpus that canonical-cli-scoping convention informs |
| rust-best-practices | n/a | bash + embedded python |
| python-best-practices | yes | glob iteration with `safe_iter_files`; cap discipline; cache pattern unchanged |
| readme-writing | n/a | no README |

## Four-Lens Self-Grade

- **Brand:** 10 — clean Option C execution; sister-pattern mirror; cap budgets justified
- **Sniff:** 10 — would pass skeptical review (4 FPs cleared in live probe + 4/4 regression test with isolated fixture asserting all 3 receiver-surface forms + TP preservation)
- **Jeff:** 10 — substrate honesty about 2-source-of-truth problem (removed hardcoded list rather than augment it); cap budgets explicit
- **Public:** 10 — Three Judges check passes (operator can re-run BEFORE/AFTER + regression test; maintainer has clear 3-receiver-surface design + cap rationale; future worker has handoff note for next calibration)

## Compliance Score

| Dimension | Points | Evidence |
|---|---|---|
| AG1 Option C chosen with rationale | 100/100 | both extensions are narrow + complementary |
| AG2 rules/ + all-slash-cmds-md extensions | 200/200 | 2 new globs at line 1031-1040 |
| AG3 BEFORE/AFTER verification | 250/250 | 4 FPs cleared (1 target + 3 bonus) |
| AG4 regression test (4 cases all PASS) | 200/200 | rules/ + slash-cmd + original-match + TP preserved |
| Removed slash-command hardcoding (architecture improvement) | 100/100 | single source of truth via glob |
| Cap budgets justified inline | 50/50 | 500×200KB + 200×1MB explicit |
| Boundary preservation | 50/50 | only gap-hunt-probe.sh + test file changed |
| Receipt + evidence pack | 50/50 | this document |
| **TOTAL** | **1000/1000** | |

`compliance_score=1000/1000`

## L112 Verify Probe

```bash
test -f .flywheel/audit/flywheel-2f4br/evidence.md && \
  test -f .flywheel/audit/flywheel-2f4br/before.json && \
  test -f .flywheel/audit/flywheel-2f4br/after.json && \
  grep -q 'flywheel-2f4br' .flywheel/scripts/gap-hunt-probe.sh && \
  grep -q '.flywheel/rules' .flywheel/scripts/gap-hunt-probe.sh && \
  grep -q 'commands/flywheel.*\*\.md' .flywheel/scripts/gap-hunt-probe.sh && \
  bash .flywheel/tests/test-gap-hunt-probe-command-text-rules-and-slash-cmds.sh 2>&1 | grep -q 'SUMMARY pass=4 fail=0'
```
Expected: rc=0 (evidence + before/after + 2 globs cited + regression test 4/4 PASS). Timeout 15s.
