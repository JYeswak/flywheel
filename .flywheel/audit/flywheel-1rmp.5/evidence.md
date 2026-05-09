# flywheel-1rmp.5 Evidence

Task: `flywheel-1rmp.5-f13060`
Bead: `flywheel-1rmp.5`
Title: [value-gap] cost-telemetry-token-burn
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)

Parent: `flywheel-1rmp` (in_progress) — Step 4o value-gap-hunter
paradigm-tier scan; dimension #4 of 10 in
`.flywheel/scripts/value-gap-probe.sh` `DIMENSIONS[]`.

## Disposition

**`VALUE_GAP_DIMENSION=cost-telemetry-token-burn
measurement=.flywheel/scripts/cost-telemetry-token-burn-probe.sh
surfaced=yes`**

The smallest recurring measurement is now wired: a bounded probe
reads `.flywheel/dispatch-log.jsonl` over a configurable window
(default 24h) and emits proxy metrics + an explicit
`actual_token_burn=no_surface_yet` receipt explaining why direct
first-party Anthropic/xAI/OpenAI token telemetry is not surfaced
through flywheel substrate today. The ledger row schema (versioned
`cost-telemetry-token-burn/v1`) is consumable by any tick receipt,
doctor signal, or dashboard that wants to read it.

Step 4o anti-pattern guardrails preserved: this probe SURFACES the
gap; it does NOT auto-create beads or dispatch fixes. Any
follow-up beads (e.g. wire first-party billing API) go through
Joshua's hand via the parent `value-gap-probe.sh` flow with
`--apply --dimension cost-telemetry-token-burn`.

## Acceptance Receipts

| Criterion | Status | Evidence |
|---|---|---|
| Define the smallest recurring measurement that would make this gap visible | done | `.flywheel/scripts/cost-telemetry-token-burn-probe.sh` (~270 lines, canonical-cli-scoping triad: doctor / info / schema / help with `--json` default-on, `--apply / --dry-run` modes, stable exit codes 0/1/64). Proxy metrics computed from dispatch-log.jsonl: `dispatches_observed`, `unique_task_sha256`, `retry_proxy`, `retry_ratio`, `declines`, `by_event / by_agent_type / by_dispatch_status / by_wave / by_pane`. |
| Wire the result into a tick receipt, doctor signal, dashboard, or explicit no-surface reason | done | Schema-versioned ledger at `~/.local/state/flywheel/cost-telemetry-token-burn.jsonl` (`cost-telemetry-token-burn/v1`) — one row per `--apply` run; first row written this turn (`probe-apply-output.json`). Plus `actual_token_burn=no_surface_yet` with `actual_token_burn_no_surface_reason=Anthropic / xAI / OpenAI billing API is not wired into flywheel substrate; smallest recurring measurement is proxy-only against dispatch-log.jsonl until a first-party telemetry surface is filed as a separate value-gap follow-up bead.` |
| Preserve Step 4o anti-pattern guardrails: do not dispatch directly from this finding | done | Probe writes ledger and emits stdout JSON. NO `br create`, no `ntm send`, no auto-bead. Confirmed by reading the script: zero invocations of `br`, `ntm`, or any dispatch surface. The parent `value-gap-probe.sh` retains its own `--dry-run` default + `--apply` opt-in for any bead-filing decision Joshua approves. |

did=3/3 didnt=none gaps=none.

## Live Receipt (this turn)

`apply` run captured at `probe-apply-output.json` and copied to
`ledger-snapshot.jsonl`:

```json
{
  "schema_version": "cost-telemetry-token-burn/v1",
  "ts": "2026-05-09T13:59:18Z",
  "window_start": "2026-05-08T13:58:57Z",
  "window_end": "2026-05-09T13:58:57Z",
  "hours_back": 24,
  "dispatches_observed": 70,
  "unique_task_sha256": 69,
  "retry_proxy": 1,
  "retry_ratio": 0.014492753623188406,
  "declines": 0,
  "by_event": {"dispatch_sent": 69, "observation": 1},
  "by_agent_type": {"codex": 69, "unknown": 1},
  "by_dispatch_status": {"queued_for_send": 69, "unknown": 1},
  "by_wave": {"4":3,"5":3,"6":3,"7":4,"8":5,"9":4,"10":5,"11":5,"12":6,"13":9,"14":5,"15":5,"16":2,"unknown":11},
  "by_pane": {"...": "..."},
  "actual_token_burn": "no_surface_yet",
  "actual_token_burn_no_surface_reason": "Anthropic / xAI / OpenAI billing API is not wired into flywheel substrate; smallest recurring measurement is proxy-only against dispatch-log.jsonl until a first-party telemetry surface is filed as a separate value-gap follow-up bead."
}
```

Live observations from the 24h window:
- 70 dispatches across 16 waves
- retry_proxy=1 (only one repeated `task_sha256` — implying low
  worker-reentry rate, healthy by proxy)
