---
title: "flywheel-ac4fy BLOCKED disposition evidence"
type: evidence
created: 2026-05-10
bead: flywheel-ac4fy
disposition: blocked
---

# flywheel-ac4fy BLOCKED — dependency not yet closed

Bead: `flywheel-ac4fy` ("[doctor-mode-lane-3] agent-mail lane — 10 P0 surfaces")
Worker: CloudyMill
Disposition: **BLOCKED** (canonical `dependency_not_yet_closed` class)
Dispatched: 2026-05-10T15:50Z
Disposition: 2026-05-10T15:57Z

## Primary blocker

The bead body explicitly states:

> Blocked by jloib.1.3 close.

`jloib.1.3` (alias `flywheel-6k36c`) is **IN_PROGRESS**, not closed:

```bash
$ br show flywheel-6k36c | head -3
◐ flywheel-6k36c · [doctor-mode-lane-1.3] dispatch lane wave 3 (tail) — 8 P0 surfaces ...   [● P1 · IN_PROGRESS]
Owner: josh · Type: feature
Created: 2026-05-10 · Updated: 2026-05-10
```

Per the canonical `trigger-gated-bead-BLOCKED-disposition-class`
(filed in flywheel-g6xaw evidence): when a bead's first acceptance gate
is an external precondition the worker cannot cause, the disposition is
BLOCKED with a concrete unblock condition. Premise unmet ≠ DECLINED
(scope is fine), ≠ DONE (work hasn't shipped), ≠ silent absorb (L52).

`blocker_type=flywheel_class`
`blocker_class=dependency_not_yet_closed`
`unblock_condition=br close flywheel-6k36c (jloib.1.3 dispatch lane wave 3 tail)`

## Secondary finding (filed as flywheel-xvzve)

The bead body claims "10 P0 surfaces" but the inventory at
`.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` shows **4 P0
agent-mail surfaces**:

| Script | Priority | canonical_cli_scoping_status |
|---|---|---|
| agent-mail-pre-allocate-worker-identities.sh | P0 | partial |
| agent-mail-restart.sh | P0 | partial |
| agent-mail-send-redacted.sh | P0 | partial |
| agentmail-identity-canonical-validator.sh | P0 | partial |

The other 4 agent-mail surfaces in inventory are P1/P2:
- `agent-mail-fd-doctor.sh` (P1, passing)
- `agent-mail-fd-pressure-check.sh` (P2, partial)
- `agentmail-fd-pressure-probe.sh` (P1, passing)
- `agentmail-registration-broadcast.sh` (P2, missing)

The 6 missing P0 surfaces (claimed 10 − 4 inventory) may live in
sibling paths (`tests/`, `hooks/`, `.flywheel/agent-mail/`) the
inventory probe did not enumerate, OR the bead body's "10 P0" was an
estimate that didn't reconcile against inventory before dispatch.

`flywheel-xvzve` (P3 bug) filed as the inventory-reconciliation
follow-up. AG1: re-probe with broader path set. AG2: update bead body
to actual P0 count. AG3: write apply-spec listing the 10 specific
surfaces (cf. jloib.2.1 has an apply-spec; lane-3 does not).

## Apply-spec missing

`.flywheel/audit/flywheel-doctor-mode-lane-3/` does NOT exist. By
contrast, `.flywheel/audit/flywheel-jloib.2.1/apply-spec.md` exists for
the recovery lane wave 1 and lists 8 specific surfaces. The lane-3
spec author should write a parallel apply-spec naming the 10 specific
agent-mail P0 surfaces before re-dispatch.

## Verbatim probes (re-runnable)

```bash
# Confirm dependency not closed:
br show flywheel-6k36c | head -1
# => ◐ flywheel-6k36c · [...]   [● P1 · IN_PROGRESS]

# Confirm 4 P0 agent-mail surfaces in inventory:
jq -c 'select((.name // "") | test("^(agent-mail|agentmail)"; "i"))
       | select(.priority == "P0") | .name' \
  .flywheel/audit/flywheel-cli-inventory/inventory.jsonl | wc -l
# => 4

# Confirm apply-spec absent:
ls .flywheel/audit/flywheel-doctor-mode-lane-3/ 2>&1
# => No such file or directory
```

## Disposition

```
blocker_type=flywheel_class
blocker_class=dependency_not_yet_closed
need=br_close_flywheel-6k36c_AND_apply-spec_for_lane-3_AND_inventory_reconciliation
filed_followup=flywheel-xvzve
```

## Cross-references

- `flywheel-6k36c` (jloib.1.3 dispatch lane wave 3 tail) — IN_PROGRESS
- `flywheel-xvzve` (inventory reconciliation follow-up, this dispatch) — OPEN P3
- `.flywheel/audit/flywheel-jloib.2.1/apply-spec.md` — exemplar lane spec
- `.flywheel/doctrine/trigger-gated-bead-precheck.md` — canonical
  pre-check pattern (this case is similar shape: dispatch-time premise
  unmet → BLOCKED).

## Four-Lens Self-Grade

- brand: 9/10 — disposition follows the canonical trigger-gated-BLOCKED
  pattern shipped today
- sniff: 10/10 — every claim probed mechanically (br show, inventory jq,
  ls)
- jeff: 10/10 — data decides; both the dep-not-closed AND inventory
  mismatch surfaces are mechanically observed
- public: 9/10 — operator can re-run the 3 probes in 5s and reproduce
  every claim

four_lens=brand:9,sniff:10,jeff:10,public:9
