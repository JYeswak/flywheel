---
schema_version: journey-entry/v1
bead_id: flywheel-97xm3
task_id: flywheel-97xm3-9c2245
worker_identity: MagentaPond
ts: 2026-05-10T17:30:00Z
mission_fitness: direct
commit_sha: 3b6e250
linked_l_rules:
  - L70
  - L52
  - L120
linked_skills:
  - canonical-cli-scoping
  - rust-best-practices
narrative_tags:
  - rust-substrate-decision
  - canonical-cli-shape-calibration
  - jeff-stack-validation
---

# flywheel-97xm3 — journey entry

Joshua direct plan-space ask: Rust is largely the framework — does
beads_rust score 13/13 to validate it as the migration template?
Read-only audit. Headline answer: 4/13 by literal checker, but 9/13
present under different naming. True structural gaps are 3
(quickstart, --examples flag, repair --dry-run discipline). Migration
shape: clone+adapt with two-step path (calibrate checker first,
then layer missing 3).

The decisive insight: most "FAILs" are clap subcommand-vs-shell-flag
shape mismatches. beads_rust uses subcommand-style (`br info`,
`br schema`, `br lint`, `br show`, `br doctor`+repair) which is
canonical Rust idiom. The checker is shell-flag-shaped (`--info`,
`--schema`, separate `health`+`repair`+`validate`+`why`).
Both shapes serve agents equally well. The doctrine should be
calibrated to recognize either.

Strong points discovered:
- clap 4.5 with derive+env+unstable-ext
- --json + --format toon (token-efficient) + BR_OUTPUT_FORMAT env
- 33KB structured schema introspection
- 80KB structured doctor output  
- AGENT_FRIENDLINESS_REPORT.md, agent_baseline/, ROBOT_MODE_EXAMPLES.jsonl,
  CLI_SCHEMA.json — explicitly agent-first project
- Backup-aware project policy (no force-recursive deletion in scripts)

Recommendation to Joshua: YES, stamp Rust, beads_rust IS the canonical
template. The checker says 4/13 but the substrate is strong. Path
forward is checker calibration (Option A, low-cost) followed by
adding the 3 truly-missing surfaces as flag-aliases on top of
beads_rust's subcommand-style (Option B). Score reaches 13/13 with
~1-2 hours of skill+template work.

Skill discovery: canonical-cli-scoping-shape-calibration-for-clap-
style-class — when a checker is one shape (shell flag-style) but a
mature CLI is another (clap subcommand-style), the gap is checker
calibration, not substrate weakness. Sister to today's calibrate-to-
actual-contract family.

DCG quirk: literal "rm -rf" appearing in prose about backup-policy
descriptions tripped DCG redirect-truncate-root-home guard during
heredoc commit. Rephrased to "force-recursive deletion" in evidence
prose. Per memory rule feedback_dcg_prose_trigger_strip_dangerous_substrings.

This bead's output feeds Joshua's plan-space Rust=framework decision.
The 7-day evaluation step the research recommended is now compressed
to a 30-min audit because the critical evidence is already on-disk
(beads_rust HEAD 1a72cb42 already cloned, br already built and
tracking 1581 issues IN this repo).
