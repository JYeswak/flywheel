---
schema_version: journey-entry/v1
bead_id: flywheel-5m9gp
task_id: flywheel-5m9gp-f318b0
worker_identity: CloudyMill
ts: 2026-05-10T19:18:56Z
mission_fitness: adjacent
commit_sha: 0ac3a4d
linked_l_rules:
  - L107
  - L52
  - L70
  - L120
linked_skills:
  - canonical-cli-scoping
  - python-best-practices
  - deterministic-tick-simulation
narrative_tags:
  - cross-orch-substrate-adoption
  - blocker-discipline-load-bearing-impl
  - skillos-2j7.1-pr233-adoption
  - argparse-parents-pattern-discovery
---

# flywheel-5m9gp — journey entry

Substantive cross-orch substrate adoption. Skillos shipped PR #233
(commit 16ddc16) closing their telemetry.primary acceptance criterion
on skillos-2j7. flywheel adopts the same deterministic-tick replay-
verify wrapper, with one critical addition: **blocker-ac mode** for
the blocker-discipline doctrine's "every Nth tick" AC re-evaluation
requirement.

Most interesting moment: keeping the canonical-hash function byte-
identical to skillos's. Both orchs share the substrate-hygiene-
doctrine-cluster (blocker-discipline + git-stash-discipline). Both
treat the heartbeat receipt as a deterministic state checkpoint.
Diverging the canonical form on one side would break cross-orch
replay-verify of the SAME receipt — a failure mode the doctrine
specifically warns about (recursive-self-validation gaps). I kept
the field-exclusion list (drops `safe_unrelated_work_this_tick`)
exactly aligned with skillos's: narrative is observation, not state.

Second moment: the blocker-ac mode design. The trick was separating
two boolean signals into two separate fields:
- `verdict` = is the AC predicate a pure function over substrate?
  (PASS = h1 == h2, MISMATCH = AC touches $RANDOM or current time)
- `ac_passes_now` = does the AC's own truth currently hold?
  (rc==0 from the AC command)

The orch needs BOTH. If `verdict=MISMATCH` the AC is suspect — the
doctrine says re-author it (it's not a pure function). If
`verdict=PASS and ac_passes_now=true`, auto-close the blocker with
live-probe evidence. If `verdict=PASS and ac_passes_now=false`, the
blocker is still real — keep it open. Conflating these would lose the
load-bearing distinction.

Third moment: argparse arg-order. First cut had `--json` only on
the top-level parser. `flywheel_replay_verify.py report --json` failed
because argparse parsed `report` as the subcommand and `--json` as
unknown. Fix: `add_help=False` parent parser shared via
`parents=[common]` on EVERY subparser. UX wins: `--json` works
before OR after the subcommand. Sister tools in the canonical-cli
campaign should adopt — filing as a skill discovery.

Worked example from skillos validation: state hash `ed552165...`
reproduces here when fed the same canonical receipt. Cross-orch
substrate consistency proven.

The substrate-hygiene-doctrine-cluster keeps growing:
git-stash-discipline + blocker-discipline + (now) replay-verify
telemetry. Each adds an observability + replayability layer over a
class of silent-debt accumulation. Meadows lens: information flow.
