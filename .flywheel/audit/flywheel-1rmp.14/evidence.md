# flywheel-1rmp.14 Evidence

Task: `flywheel-1rmp.14-d459c2`
Bead: `flywheel-1rmp.14`
Title: [value-gap] customer-facing-observability
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)

Parent: `flywheel-1rmp` (in_progress) — Step 4o value-gap-hunter
paradigm-tier scan; dimension #3 of 10 in
`.flywheel/scripts/value-gap-probe.sh:DIMENSIONS[]`. Sisters
(same shape, all closed): `flywheel-1rmp.5`, `flywheel-1rmp.7`,
`flywheel-1rmp.9`, `flywheel-1rmp.11`.

## Disposition

**`VALUE_GAP_DIMENSION=customer-facing-observability
measurement=.flywheel/scripts/customer-facing-observability-probe.sh
surfaced=yes`**

The smallest recurring measurement is now wired: a bounded probe
inventories presence + report-freshness across the canonical
client/product set (alpsinsurance, blackfoot, terratitle, plus
active product surfaces zesttube + mobile-eats) and emits proxy
metrics + `customer_observability_state=no_aggregation_pipeline_yet`
receipt. Schema-versioned ledger at
`~/.local/state/flywheel/customer-facing-observability.jsonl`.

Step 4o anti-pattern guardrails preserved.

## Live Probe Receipt

| repo | repo_present | reports_dir_present | report_status |
|---|---|---|---|
| alpsinsurance (client) | yes | no | missing |
| blackfoot (client) | **no** | n/a | missing |
| terratitle (client) | yes | no | missing |
| zesttube (product) | yes | no | missing |
| mobile-eats (product) | yes | yes | **stale** (mtime 2026-05-04) |

Aggregate:
- `repos_total=5` (3 clients + 2 products)
- `repos_present_count=4` (blackfoot missing — known
  dangling-symlink condition per memory
  `feedback_orch_paralysis_when_data_specifies_action`)
- `reports_dir_present_count=1` (only mobile-eats)
- `fresh_report_count=0` (mobile-eats is 5 days stale beyond
  the 72h budget)
- `stale_report_count=1`
- `missing_report_count=4`
- `coverage_ratio=0.0`

This is a real actionable signal: the customer-facing-observability
gap is wide open. Today, exactly zero clients/products surface a
fresh customer-visible value+risk receipt to the flywheel.

## Acceptance Receipts

| Criterion | Status | Evidence |
|---|---|---|
| Define the smallest recurring measurement that would make this gap visible | done | `.flywheel/scripts/customer-facing-observability-probe.sh` (~280 lines, canonical-cli-scoping triad). Proxy metrics enumerated above. |
| Wire the result into a tick receipt, doctor signal, dashboard, or explicit no-surface reason | done | Schema-versioned ledger; `customer_observability_state=no_aggregation_pipeline_yet` with concrete `no_aggregation_reason` documenting the missing producer-side aggregation. |
| Preserve Step 4o anti-pattern guardrails | done | Probe writes ledger only. NO `br create`, no `ntm send`, no auto-aggregation. Verified by reading the script: zero invocations of any dispatch surface. |

did=3/3 didnt=none gaps=none.

## Files Changed

- `.flywheel/scripts/customer-facing-observability-probe.sh`
- `.flywheel/audit/flywheel-1rmp.14/evidence.md`
- `.flywheel/audit/flywheel-1rmp.14/probe-apply-output.json`
- `.flywheel/audit/flywheel-1rmp.14/ledger-snapshot.jsonl`

Out-of-repo: `~/.local/state/flywheel/customer-facing-observability.jsonl`.

No edits to `value-gap-probe.sh` (parent), AGENTS.md, INCIDENTS,
or any skill.

## Verification Commands

```bash
bash -n /Users/josh/Developer/flywheel/.flywheel/scripts/customer-facing-observability-probe.sh
/Users/josh/Developer/flywheel/.flywheel/scripts/customer-facing-observability-probe.sh --doctor --json | jq -r .status
/Users/josh/Developer/flywheel/.flywheel/scripts/customer-facing-observability-probe.sh --dry-run --json | jq '{repos_present_count, fresh_report_count, customer_observability_state}'
```

L112 probe (worker callback):

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/customer-facing-observability-probe.sh --dry-run --json | jq -r '.customer_observability_state'
```

Expected: literal `no_aggregation_pipeline_yet`.

## Boundary

- Probe is read-only. No source mutation outside its ledger.
- Building a per-client customer-receipt aggregator is OUT OF
  SCOPE (separate value-gap-followup bead under parent flywheel-1rmp).
- `blackfoot` repo absence is a known issue (dangling symlink);
  not this bead's scope to repair.

## Skill Auto-Routes

- `canonical-cli-scoping`: yes — triad, `--json` default-on,
  mutation discipline, stable exit codes.
- Others: n/a.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no`.
- `readme_updated=not_applicable`.
- `no_touch_reason=operational_probe_not_doctrine`.

## Four-Lens Self-Grade

- Brand: 8 — closes the 5th value-gap-hunter dimension this
  session with the same template; complete sister set now ships.
- Sniff: 9 — five repos probed, per-repo evidence with byte-level
  presence/freshness, aggregate ratios + per-row JSON.
- Jeff: 8 — small surface, no doctrine mutation, no upstream patch.
- Public: 9 — operator/maintainer/future worker can rerun in <2s
  and reach the same disposition.

## L52 Receipt

`beads_filed=none beads_updated=flywheel-1rmp.14 no_bead_reason=none`.
