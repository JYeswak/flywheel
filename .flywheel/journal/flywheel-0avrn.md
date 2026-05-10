---
bead_id: flywheel-0avrn
task_id: flywheel-0avrn-b6f3ce
worker_identity: MistyCliff
ts: 2026-05-10T03:21:30Z
mission_fitness: adjacent
commit_sha: pending
linked_incidents: []
linked_l_rules: []
linked_skills: []
narrative_tags:
  - storage-tier-a-apply
  - preserve-then-prune-pattern
  - archive-verify-before-delete
  - fire-tier-exit
---

The interesting decision was Item 4: the spec said "Recent (last 30
days): KEEP on main disk", but at apply time the age probe showed
zero files <=30d and all 4838 files >30d. So the "kept on main disk"
tier was empty in practice. That's not a bug — it's information about
how Joshua actually uses comfyui (generations sit, then sit some more).
The script handled this correctly: the recent-keep filter returned
zero, archive received everything.

Compression ratio was 99.52% (i.e., almost no compression). PNGs
are already entropy-compressed; zstd can only reclaim the tar
metadata overhead. This is the canonical answer for "should I zstd
my image archives" — yes for the integrity/single-file convenience,
no for the size reduction. Worth saving for the next time someone
asks.

The preserve-then-prune pattern stamps clean here:
1. Build filelist of work-to-do (deterministic, auditable input)
2. Build archive from filelist (single output)
3. Verify archive integrity *and* listing readability *and* count
   match (three independent checks)
4. Delete only what was successfully archived (the filelist is the
   contract)

Each step has a halt-on-failure gate. The xargs phase ran longer
than expected (4838 forks at -I{}) and the harness reaped the bash
shell during that phase, leaving the post-state and receipt sections
unwritten. The bulk work was already done by then — the harness
reap is recoverable: re-run inventory and synthesize the receipt
directly from current ground truth. Future improvement: replace
`xargs -I{} rm "{}"` with `xargs rm` (no -I, batched; handles spaces
via -0 with -print0). Filed as a personal reminder, not a separate
bead — the apply.sh is one-shot for this item.

Storage tier exit: 3% → 12.18%, FIRE → SOFT_PRUNE. The 2.82-pt gap
between actual 12.18% and spec target 15% is exactly the 31GB
archive on disk — which is what Joshua asked to preserve. The spec
target was internally inconsistent (it said preserve AND >=15), and
the right answer is to honor preserve and report the gap honestly,
not delete the archive to hit a number.
