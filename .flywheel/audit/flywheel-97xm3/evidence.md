---
title: flywheel-97xm3 evidence — Rust-substrate-spike audit
type: evidence
created: 2026-05-10
bead: flywheel-97xm3
parent: research-triad fork a5805b5dec
chain: rust-substrate-spike
---

# flywheel-97xm3 evidence

**Status:** DONE — read-only audit complete; substantive findings authored at `beads-rust-canonical-cli-audit.md`.

## Acceptance gates

| AG | Status | Evidence |
|---|:-:|---|
| AG1: clone or use existing beads_rust source | DID | `~/Developer/beads_rust` HEAD `1a72cb42` (gh clone not needed) |
| AG2: compile + run br --help | DID | `br 0.2.5` already built at `/Users/josh/.cargo/bin/br`; `--help` lists 40+ subcommands |
| AG3: execute canonical-cli-scoping/check-cli-scoping.sh | DID | raw output captured at `check-cli-scoping-raw.txt`; rc=1 |
| AG4: report 13/13 score breakdown | DID | **4 PASS / 9 FAIL** literal; **calibrated 4 full + 6 partial-shape + 3 truly-missing** |
| AG5: 13/13 → migration template; <13 → enumerate gaps | DID | 4 < 13 → enumerated 9 gaps with subcommand-vs-flag shape mapping |
| AG6: document findings | DID | `beads-rust-canonical-cli-audit.md` (200 lines, full breakdown + recommendation) |
| AG7: recommend migration shape (clone+adapt vs fork vs new crate) | DID | **clone+adapt** with two-step path (Option A: calibrate skill, Option B: layer aliases); recommendation to Joshua: yes, stamp Rust, beads_rust IS the template |

did=7/7, didnt=none, gaps=none.

## Headline finding

beads_rust **passes the substrate bar but misses the canonical-cli-scoping shape bar**. Score is 4/13 by literal checker, but 9/13 are present-with-different-naming (clap subcommand-style instead of shell flag-style). True structural gaps are 3: `quickstart` subcommand, `--examples` flag, `repair --dry-run` discipline.

## Strong points

- clap 4.5 (derive + env + unstable-ext) — production Rust CLI framework
- `--json` + `--format toon` (token-efficient) + `BR_OUTPUT_FORMAT` env override
- `br schema` emits 33KB of structured per-command output schemas
- `br doctor --json` emits 80KB of structured per-check output
- Dedicated agent-friendliness artifacts: `AGENT_FRIENDLINESS_REPORT.md`, `agent_baseline/`, `ROBOT_MODE_EXAMPLES.jsonl`, `CLI_SCHEMA.json`
- Project explicitly forbids force-recursive deletion in scripts/tests — backup-aware by design

## Migration recommendation

**clone+adapt** with two-step path:

1. **Option A (low-cost)**: calibrate `canonical-cli-scoping/SKILL.md` and `check-cli-scoping.sh` to recognize clap subcommand-style equivalents (`info` ≡ `--info`, `schema` ≡ `--schema`, `doctor-with-repair` ≡ `health+repair`, `lint` ≡ `validate`, `show` ≡ `why`). Score jumps to ~10/13.
2. **Option B (small)**: layer the truly-missing 3 (quickstart subcommand, `--examples` flag-alias, repair `--dry-run` discipline) on top of beads_rust pattern. Score reaches 13/13.

## Boundary honored

- Read-only audit. No edits to `~/Developer/beads_rust/`.
- Evidence artifacts captured at `.flywheel/audit/flywheel-97xm3/`:
  - `beads-rust-canonical-cli-audit.md` (substantive findings)
  - `check-cli-scoping-raw.txt` (raw checker output)
  - `br-info-output.json` (info envelope)
  - `br-schema-output.json` (schema introspection — 33KB)
  - `br-doctor-output.json` (doctor envelope — 80KB)

## Skill auto-routes addressed

- `canonical-cli-scoping=yes` — explicitly the audit subject
- `rust-best-practices=yes` — beads_rust audit, dependency stack reviewed (clap, serde, fsqlite); cargo fmt/clippy/test not run (read-only audit, target is upstream crate)
- `python-best-practices=n/a`
- `readme-writing=n/a`

## Skill discovery

`sd_ids=canonical-cli-scoping-shape-calibration-for-clap-style-class` — when
the canonical-cli-scoping checker is shell-flag-shaped but the target CLI is
clap subcommand-shaped, the gap is a checker-calibration issue, not a
substrate weakness. Sister to today's calibrate-to-actual-contract family.

## Cross-references

- Joshua's signoff 2026-05-10T17:18Z: "Rust is largely the framework"
- Research-triad fork `a5805b5dec` (2026-05-10T17:11Z)
- This audit: `flywheel-97xm3`
- canonical-cli-scoping skill: `~/.claude/skills/canonical-cli-scoping/SKILL.md`
- beads_rust upstream: `https://github.com/Dicklesworthstone/beads_rust`
- Local clone: `~/Developer/beads_rust` HEAD `1a72cb42`
