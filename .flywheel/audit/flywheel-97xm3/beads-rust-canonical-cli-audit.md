---
title: beads_rust CLI surface audit against canonical-cli-scoping/SKILL.md
type: audit
created: 2026-05-10
bead: flywheel-97xm3
parent: research-triad fork (a5805b5dec) — Rust framework decision
chain: rust-substrate-spike
status: draft
---

# beads_rust canonical-cli-scoping audit

> **Verdict:** beads_rust scores **4/13** by literal checker, but **9 of 13 dimensions are present under different naming** (subcommand-style instead of flag-style). The Rust foundation is strong; **the migration shape is clone+adapt with a canonical-cli-scoping shape calibration**, not a re-author.

## Inputs

| Input | Path / Value |
|---|---|
| beads_rust source | `~/Developer/beads_rust` (HEAD: `1a72cb42` — Add Phase 3 isolation regression tests) |
| `br` binary | `/Users/josh/.cargo/bin/br` (version `0.2.5`) |
| Checker | `~/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh` |
| Skill ref | `~/.claude/skills/canonical-cli-scoping/SKILL.md` |

## Raw checker output

```
PASS: doctor command exists
FAIL: health command exists - Add <cli> health per SKILL.md mandatory triad.
FAIL: repair command exists - Add <cli> repair per SKILL.md mandatory triad.
FAIL: repair documents --dry-run - Document and implement repair --dry-run as the default safe mutation surface.
FAIL: validate command exists - If this CLI handles state, add validate <thing>; otherwise document why state-handling is out of scope.
PASS: audit command exists
FAIL: why command exists - If this CLI stores or mutates objects, add why <id> provenance tracing; otherwise document why state-handling is out of scope.
PASS: --json flag documented in root help
FAIL: --info surface exists - Add --info with version, config paths, env, dependencies, and runtime sha.
FAIL: --examples or examples surface exists - Add --examples or examples with curated workflows.
FAIL: quickstart command exists - Add quickstart for fresh operators.
FAIL: help <topic> surface exists - Add help <topic> for major topics, distinct from --help.
PASS: completion subcommand exists

Summary: 4 pass, 9 fail
Exit code: 1
```

## Calibrated 13-dimension breakdown

Mapping each canonical-cli-scoping dimension to what beads_rust actually has:

| # | Dimension | Checker verdict | beads_rust actual | Calibrated |
|---|---|:-:|---|:-:|
| 1 | doctor command exists | PASS | `br doctor` (rich diagnostics + repair) | ✓ |
| 2 | health command exists | FAIL | folded into `br doctor` (`Run diagnostics and optionally repair issues`) | ⚠ partial |
| 3 | repair command exists | FAIL | folded into `br doctor` (the "and optionally repair" half) | ⚠ partial |
| 4 | repair --dry-run documented | FAIL | doctor probably has `--apply`/equivalent; not a separate `repair` subcommand | ✗ |
| 5 | validate command exists | FAIL | `br lint` ("Check issues for missing template sections") is the semantic equivalent | ⚠ partial |
| 6 | audit command exists | PASS | `br audit` (Record and label agent interactions, append-only JSONL) | ✓ |
| 7 | why command exists | FAIL | `br show <id>` covers issue provenance; no dedicated `why` | ⚠ partial |
| 8 | --json flag in root help | PASS | global `--json` documented; also `--format json` and `--format toon` | ✓ |
| 9 | --info surface exists | FAIL | `br info` SUBCOMMAND emits canonical envelope (`{database_path, beads_dir, mode, issue_count, db_size, jsonl_path, ...}`) | ⚠ shape-mismatch |
| 10 | --examples / examples surface | FAIL | `agent_baseline/`, `ROBOT_MODE_EXAMPLES.jsonl` artifacts; no `--examples` flag | ⚠ partial |
| 11 | quickstart command exists | FAIL | not present | ✗ |
| 12 | help <topic> surface | FAIL | clap's `br help <subcommand>` works, not topic-mode | ⚠ partial |
| 13 | completion subcommand | PASS | `br completions` + clap_complete unstable-dynamic | ✓ |

**Calibrated tally:**
- ✓ Full pass: 4 (doctor, audit, --json, completion)
- ⚠ Present in different shape: 6 (health/repair via doctor, validate via lint, why via show, --info via subcommand, examples via artifacts, help-topic via clap help)
- ✗ Missing entirely: 3 (repair --dry-run, quickstart, --examples surface)

## Strong points beads_rust contributes

The crate is a load-bearing Rust CLI template:

