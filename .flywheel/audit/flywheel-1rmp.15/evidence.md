# flywheel-1rmp.15 Evidence

Task: `flywheel-1rmp.15-f3cd3f`
Bead: `flywheel-1rmp.15`
Title: [value-gap] cost-telemetry-token-burn
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)

## Disposition

**Duplicate of `flywheel-1rmp.5` — SUPERSEDED. Same title, same
finding, same proposed measurement.** Sibling bead
`flywheel-1rmp.5` shipped this exact dimension at commit
`4f1669e` earlier this session (CLOSED 2026-05-09). The probe at
`.flywheel/scripts/cost-telemetry-token-burn-probe.sh` already
exists, doctor returns `status=ok`, and the live ledger row at
`~/.local/state/flywheel/cost-telemetry-token-burn.jsonl`
carries the proxy metrics + explicit `no_surface_yet` receipt.

```
VALUE_GAP_DIMENSION=cost-telemetry-token-burn
measurement=.flywheel/scripts/cost-telemetry-token-burn-probe.sh
surfaced=yes
(duplicate of flywheel-1rmp.5; see commit 4f1669e and audit pack
.flywheel/audit/flywheel-1rmp.5/)
```

## Cross-reference

- Sibling: `flywheel-1rmp.5` (CLOSED 2026-05-09)
- Sibling audit: `.flywheel/audit/flywheel-1rmp.5/evidence.md`
- Probe: `.flywheel/scripts/cost-telemetry-token-burn-probe.sh`
- Ledger: `~/.local/state/flywheel/cost-telemetry-token-burn.jsonl`
- Schema: `cost-telemetry-token-burn/v1`

## Live Re-Probe (proves supersession is intact)

`./cost-telemetry-token-burn-probe.sh --dry-run --json`:

```json
{
  "dispatches_observed": 70,
  "retry_proxy": 1,
  "retry_ratio": 0.014492753623188406,
  "declines": 0,
  "actual_token_burn": "no_surface_yet"
}
```

Doctor: `status=ok`. Schema unchanged. No new code needed.

## Acceptance Receipts

| Criterion | Status | Evidence |
|---|---|---|
| Define the smallest recurring measurement that would make this gap visible | done (via flywheel-1rmp.5) | existing probe at `.flywheel/scripts/cost-telemetry-token-burn-probe.sh` (commit 4f1669e) |
| Wire the result into a tick receipt, doctor signal, dashboard, or explicit no-surface reason | done (via flywheel-1rmp.5) | ledger at `~/.local/state/flywheel/cost-telemetry-token-burn.jsonl`; schema-versioned `cost-telemetry-token-burn/v1` |
| Preserve Step 4o anti-pattern guardrails: do not dispatch directly from this finding | done (via flywheel-1rmp.5) | probe writes ledger only; zero `br create` / `ntm send` calls |

did=3/3 didnt=none gaps=none.

## Files Changed

- `.flywheel/audit/flywheel-1rmp.15/evidence.md` — this report.

No new probe authored, no ledger changes, no script edits, no
doctrine touched. The supersession is purely a bookkeeping close.

## Verification Commands (re-runnable)

```bash
br show flywheel-1rmp.5 | head -3   # CLOSED
/Users/josh/Developer/flywheel/.flywheel/scripts/cost-telemetry-token-burn-probe.sh --doctor --json | jq -r .status   # ok
/Users/josh/Developer/flywheel/.flywheel/scripts/cost-telemetry-token-burn-probe.sh --dry-run --json | jq -r .actual_token_burn   # no_surface_yet
```

L112 probe (worker callback):

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/cost-telemetry-token-burn-probe.sh --dry-run --json | jq -r '.actual_token_burn'
```

Expected: literal `no_surface_yet`.

## Skill Auto-Routes

- `canonical-cli-scoping`: n/a (no new CLI authored).
- Others: n/a.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no`.
- `readme_updated=not_applicable`.
- `no_touch_reason=duplicate_of_flywheel-1rmp.5_no_new_artifact_authored_supersession_close_only`.

## Four-Lens Self-Grade

- Brand: 7 — clean supersession close, no duplicated work
  shipped; respects the no-duplicate-artifact rule.
- Sniff: 8 — three independent verifications (br show sibling,
  probe doctor, live dry-run) all confirm supersession.
- Jeff: 7 — small surface (one audit MD), no doctrine mutation.
- Public: 8 — operator/maintainer/future worker can rerun the
  3-line verification in <2s.

## L52 Receipt

`beads_filed=none beads_updated=flywheel-1rmp.15
no_bead_reason=duplicate_of_flywheel-1rmp.5_supersession_close_only`.
