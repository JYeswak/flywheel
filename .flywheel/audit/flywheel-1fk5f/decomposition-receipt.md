# flywheel-1fk5f decomposition receipt

**Tick:** 1fk5f-decompose-v1 (decomposition-only)
**Worker:** CloudyMill (flywheel:0.2)
**Parent bead:** flywheel-1fk5f
**Sister scaffolder:** flywheel-war3i (CLOSED — wave-2 scaffold author)
**Decomposition rule:** decompose-by-natural-unit META-RULE 2026-05-10
**Total fillin scope:** ~144 TODO markers across 8 surfaces; 4-8h aggregate.

## Sub-beads filed

| Sub-bead | Surface | TODOs | Apply-spec | Wall-time est. |
|---|---|---:|---|---:|
| `flywheel-1fk5f.1` | `.flywheel/scripts/dispatch-self-test-delivery-identity.sh` | 18 | `.flywheel/audit/flywheel-1fk5f.1/apply-spec.md` | 30-60 min |
| `flywheel-1fk5f.2` | `.flywheel/scripts/dispatch-surface-conflict-probe.sh` | 18 | `.flywheel/audit/flywheel-1fk5f.2/apply-spec.md` | 30-60 min |
| `flywheel-1fk5f.3` | `.flywheel/scripts/dispatch-trigger-gated-precheck.sh` | 18 | `.flywheel/audit/flywheel-1fk5f.3/apply-spec.md` | 30-60 min |
| `flywheel-1fk5f.4` | `.flywheel/scripts/idle-pane-auto-dispatch.sh` | 18 | `.flywheel/audit/flywheel-1fk5f.4/apply-spec.md` | 30-60 min |
| `flywheel-1fk5f.5` | `.flywheel/scripts/ntm-approve-human-gates.sh` | 18 | `.flywheel/audit/flywheel-1fk5f.5/apply-spec.md` | 30-60 min |
| `flywheel-1fk5f.6` | `.flywheel/scripts/ntm-coordinator-shadow.sh` | 18 | `.flywheel/audit/flywheel-1fk5f.6/apply-spec.md` | 30-60 min |
| `flywheel-1fk5f.7` | `.flywheel/scripts/ntm-fleet-health.sh` | 18 | `.flywheel/audit/flywheel-1fk5f.7/apply-spec.md` | 30-60 min |
| `flywheel-1fk5f.8` | `.flywheel/scripts/ntm-pane-sidecar-respawn.sh` | 18 | `.flywheel/audit/flywheel-1fk5f.8/apply-spec.md` | 30-60 min |

**Aggregate:**
- Sub-beads filed: 8
- TODO markers covered: 144 (18 × 8)
- Wall-time estimate: 4-8h (lower bound 30 min × 8 = 4h; upper 60 min × 8 = 8h)

## Sub-bead ID list (machine-parsable)

```
flywheel-1fk5f.1,flywheel-1fk5f.2,flywheel-1fk5f.3,flywheel-1fk5f.4,flywheel-1fk5f.5,flywheel-1fk5f.6,flywheel-1fk5f.7,flywheel-1fk5f.8
```

## Parent-child verification

Each sub-bead carries `parent-child` dep on `flywheel-1fk5f`. Verified via:

```
$ ~/.cargo/bin/br dep tree flywheel-1fk5f.1
flywheel-1fk5f.1: [doctor-mode-lane-1.2-fillin] dispatch-self-test-delivery-identity TODO fill-in [P2] [open]
  ├── flywheel-1fk5f: [doctor-mode-lane-1.2-fillin] dispatch wave 2 TODO fill-in [P2] [open]
```

Same shape on .2 through .8.

## Decomposition mechanics

- **`br create --parent flywheel-1fk5f --silent`** for each surface
  → bead IDs assigned as flywheel-1fk5f.1 through flywheel-1fk5f.8
  (br's parent-child auto-numbering; expected shape).
- The dispatch's literal `--depends-on` flag does not exist in br;
  `--parent` is the canonical decomposition flag (creates parent-child
  edge with bidirectional visibility via `br dep tree` from child).
- **No code changes** in this tick — decomposition-only. Surface
  implementation lands in subsequent 8-pane-parallel dispatch.

## Per-surface fillin shape (referenced in every apply-spec)

Each apply-spec embeds the same 11-step fillin shape derived from
sister fillins (vc3zs, mae86, 4pwc5, dulh3, gl7om, 39vhm, dsrq1):

1. Module-scope var lift (audit log path, etc.)
2. `scaffold_emit_schema` per-surface schemas
3. Single-printf `scaffold_emit_topic_help` (SIGPIPE/pipefail discipline)
4. `scaffold_cmd_doctor` ≥5 named probes
5. `scaffold_cmd_health` audit-log tail + canonical status
6. `scaffold_cmd_repair --scope ...` dry-run/apply with --idempotency-key
7. `scaffold_cmd_validate <subject>` per-row schema check
8. `scaffold_cmd_audit` via `cli_emit_audit_tail` (path-then-schema)
9. `scaffold_cmd_why <id>` found|not_found|unavailable
10. cmd_run wired to `cli_audit_append` at terminal envelopes
11. Test scaffold extended 15 → ≥19 with fillin assertions

## Three doctrine gotchas embedded in every apply-spec

Caught during sister fillins; preserved as cross-refs so each parallel
worker hits the lessons before the bug:

1. **SIGPIPE/pipefail multi-printf trap** (gl7om) — multi-printf
   topic_help bodies trip SIGPIPE under `pipefail` when consumers pipe
   through `grep -q`. Use single printf per topic.
2. **`local var1 var2=""` only initializes var2** (dsrq1) — under
   `set -u`, `var1` is declared-but-unset, raising "unbound variable"
   on any `[[ -z "$var1" ]]` check. Use `local var1="" var2=""`.
3. **`cli_emit_audit_tail` positional order** (xmafr/dsrq1) — helper
   signature is `cli_emit_audit_tail <path> <schema> [<limit>]`; do
   not swap path and schema.

## Edge-case log (none)

No surface in the 8 resists the 18-TODO shape. All 8 have
canonical-cli scaffold blocks and cmd_run sections suited to the same
fillin pattern. No L61 doctrine gaps surfaced.

## Next dispatch wave

8-pane-parallel implementation. Each pane gets one
`/tmp/dispatch_flywheel-1fk5f.<n>-<task>.md` packet citing this
receipt + the per-bead apply-spec. Expected wave wall-time: ~30-60
min per pane in parallel = ~30-60 min wall, not 4-8h serial.

## Constraints honored

- ✅ Did NOT implement any surface
- ✅ Did NOT close flywheel-1fk5f (parent stays OPEN)
- ✅ Each sub-bead declares parent-child relationship to flywheel-1fk5f
- ✅ Decomposition follows decompose-by-natural-unit META-RULE: 1 bead
  per surface, no bundling