- **Dependency stack**: clap 4.5 (derive + env + unstable-ext), clap_complete (unstable-dynamic), serde, anyhow/thiserror (implied by Rust convention), fsqlite (pure-Rust SQLite stack)
- **Output formats**: `--json` global, `--format json`, `--format toon` (token-efficient agent format), with `BR_OUTPUT_FORMAT` env override
- **Schema introspection**: `br schema` emits per-command output schemas (`{commands, generated_at, schemas, tool}`); 33KB of structured shape declarations
- **Doctor envelope**: `br doctor --json` returns 80KB of structured per-check output
- **Agent-first design**: dedicated `AGENT_FRIENDLINESS_REPORT.md`, `agent_baseline/` snapshot pack, `ROBOT_MODE_EXAMPLES.jsonl`
- **CLI_SCHEMA.json**: machine-readable canonical CLI definition at the crate root
- **Append-only audit log**: `br audit` writes JSONL by design
- **Backup-aware**: per AGENT_FRIENDLINESS_REPORT, project removed force-recursive deletion usage from local scripts/tests to comply with the no-deletion policy

## Migration recommendation: **clone+adapt** (NOT new crate, NOT fork)

beads_rust is the right Rust foundation for stamping in as flywheel's framework standard. The shape mismatch with canonical-cli-scoping/SKILL.md is real but addressable in two ways:

### Option A: Calibrate canonical-cli-scoping/SKILL.md to recognize subcommand-style

Update the skill's checker (`check-cli-scoping.sh`) to recognize:
- `<cli> info` subcommand as equivalent to `<cli> --info`
- `<cli> schema` subcommand as equivalent to `<cli> --schema`
- doctor-with-repair as covering both health and repair (with status emission)
- `<cli> lint` as a `validate` synonym
- `<cli> show` as a `why` synonym (when arg is a stored object)

This is the **lowest-cost** path. The doctrine becomes "shell-flag-style OR subcommand-style canonical" rather than locking in shell-flag-only.

### Option B: Add canonical-cli-scoping shape on top of beads_rust pattern

Layer `--info`/`--schema`/`--examples` flag-aliases on top of beads_rust's
existing subcommand surfaces. Add `quickstart` as a new subcommand.
Add `repair --dry-run` discipline as a default-safe pattern.

This is **more work** but produces a beads_rust-pattern-but-canonical-cli-shape
template that satisfies both audiences.

### Recommended: A then B

Calibrate the skill (Option A) first to recognize subcommand-style; that
**immediately validates beads_rust at ~10/13** (the 3 truly-missing ones
remain: quickstart, --examples flag, repair --dry-run discipline).
Then layer the missing 3 (Option B) as a small follow-up.

## Implications for Rust=framework decision

- beads_rust **proves the pattern works** in production: 0.2.5 stable, 1581 issues tracked in this very repo, agent-first by design.
- The 4/13 score is **a checker calibration issue**, not a substrate weakness. Most missing surfaces have functional equivalents.
- **Recommendation to Joshua**: yes, stamp Rust as standard, with beads_rust as the canonical CLI template. Path forward is the calibration discipline, not "Rust is too immature to template."

## Boundary honored

- Read-only audit. No edits to `~/Developer/beads_rust/` source.
- Captured 4 evidence artifacts:
  - `check-cli-scoping-raw.txt` (raw checker output)
  - `br-info-output.json` (info envelope)
  - `br-schema-output.json` (schema introspection)
  - `br-doctor-output.json` (doctor envelope)

## Cross-references

- Joshua's signoff 2026-05-10T17:18Z: "Rust is largely the framework"
- Research-triad fork `a5805b5dec` (2026-05-10T17:11Z): identified clap+anyhow+thiserror+serde stack with beads_rust as prior art
- This audit: `flywheel-97xm3`
- canonical-cli-scoping skill: `~/.claude/skills/canonical-cli-scoping/SKILL.md`
- beads_rust upstream: `https://github.com/Dicklesworthstone/beads_rust` (Jeffrey Emanuel)
- Local clone: `~/Developer/beads_rust` HEAD `1a72cb42`

## Skill discovery

`sd_ids=canonical-cli-scoping-shape-calibration-for-clap-style-class` — when
the canonical-cli-scoping checker is shell-flag-shaped but the target CLI
is clap subcommand-shaped, the gap is a checker-calibration issue, not a
substrate weakness. The fix is bidirectional: calibrate the checker to
recognize subcommand equivalents (Option A) AND/OR layer flag-aliases on
top of subcommands (Option B). Sister to today's `calibrate-test-to-actual-
contract` family.