- declines=0 (no DECLINED dispositions in the window)
- by_agent_type indicates codex labels even though the actual fleet
  is currently all-claude (per flywheel-orx1 finding) — this is
  metadata-vs-runtime drift, NOT a token-burn anomaly

## Files Changed

In-repo:
- `.flywheel/scripts/cost-telemetry-token-burn-probe.sh` — new
  bounded probe with canonical-cli-scoping triad.
- `.flywheel/audit/flywheel-1rmp.5/evidence.md` — this report.
- `.flywheel/audit/flywheel-1rmp.5/probe-apply-output.json` —
  apply-mode JSON envelope from this turn.
- `.flywheel/audit/flywheel-1rmp.5/ledger-snapshot.jsonl` — copy of
  the first ledger row.

Out-of-repo:
- `~/.local/state/flywheel/cost-telemetry-token-burn.jsonl` — new
  ledger; one row written this turn (will accumulate one row per
  `--apply` invocation; intended cadence: per-tick consumer or
  cron-equivalent at parent's discretion).

No edits to `value-gap-probe.sh` (parent), AGENTS.md, INCIDENTS,
canonical L-rules, or any skill. The new probe is purely additive
and conforms to the existing dimension-#4 contract in
`value-gap-probe.sh:DIMENSIONS[3]`.

## Verification Commands (re-runnable)

```bash
bash -n /Users/josh/Developer/flywheel/.flywheel/scripts/cost-telemetry-token-burn-probe.sh

# Triad
/Users/josh/Developer/flywheel/.flywheel/scripts/cost-telemetry-token-burn-probe.sh --doctor --json | jq -r .status
/Users/josh/Developer/flywheel/.flywheel/scripts/cost-telemetry-token-burn-probe.sh --info --json | jq -r .owns
/Users/josh/Developer/flywheel/.flywheel/scripts/cost-telemetry-token-burn-probe.sh --schema --json | jq -r '.ledger_row_required_fields | length'

# Live measurement (no write)
/Users/josh/Developer/flywheel/.flywheel/scripts/cost-telemetry-token-burn-probe.sh --dry-run --json | jq '{dispatches_observed, retry_ratio, declines, actual_token_burn}'

# Parent dimension routing still intact
/Users/josh/Developer/flywheel/.flywheel/scripts/value-gap-probe.sh --dimension cost-telemetry-token-burn --json --dry-run | jq -r .value_gap_dimension_scanned
```

L112 probe (worker callback):

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/cost-telemetry-token-burn-probe.sh --dry-run --json | jq -r '.actual_token_burn'
```

Expected: literal `no_surface_yet`.

## Boundary

- The probe is read-only against `dispatch-log.jsonl` and append-only
  on `~/.local/state/flywheel/cost-telemetry-token-burn.jsonl`. No
  source mutation outside its own ledger.
- First-party token telemetry (real Anthropic/xAI/OpenAI billing
  API) is OUT OF SCOPE for this bead; the explicit no-surface
  reason in the schema documents the gap so a future
  value-gap-follow-up bead can wire it without re-deriving the
  context.
- `value-gap-probe.sh` (parent) is unchanged; the probe is
  consumable by it via `--dimension cost-telemetry-token-burn`.

## Skill Auto-Routes

- `canonical-cli-scoping`: yes — script ships `doctor / info /
  schema / help` triad, `--json` default-on for robot consumers,
  `--apply / --dry-run` mutation discipline, stable exit codes
  (0/1/64), ~270 lines (under threshold).
- `rust-best-practices`: n/a — no Rust.
- `python-best-practices`: n/a — only inline `python3` snippets in
  test summarization.
- `readme-writing`: n/a — no README.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — no L-rule promotion this turn; the probe
  is operational and the no-surface reason is captured in the
  schema, not in canonical doctrine.
- `readme_updated=not_applicable` — no top-level README.
- `no_touch_reason=operational_probe_not_doctrine_no_l_rule_or_skill_promotion`.

## Four-Lens Self-Grade

- Brand: 8 — closes a P3 paradigm-tier gap with a measurable proxy
  AND an explicit no-surface receipt that hands off the
  first-party telemetry asks to a future bead. Future workers can
  read the schema and find the seam without re-deriving context.
- Sniff: 9 — three independent verifications (triad, dry-run live
  metrics, parent value-gap-probe routing intact); ledger row
  shown verbatim with actual numbers (70 dispatches in last 24h,
  retry_ratio=1.4%, declines=0).
- Jeff: 8 — small surface area (one new shell probe, no doctrine
  mutation, no upstream patch); honors the canonical-cli-scoping
  triad with stable exit codes and `--json` discipline.
- Public: 9 — operator/maintainer/future worker can rerun the
  verification block in <2s and reach the same disposition. Three
  Judges check passes: operator (sees concrete proxy numbers),
  maintainer (sees the explicit no-surface reason in the schema),
  future worker (sees the parent dimension contract preserved at
  `value-gap-probe.sh:DIMENSIONS[3]`).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-1rmp.5 no_bead_reason=none`.
