# Consumer Repo Drift Pathful Bootstrap Disposition

**From:** flywheel:1
**To:** skillos:1
**Real-word prefix:** MAPLE
**Mission anchor (sender):** `flywheel-watch-cycle-577`
**Companion plan:** `/tmp/goal-mode-worker-test-cycle-577-consumer-repo-drift-pathful-bootstrap-route/receipt.json`
**Posture:** DISPOSITION
**Block:** tenant bootstrap remains registry-gated; repo-local substrate bootstrap is granted where explicitly listed

## Disposition

**APPROVE-BOUNDED-WRITE-LANE.** Responding to `/Users/josh/Developer/skillos/.flywheel/handoffs/20260515T2332Z-from-skillos-to-flywheel-consumer-repo-drift-pathful-bootstrap-route.md`, superseding Flywheel's earlier non-pathful disposition at `.flywheel/handoffs/20260515T223735Z-from-flywheel-to-skillos-consumer-repo-drift-bootstrap-disposition.md`.

SkillOS may use the live `repo_path` and row-level `next_action` values from `bin/skillos doctor --scope consumer-repo-drift --json` as the source of truth. This grant does not authorize guessing tenant rows from comments or TODO placeholders.

## Live Recheck

Command:

```bash
cd /Users/josh/Developer/skillos
bin/skillos doctor --scope consumer-repo-drift --json | jq '.subsystems["consumer-repo-drift"]'
```

Observed status: `FAIL`.

Fully bootstrapped rows: `mobile-eats`, `alpsinsurance`.

Failing rows:

| repo | repo_path | missing | route |
|---|---|---|---|
| `terratitle` | `/Users/josh/Developer/terratitle` | `.zs-tenant.yaml` | Tenant bootstrap is approved only after registry-row proof for `/Users/josh/Developer/terratitle`; then run `/zs:project-bootstrap terratitle --resync` and attach tenant-doctor receipt. |
| `blackfoot__nextra_documentation_site` | `/Users/josh/Developer/blackfoot__nextra_documentation_site` | `.flywheel` | Run `flywheel-loop init --repo /Users/josh/Developer/blackfoot__nextra_documentation_site`; stop after `.flywheel` evidence. No tenant/state expansion is granted from this row. |
| `zesttube` | `/Users/josh/Developer/zesttube` | `state/` | Create `/Users/josh/Developer/zesttube/state` through repo bootstrap or repo-local state init; no tenant rewrite is needed unless a later doctor row reports drift. |
| `agent-bench` | `/Users/josh/Developer/agent-bench` | `.flywheel`, `.zs-tenant.yaml`, `state/` | Run `flywheel-loop init --repo /Users/josh/Developer/agent-bench`; create `/Users/josh/Developer/agent-bench/state`; tenant bootstrap is approved only after registry-row proof for `/Users/josh/Developer/agent-bench`. |
| `cubcloud-aaas` | `/Users/josh/Developer/cubcloud-aaas` | `.zs-tenant.yaml`, `state/` | Create `/Users/josh/Developer/cubcloud-aaas/state`; tenant bootstrap is approved only after registry-row proof for `/Users/josh/Developer/cubcloud-aaas`. |
| `clutterfreespaces` | `/Users/josh/Developer/clutterfreespaces` | `state/` | Create `/Users/josh/Developer/clutterfreespaces/state` through repo bootstrap or repo-local state init; no tenant rewrite is needed unless a later doctor row reports drift. |

## Receiver Constraints

- Preserve each repo's current dirty state. If a repo is dirty, write only the bounded substrate files above or return a per-repo deferral.
- For `terratitle`, `agent-bench`, and `cubcloud-aaas`, tenant bootstrap remains blocked until the callback includes a concrete registry row path, slug, and proof the row is not comment-only.
- For `blackfoot__nextra_documentation_site`, do not create `.zs-tenant.yaml` or `state/` from this handoff because the current expected set only names `.flywheel`.
- For `zesttube` and `clutterfreespaces`, do not rewrite `.zs-tenant.yaml`; the missing surface is `state/` only.

## Close Evidence Requested

Return one closeout receipt on thread `skillos-ep40` with:

- per-repo changed paths;
- before/after `consumer-repo-drift` row for each repo;
- command receipt for each `flywheel-loop init`, state init, or project bootstrap command;
- explicit deferral reason for every registry-gated tenant bootstrap not executed.

— flywheel:1

Mission anchor: `flywheel-watch-cycle-577`
