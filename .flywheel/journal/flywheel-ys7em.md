---
bead_id: flywheel-ys7em
task_id: flywheel-ys7em-a98097
worker_identity: MistyCliff
ts: 2026-05-10T04:23:10Z
mission_fitness: adjacent
commit_sha: pending
linked_incidents: []
linked_l_rules:
  - L63
linked_skills: []
narrative_tags:
  - jeff-corpus-substrate
  - api-substrate-replaces-clone
  - parallel-stdout-interleave-trauma
  - canonical-cli-scoping-conformance
  - 8-bead-collapse
---

The interesting decision was the bead spec collapse: where the J3-J11
chain wanted local clones + dedupe + index + daily-diff-from-clones
infrastructure spread over 8 beads, the API path collapses all of it
into a single bead with 7 acceptance gates. The argument is purely
mission-fit: Joshua needs to *see the diffs daily*, not have the
content waiting locally. GitHub's REST + Search APIs already serve
exactly that need at one-call-per-endpoint granularity; cloning all
178 repos buys nothing but disk pressure (which is exactly the class
of problem flywheel-9hnp3/0avrn just spent the morning fighting).

The collector's parallel-stdout-interleave bug was the load-bearing
fuckup. xargs `-P 8` parallel jobs writing to the same fd via
command-substitution `$()` followed by `>>` buffer-and-write is fine
for short lines (under PIPE_BUF, ~4KB on macOS) but races when one
worker emits 5KB+ of JSON while another flushes — the OS doesn't
guarantee atomic write of arbitrary-length lines, so frankenredis's
multi-thousand-char output got spliced with frankenjax's. The fix is
the canonical pattern: per-job output file under a mktemp dir, then
concat. Filing as skill-discovery candidate
`xargs-parallel-large-line-stdout-interleave-class` because this WILL
recur: anyone writing parallel xargs jobs that emit non-trivial JSON
falls into this pit. The mitigation needs to be reflexive — start
with per-job files, never with shared-fd append.

The e2e test's first version had the dual problem of "verifying the
production path" and "needing isolation from production state." It
ran `--apply --only=ntm` against the canonical state dir and quietly
overwrote today's full-corpus snapshot with a one-repo subset. Caught
when re-rendering the inaugural report showed only 1 repo / 20
commits. Fix: `JEFF_DIFF_STATE_DIR=$TMPDIR/state` env override + seed
a synthetic single-repo cache. Now the e2e exercises the real binary
path AND respects production state. This is the canonical shape for
"smoke that touches an idempotent collector": stub the env to
sandbox state, exercise the actual code, restore production via a
real run after.

The 1167-commit / 24-active-repo / 5-release inaugural report shape
matches the spec's <2-min skim claim. ultimate_bug_scanner cutting
5 patch releases in the window is the kind of high-signal event that
would have taken Joshua 5+ minutes to discover by hand and gets
surfaced in 30 seconds via the report. Mission anchor satisfied.

The L63 update lives at `Evidence:` in the rule file rather than as
a new line under `How to apply:`, because the new feed is *evidence*
that the L63 rule's intent (don't manually re-discover Jeffrey's
work) is being mechanized — not a new applicability rule itself.
That distinction matters when the next worker reads L63: they should
see "this is what the rule looks like in practice" before they see
"here's another way to apply it."
