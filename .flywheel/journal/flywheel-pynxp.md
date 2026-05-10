---
schema_version: journey-entry/v1
bead_id: flywheel-pynxp
task_id: flywheel-pynxp-18ce5e
worker_identity: CloudyMill
ts: 2026-05-10T18:08:40Z
mission_fitness: adjacent
commit_sha: a9f1312
linked_l_rules:
  - L107
  - L52
  - L70
  - L120
linked_skills:
  - canonical-cli-scoping
  - git-stash-janitor
narrative_tags:
  - doctrine-implementation
  - L120-extension
  - fleet-wide-discipline-wire
---

# flywheel-pynxp — journey entry

P0 substantive build, not a fillin. Wired the just-drafted git-stash-
discipline doctrine into 4 enforcement points: worker close gate,
orch STATE.md probe, flywheel-loop doctor, template mirror. Live
test on flywheel itself — N=2 stashes — produced exactly the
predicted "notable signal but no halt" outcome.

Most interesting moment: idempotent STATE.md tagged-block update.
First cut had a regex that required `<!-- end -->\n` (trailing
newline). Bash command substitution `$(...)` strips trailing
newlines from the captured BLOCK_BODY. So after first apply, the
file ended at `<!-- end -->` with no \n. Second apply's regex
search returned 0 matches, so it appended again. Third apply
regex matched ONE block (the second), replaced it, but left two.
Fix is two-fold: (1) Python ensures new_block ends with \n
regardless of bash stripping, (2) regex tolerates absent trailing
newline (`\n?`). Five reruns now produce one block. Lesson: bash
command substitution is a string-stripper; any downstream consumer
that depends on trailing-newline-as-record-terminator must defend.

Second moment: --examples --json arg-order. The arg loop hit
`--examples` before `--json`, so JSON_OUT was 0 when examples()
ran, emitting a heredoc text instead of JSON. Test 4 caught it
with a jq parse error. Fix is the standard "first-pass for global
flags before action dispatch" pattern: scan args for `--json` once
before entering the main loop. Sister surfaces in the canonical-cli
campaign should adopt the same scan to avoid this trap.

Third: the validator stash check fires from the **validator's own
sibling script**, not from the **target repo's** scripts. First
cut used `$REPO/.flywheel/scripts/stash-discipline-check.sh` —
which fails when --repo points at a tmp test repo with no flywheel
substrate. Fix: `$(dirname ${BASH_SOURCE[0]})/stash-discipline-
check.sh` always finds the sibling. Validator stays repo-agnostic;
the GATE binary is fleet-wide.

The doctrine itself is load-bearing. Joshua surfaced the snapshot
`flywheel: N=2, skillos: N=16 (P0 cleanup needed)`. Skillos crosses
the halt threshold. With this wire in place, the next skillos worker
to attempt close will get rejected by their own validator —
discipline propagates by REFUSAL, not nagging.
