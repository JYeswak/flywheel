---
bead_id: flywheel-t53xc
task_id: flywheel-t53xc-dfb9b6
worker_identity: MistyCliff
ts: 2026-05-10T03:38:48Z
mission_fitness: adjacent
commit_sha: pending
linked_incidents: []
linked_l_rules: []
linked_skills:
  - binary-atomic-swap-darwin (proposed)
narrative_tags:
  - ntm-rebuild
  - darwin-arm64-cp-signature-trap
  - reflexive-rollback-discipline
  - skill-discovery-pattern-emerged
---

The build was uneventful — make output reported the real commit
hash directly in the ldflags, dist binary version reported
`commit=7d1fc78ebf19af12b193c972d25016ec707d8f87`, AG1 cleared in
30 seconds.

The interesting failure was AG2. The cp succeeded, shasum matched
the source byte-for-byte, but the new `~/.local/bin/ntm` returned
**exit 137 with empty output** on every invocation. Same bytes,
different inode, kernel SIGKILL. Spent ~90 seconds isolating it:
checked xattrs (only `com.apple.provenance`), ran codesign -v on
both files (no helpful output), then guessed Gatekeeper /
ad-hoc-signature based on the SIGKILL pattern. `codesign -f -s -
<path>` recovered the binary on first try.

This is the canonical darwin/arm64 trap for atomic-swap operations:
when you cp a binary on top of an existing one, even though the
file content is identical, the kernel won't run the result without
a valid signature. The build output at `~/Developer/ntm/ntm` had
been ad-hoc-signed by the kernel on first run; the cp destination
inherited the bytes but not the kernel-side signature trust. The
re-sign restores it. Filed as `skill-discovery/v1` row
`sd-45e6cab585454892` proposing a `binary-atomic-swap-darwin`
skill — this WILL recur every time anyone swaps a darwin binary,
and the SIGKILL diagnosis takes longer than the fix.

The spec at `.flywheel/audit/flywheel-u4fmq/apply-spec.md` should
gain a Step 2.5: `codesign -f -s - <destination>` after cp,
mandatory on darwin. Not editing the spec here — it's frozen as the
artifact the parent bead committed against — but the followup bead
mentioned in the spec (`flywheel-u4fmq-doctrine` for L87 sunset)
should also bundle this amendment.

Spec drift on `dist/ntm` vs `./ntm`: the spec said `dist/ntm` but
the Makefile's `-o ntm` writes to top level. Adapted in-flight.
Worth flagging in evidence so the next worker knows the actual path.

The post-recovery state is clean: 7/7 stale-error-auto-ping PASS,
backup retained at known path, rollback recipe is `cp .bak back +
codesign -f -s -` (i.e., the rollback also needs the codesign step
for the same reason). 35ms swap target hit (well under 100ms), no
fleet-visible interruption.
