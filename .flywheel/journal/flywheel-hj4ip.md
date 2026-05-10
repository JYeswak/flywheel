---
schema_version: journey-entry/v1
bead_id: flywheel-hj4ip
task_id: flywheel-hj4ip-0bffc6
worker_identity: MagentaPond
ts: 2026-05-10T16:15:00Z
mission_fitness: infrastructure
commit_sha: ec7308f
linked_l_rules:
  - L70
  - L52
  - L120
linked_skills:
  - canonical-cli-scoping
narrative_tags:
  - recovery-lane-wave-3
  - scaffolder-bug-discovery
  - bin-binaries-targeted
---

# flywheel-hj4ip — journey entry

Wave 3 of the 37-surface recovery lane. Different surface area than
prior waves (jh5bb/aav72 hit .flywheel/scripts/) — these 8 targets are
binaries under ~/.claude/skills/.flywheel/bin/, the .flywheel skill's
operational bin/. Same scaffold-only pattern, but two systemic
scaffolder bugs surfaced when applied to absolute-path skill-binary
targets:

(1) Generated test files concatenate $ROOT + absolute path → invalid
double-slash paths. Fixed in 8 generated tests via in-place sed.

(2) Scaffolder-emitted cmd_doctor/cmd_health/cmd_validate stubs use
[[ ]] && X || Y short-circuit return idiom — which the *paired*
canonical-cli-lint flags as L4 violation. Self-inconsistency: the
generator produces code that fails its own paired linter. Fixed via
python regex mass-replacement to if/then/else/fi for autoloop ×4 +
doctrine-sync ×3 + a remaining L1 chained-local on doctrine-sync:742.

Both bugs filed as flywheel-946sy (P2) for scaffolder author flywheel-
ws02m to fix at the source.

Custom domain tests for autoloop (602 lines, asserts --help doesn't
write state, --watch documented) and doctrine-sync (asserts repair
--explain works) preserved as pre-existing behavior contracts. Sister
scaffolded 13/13 tests added at tests/<binary>-canonical-cli-scaffold.sh
to validate the canonical-CLI surface independently of the domain
custom tests.

Final result: 8/8 lint clean, 104/104 canonical-CLI assertions PASS.

This work was peer-pane-committed (ec7308f) when the peer's git operation
swept up my staged files. Net effect: the wave 3 surfaces are landed +
green, the scaffolder bugs are filed for systemic fix.

Skill discovery: scaffolder-self-inconsistent-with-paired-linter-class
(generator must produce code that lints clean against its own paired
linter — fix at the source, not at each generated output).
