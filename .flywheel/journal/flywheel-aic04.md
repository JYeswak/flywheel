---
bead_id: flywheel-aic04
task_id: flywheel-aic04-258c0c
worker_identity: MistyCliff
ts: 2026-05-10T02:38:00Z
mission_fitness: adjacent
commit_sha: 5f3a463
linked_incidents:
  - feedback_basename_keying_collision_class
linked_l_rules: []
linked_skills: []
narrative_tags:
  - substrate-hygiene
  - cross-repo-commit
  - case-portability
  - layered-disposition
---

The trauma class was silent on macOS APFS — `.flywheel/plans/` and
`.flywheel/PLANS/` aliased to the same inode, so the lowercase
references passed every local test. Linux ext4 would have surfaced
the bug as a "No such file or directory" at the first deployment.
The sweep audited 11 active code references (per the bead body's
grep snapshot) and triaged each into one of three dispositions:
normalize to canonical uppercase (7 references in 7 files), preserve
case-fallback discipline (2 references in 2 files, per
flywheel-4rmc precedent), or no-op (1 synthetic mktemp test
fixture). The cross-repo split landed naturally — 4 normalizations
in flywheel via commit 5f3a463, 3 in ~/.claude via commit 98238858
— with the audit pack pinning both. 10-test regression covers all
three disposition classes plus bash/python syntax invariants. The
load-bearing decision: refusing to flatten the case-fallback
patterns into uniform PLANS/ would have broken the canonical
defensive walks that flywheel-4rmc shipped intentionally for
case-insensitive-FS edge cases. Left those alone, cited the
precedent, moved on.
