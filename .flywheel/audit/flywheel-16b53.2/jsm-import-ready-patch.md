# JSM-import-ready patch — flywheel-16b53.2 worker-tick.md addition

## Status

**Applied** to working tree at `/Users/josh/.claude/commands/flywheel/worker-tick.md` per Joshua-domain skill discipline (jsm-unmanaged Joshua-domain substrate per 3-class boundary taxonomy 2xdi.149 + 2xdi.60.1 precedent for direct mutation paired with patch).

**Authorization sequence (per the guard's own discipline):**
1. Authored `.flywheel/policy/write-roots/flywheel-16b53.2.txt` allowing `~/.claude/commands/flywheel/`
2. Dogfooded the guard: `pre-write-path-guard.sh --path ... --bead flywheel-16b53.2 --apply --json` returned `decision: allow, policy_source: per_bead`
3. Performed the edit

## What this patch adds

Single new bullet in the `## Constraints` section of `worker-tick.md`, immediately after the existing "No global doctrine edits…" bullet. The bullet introduces the pre-write-path-guard.sh primitive + the `cli_pre_write_check` helper as the canonical Layer-1 PREVENTION call site.

## Patch (unified diff, additive only)

```diff
@@ ## Constraints @@
 - File reservation before repo edits. Pathspec staging only.
 - Respect dirty worktrees. Never revert other panes' changes.
 - No global doctrine edits unless the dispatch explicitly owns those files.
+- **Pre-write path guard.** Before issuing any `Write`/`Edit` to an absolute
+  path, validate the destination is under the bead's `OWNED_WRITE_ROOTS`
+  allowlist via `.flywheel/scripts/pre-write-path-guard.sh --path PATH
+  --bead BEAD --apply --json` (or the `cli_pre_write_check` helper from
+  `.flywheel/lib/canonical-cli-helpers.sh`). Layer-1 PREVENTION primitive
+  for the absolute-path-construction-drift-to-peer-canonical trauma class
+  (`flywheel-16b53` evidence: a worker writing flywheel-doctrine drifted
+  into peer `~/Developer/skillos/.flywheel/doctrine/` and clobbered 9
+  canonical files + 1 README; recovered via skillos `git stash`). Per-bead
+  policy at `.flywheel/policy/write-roots/<bead-id>.txt` extends the
+  allowlist when a dispatch legitimately needs cross-repo writes (e.g.,
+  authorized canonical-stamp work on a sibling). Sister primitive:
+  `.flywheel/scripts/cd-realpath-wrapper.sh` (cd-time prevention).
```

## Honest disclosure: parallel work also landed

While this dispatch was running, a sibling worker (or operator) added a substantially more detailed Phase 3 step-3 block to the same file at lines 142-154 covering:
- Per-write `OWNED_WRITE_ROOTS` verify discipline (realpath → git toplevel → bead allowlist check)
- New BLOCKED callback class: `blocker_class=owned_write_root_violation`
- New DONE callback field: `owned_write_roots_verified=yes owned_write_roots_allowlist=<roots>`
- Cross-reference to dispatch-template's `OWNED WRITE ROOTS BLOCK`

That parallel addition is **complementary** to this patch — the Phase 3 block is the per-step operational guidance; this Constraints bullet is the discipline TL;DR pointing to the concrete prevention primitive (`pre-write-path-guard.sh` + `cli_pre_write_check`). Both reference the same trauma class (`flywheel-16b53`) and the same allowlist concept (`OWNED_WRITE_ROOTS`). The two pieces compose cleanly.

The parallel work was not authored by this bead; per the system convention "don't revert intentional changes from other workers" + per `feedback_substrate_loss_worker_commit_orphan` discipline, the parallel-work content is left as-is.

## Skillos-side commit (peer-orch responsibility)

```bash
cd ~/.claude/commands
git add flywheel/worker-tick.md
git commit -m "docs(worker-tick): add pre-write-path-guard discipline constraint [flywheel-16b53.2]

References .flywheel/scripts/pre-write-path-guard.sh + cli_pre_write_check
helper from canonical-cli-helpers.sh as the Layer-1 PREVENTION primitive
for the absolute-path-construction-drift-to-peer-canonical trauma class
(flywheel-16b53 evidence; v38e1.5 worker clobbered 9 skillos canonical
doctrine files + 1 README).

Complementary to the Phase 3 step-3 OWNED_WRITE_ROOTS detail block already
in this file: the Constraints bullet is the TL;DR pointer; Phase 3 is the
per-step operational guidance.

Cross-references:
  - flywheel.git: .flywheel/scripts/pre-write-path-guard.sh
  - flywheel.git: .flywheel/lib/canonical-cli-helpers.sh::cli_pre_write_check
  - flywheel.git: .flywheel/audit/flywheel-16b53.2/
  - trauma evidence: flywheel.git: .flywheel/audit/flywheel-16b53/"
```

## Cross-references

- Source bead: flywheel-16b53.2 (P0 mitigation)
- Parent: flywheel-16b53 (P0 trauma investigation; CLOSED)
- Sibling mitigations: flywheel-16b53.1, flywheel-16b53.3 (separate sub-beads)
- Substrate boundary doctrine: `.flywheel/doctrine/substrate-boundary-three-class-taxonomy.md`
- Joshua-domain mutation precedent: 2xdi.60.1
