# flywheel-2xdi.66 — Evidence Pack

**Bead:** flywheel-2xdi.66 (P3)
**Title:** [gap-wired-but-cold] `.claude/skills/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools/scripts/cluster-recommendations.sh`
**Mission fitness:** `adjacent` — probe corpus accuracy supports continuous orch uptime by removing false-positive cold flags.

## Hypothesis vs Root Cause (Meadows #5 leverage, instance N=10)

**Bead hypothesis (auto-filed):** `cluster-recommendations.sh` is wired-but-cold (script not invoked by recent flywheel jsonl ledgers).

**Root cause found:** Script IS wired — documented as a use case in
`~/.claude/skills/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools/references/calibration-fixtures/README.md:51`:

> **Regression test for clusterer**: when re-running `scripts/cluster-recommendations.sh` against `bv-dogfood-2026-05-07.recommendations.jsonl`, the default threshold (3) should produce 3 clusters.

The probe's `skill_md_corpus()` only scanned `SKILL.md` files at skill roots, not tree-internal docs (`references/**/README.md`, `assets/**/*.md`). Same META-rule shape as 2xdi.47, .49, .64: probe corpus blind spot, not dead code.

## Fix

`.flywheel/scripts/gap-hunt-probe.sh` — `skill_md_corpus()`:

1. **Glob broadened:** `SKILL.md` → `*.md`. The candidate set now includes any markdown under `~/.claude/skills/`, covering tree-internal docs (references, assets, etc.).
2. **Per-file cap:** introduced `per_file_cap = 4_096` so a single large file (e.g., `CHANGELOG.md` at 350KB) can no longer devour the budget at the front of iteration order.
3. **Overall budget bumped:** `1.5MB` → `32MB` to fit the broader corpus.
4. **File count cap raised:** `1000` → `6000` to cover the full skills tree (5561 *.md observed).

The function name + cache key remain `skill_md_corpus` / `_SKILL_MD_CORPUS` because the semantic intent is unchanged: skill-tree markdown documentation = wiring evidence.

## Verification

| Gate | Command | Result |
|---|---|---|
| Probe syntax | `bash -n .flywheel/scripts/gap-hunt-probe.sh` | OK |
| Live probe — target gone | `bash .flywheel/scripts/gap-hunt-probe.sh --json \| jq '[.gap_ids[] \| select(test("cluster-recommendations"))] \| length'` | `0` |
| Live probe — archetype sister still clean | `... select(test("archetype-calibrate"))` | `0` |
| Live probe — protected sister still clean | `... select(test("protected-session-recovery"))` | `0` |
| New regression | `bash tests/gap-hunt-probe-skill-tree-md-corpus.sh` | 6/6 PASS |
| Sister 47 | `bash tests/gap-hunt-probe-for-loop-source-corpus.sh` | 4/4 PASS |
| Sister 49 | `bash tests/gap-hunt-probe-skill-md-corpus.sh` | 5/5 PASS |
| Sister 64 | `bash tests/gap-hunt-probe-exec-sh-corpus.sh` | 5/5 PASS |

## DID / DIDNT / GAPS

- **DID 4/4**
  - `skill_md_corpus` glob broadened from `SKILL.md` to `*.md`
  - Per-file cap added (prevents single-file budget exhaustion)
  - Regression test `tests/gap-hunt-probe-skill-tree-md-corpus.sh` (6/6 PASS) using REAL probe fields
  - Sister suites verified green (no regression)
- **DIDNT none**
- **GAPS** = `flywheel-f1s2x` — sister regression tests (2xdi.47, .49, .64) use vacuous `.gaps // []` filter on JSON output that has no `.gaps` field; assertions pass vacuously. Filed as P2 bug.

## Files Changed

- `.flywheel/scripts/gap-hunt-probe.sh` — `skill_md_corpus()` glob + per-file cap + budget
- `tests/gap-hunt-probe-skill-tree-md-corpus.sh` (new, +110 lines)

## L112 Probe

- `l112_probe_command`: `bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '[.gap_ids[] | select(test("cluster-recommendations"))] | length'`
- `l112_probe_expected`: `literal:0`
- `l112_probe_timeout_sec`: `120`

## Pattern reinforcement

This is the 4th probe-corpus-extension fix in the 2xdi cluster (47, 49, 64, 66).
Cumulative META-rule: **when a bead with class=wired-but-cold appears, default
first action is to investigate the suspect script's documented invocation
paths AND wrapper scripts. If the pattern is unrecognized by the probe's
corpus collector, extend the corpus, not the script.**

Bead-hypothesis-is-prior META-rule now at N=10 instances this session.
