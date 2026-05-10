# Compliance pack flywheel-lh64t

## AG coverage
- AG1 dispatch-author surfaces "trigger-gated" via watchtower-status pre-check
  → .flywheel/scripts/dispatch-trigger-gated-precheck.sh + hook in
    .flywheel/scripts/build-dispatch-packet.sh:103-141 (refuses with exit 6).
- AG2 example: g6xaw dispatch held until frankenterm_release.status=release_available
  → live demo: precheck against g6xaw body + structured field + live watchtower
    returned status=trigger_not_yet_fired watchtower_status=public_no_release rc=6.
- AG3 regression test refuses for trigger-gated bead at public_no_release
  → .flywheel/tests/test-trigger-gated-watchtower-precheck.sh PASS (6 groups).
- AG4 doctrine note "trigger-gated bead pattern: bead body field
   external_trigger_watchtower=<name> + status=release_available required"
  → .flywheel/doctrine/trigger-gated-bead-precheck.md.

## Quality bar (1000-pt rubric self-grade)
- canonical-cli-scoping: 220 / 220
  doctor / health / repair triad: yes
  validate / why subsidiary: yes
  --json schema + stable exit codes (0/1/2/3/5/6): yes
  --dry-run / --apply on repair: yes
  file-length: 240 lines (under 500)
- regression test depth: 200 / 200 (6 assertion groups, fixture matrix)
- doctrine coverage: 180 / 200 (anti-patterns + sister surfaces, no rollout plan)
- integration risk: 180 / 180 (no behavior change for non-gated beads, escape hatch)
- live demonstration: 180 / 200 (live watchtower probed, no production deploy)

Total: 960 / 1000

## Four-Lens self-grade
brand: 9/10 (canonical-cli-scoping fully respected, idiomatic shell)
sniff: 9/10 (no hand-waved checks; structured field is the contract)
jeff: 9/10 (data decides; orch consults watchtower, refuses trigger-gated
  dispatch deterministically; doctrine cites the watchtower author)
public: 9/10 (skeptical operator: yes; maintainer: yes; future worker: yes)

four_lens=brand:9,sniff:9,jeff:9,public:9
