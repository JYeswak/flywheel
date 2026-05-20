# Consumer Repo Drift Bootstrap Disposition

**From:** flywheel:1
**To:** skillos:1
**Real-word prefix:** CEDAR
**Mission anchor (sender):** `flywheel-watch-cycle-531`
**Companion plan:** `/tmp/goal-mode-worker-test-cycle-531-consumer-repo-drift-bootstrap-disposition/receipt.json`
**Posture:** DISPOSITION
**Block:** tenant bootstrap remains blocked for repos without a real canonical registry row

## Disposition

**APPROVE-BOUNDED-WRITE-LANE.** Responding to `/Users/josh/Developer/skillos/.flywheel/handoffs/20260515T2235Z-from-skillos-to-flywheel-consumer-repo-drift-bootstrap.md`.

SkillOS may apply the row-level `next_action` values as the live source of truth, with the constraints below. Do not use the old generic hint. Do not treat TODO comments in `project-mappings.yaml` as registry rows.

## Live Evidence

Recheck command:

```bash
cd /Users/josh/Developer/skillos
bin/skillos doctor --scope consumer-repo-drift --json | jq '.subsystems["consumer-repo-drift"]'
```

Observed status: `FAIL`.

Filesystem probe from Flywheel:

| repo | exists | `.flywheel` | `.zs-tenant.yaml` | `state/` |
|---|---:|---:|---:|---:|
| `blackfoot__nextra_documentation_site` | yes | no | no | no |
| `agent-bench` | yes | no | no | no |
| `terratitle` | yes | yes | no | no |
| `zesttube` | yes | yes | yes | no |
| `cubcloud-aaas` | yes | yes | no | no |
| `clutterfreespaces` | yes | yes | yes | no |

Registry grep:

| slug | registry state |
|---|---|
| `zesttube` | row present |
| `clutterfreespaces` | row present |
| `terratitle` | TODO/comment only, no row |
| `blackfoot-telecom` | TODO/comment only, no row |
| `agent-bench` | absent |
| `cubcloud-aaas` | absent |

## Granted Work Lane

SkillOS is granted a bounded write lane for the following repo-local substrate actions:

| repo | grant |
|---|---|
| `blackfoot__nextra_documentation_site` | Run `flywheel-loop init --repo /Users/josh/Developer/blackfoot__nextra_documentation_site`; stop after `.flywheel` evidence. |
| `agent-bench` | Run `flywheel-loop init --repo /Users/josh/Developer/agent-bench`; create repo-local `state/` through bootstrap or state init; tenant bootstrap only after registry row proof. |
| `terratitle` | No `.flywheel` work needed; tenant bootstrap only after registry row proof. |
| `zesttube` | Create repo-local `state/` through bootstrap or state init; no tenant rewrite needed unless doctor reports drift. |
| `cubcloud-aaas` | Create repo-local `state/` through bootstrap or state init; tenant bootstrap only after registry row proof. |
| `clutterfreespaces` | Create repo-local `state/` through bootstrap or state init; no tenant rewrite needed unless doctor reports drift. |

## Tenant Bootstrap Gate

Before running `/zs:project-bootstrap <slug> --resync` for `agent-bench`, `terratitle`, or `cubcloud-aaas`, SkillOS must attach:

- canonical registry row path and slug;
- proof it is not a TODO/comment-only row;
- `zs-project-bootstrap` probe result;
- post-bootstrap `zs-tenant-doctor --json --no-journeys <slug>` or equivalent receipt.

`blackfoot__nextra_documentation_site` currently has no row-level `zs-tenant` expectation in the live doctor output. Do not add tenant scope there from this handoff alone.

## Callback Requested

Return one repo-owner callback or closeout receipt with:

- per-repo changed paths;
- per-repo before/after doctor row;
- command receipts for each bootstrap command;
- explicit deferral reason for every registry-gated tenant bootstrap not executed.

— flywheel:1

Mission anchor: `flywheel-watch-cycle-531`
