# ntm controller-pane topology-aware wording proposal

**Filed under:** flywheel-se3h.8 (local-only — no upstream push without explicit Joshua approval)
**Boundary:** This is a DRAFT. It is not posted to upstream `Dicklesworthstone/ntm`.
**Proposed for:** ntm v1.14.x doc/help surfaces that hardcode "pane 1" as the controller.

## Surfaces that need topology-aware wording

Per the search receipt at `evidence/flywheel-se3h.8/ntm-controller-pane-grep.txt`, three live surfaces hardcode "controller pane is pane 1":

| File | Line | Current text |
|---|---|---|
| `internal/cli/get_all_session_text.go` | 28 | `- Controller pane (pane 1) last message and status` |
| `internal/cli/controller.go` | 81 | `Description: "Launch a dedicated controller agent in pane 1"` |
| `internal/cli/controller.go` | 139-140 | `Short: "Launch a dedicated controller agent in pane 1"`; `Long: "Launch a controller agent in pane 1 of an existing session...`"` |

Two test/comment surfaces also reference the hardcoded assumption (lower priority):
- `internal/cli/controller_test.go:19,37,153,334,355`
- `internal/cli/controller.go:299` (`// Find or create pane 1`)

## Counterexamples from current fleet topology

Per `evidence/flywheel-se3h.8/topology-counterexamples.jsonl` (44 rows):

1. **alpsinsurance (2026-05-01T14:21Z)** — `orchestrator_pane=0 callback_pane=0`. Pane 0, NOT pane 1.
2. **mobile-eats (2026-05-02T12:04Z)** — `orchestrator_pane=2 callback_pane=2`. Pane 2, NOT pane 1.

Both confirm the "controller pane is pane 1" assumption breaks for fleets that started a non-default pane allocation. The current fleet (flywheel + skillos + vrtx) does happen to use pane 1, but the topology layer is explicitly session-specific (`session-topology.jsonl` row carries `orchestrator_pane` per session).

## Proposed wording

### `internal/cli/get_all_session_text.go:28`

**Current:** `- Controller pane (pane 1) last message and status`

**Proposed:** `- Controller pane (per session topology; default pane 1) last message and status`

Or, if a topology resolver is available: `- Controller pane (topology[session].orchestrator_pane) last message and status`.

### `internal/cli/controller.go:81`

**Current:** `Description: "Launch a dedicated controller agent in pane 1"`

**Proposed:** `Description: "Launch a dedicated controller agent in the session's controller pane (default pane 1; override via --pane=N)"`

### `internal/cli/controller.go:139-140`

**Current:**
```go
Short: "Launch a dedicated controller agent in pane 1",
Long: `Launch a controller agent in pane 1 of an existing session.
```

**Proposed:**
```go
Short: "Launch a dedicated controller agent in the session's controller pane",
Long: `Launch a controller agent in the session's controller pane (default pane 1; override via --pane=N) of an existing session.

The controller pane defaults to pane 1 because that is the convention for new
sessions, but for sessions whose topology was registered with a different
controller pane (e.g. alpsinsurance pane 0, mobile-eats pane 2), pass --pane=N
to target the correct pane. The wrapper layer (e.g. flywheel session-topology.jsonl)
is the source of truth for which pane is the controller.
```

## Why this is a wording change, not a behavior change

The current `controller.go` flow at `internal/cli/controller.go:299` already does `Find or create pane 1`. That logic is **fine** — it correctly defaults to pane 1 when the session doesn't already have one. The issue is purely user-facing prose that asserts the assumption is invariant. Documentation should describe the default + override mechanism rather than mandate the default.

For sessions like alpsinsurance and mobile-eats where the controller pane is NOT pane 1, the user still passes `--pane=N` to the relevant ntm subcommand. The ntm binary's behavior already handles this correctly. Only the doc strings need updating.

## Disposition

- **No upstream push** without explicit Joshua approval (per acceptance gate 5).
- **No local ntm binary patch** (per Out of Scope).
- **Draft staged here** for future Jeffrey-issue dispatch when Joshua approves contact.

## `no_upstream_push_reason`

`bead-out-of-scope-without-joshua-approval` — bead acceptance gate 5 explicitly says: *"No upstream push occurs without explicit Joshua approval."* And the bead's "Out Of Scope" lists "No upstream push" first. The `Rollback / Dry-Run Posture` line says: *"Draft-only until Joshua approves upstream contact or local patch."*

When Joshua approves, follow `jeff-issue-chain` skill v1.3 Phase 1 contract:

1. File issue at `Dicklesworthstone/ntm` with body lifted from this proposal — anonymized to remove flywheel/zeststream/josh paths and bead IDs.
2. Cite source-trace: `internal/cli/get_all_session_text.go:28`, `internal/cli/controller.go:81,139-140`.
3. Cite counterexamples: alpsinsurance pane 0, mobile-eats pane 2.
4. Frame as wording-only proposal; behavior already correct.
