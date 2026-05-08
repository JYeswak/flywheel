# flywheel-ef8m evidence

Task: ce812ca0
Worker: JadeStone
Status: partial with continuation bead

## DID

1. AG1: ntm version probe confirms PR #117 fields are present.
   - Command: `/Users/josh/.local/bin/ntm version`
   - Result: `v1.14.0-41-ga2529ba3-dirty`, commit `a2529ba34a7fd0d24194145c27786b2b4763f884`, built `2026-05-04T02:30:57Z`.
   - Command: `/Users/josh/.local/bin/ntm --robot-activity=flywheel --activity-type=codex,claude --json`
   - Result: agent rows include `capture_collected_at`, `capture_provenance`, and `capture_error`; current flywheel pane sample showed `capture_provenance=live`.

2. AG2: `/tmp/idle-pane-auto-dispatch.sh` filters only live waiting worker panes.
   - Existing v4 watcher already uses:
     `select(.pane_idx>=2 and .pane_idx<=4 and .state=="WAITING" and .capture_provenance=="live")`.
   - Verification: `bash -n /tmp/idle-pane-auto-dispatch.sh` and `rg 'capture_provenance=="live"|state=="WAITING"' /tmp/idle-pane-auto-dispatch.sh`.

3. AG5: `/flywheel:dispatch` command doc now requires live capture provenance before dispatch.
   - Updated: `/Users/josh/.claude/commands/flywheel/dispatch.md`
   - Gate now checks `.agents[0].capture_provenance == "live"` and routes `capture_provenance="unavailable"` to flywheel-respawn/flywheel-recovery instead of classifying the worker.
   - Dispatch log example now records `capture_provenance`, `capture_collected_at`, and `capture_error`.

4. AG6: Added conformance test for capture provenance fixtures.
   - Added: `/Users/josh/Developer/flywheel/tests/pane-capture-provenance.sh`
   - Fixtures covered: `live-waiting`, `live-error`, `unavailable-with-error`, `unavailable-without-error`.
   - Result: `PASS pane-capture-provenance fixtures=4 repo=/Users/josh/Developer/flywheel`.

5. AG7: Updated Jeff substrate inventory memory with ntm #117 adoption rule.
   - Updated: `/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/reference_jeff_substrate_inventory.md`
   - Added installed version, live field proof, and flywheel rule: dispatch only when `capture_provenance=="live"` and `state=="WAITING"`.

## DIDNT

Continuation bead: `flywheel-255f`

Blocked by active `RoseIsland` reservations for `flywheel-et7t` on shared files:
- `/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop`
- `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md`
- `/Users/josh/Developer/flywheel/AGENTS.md`

Unfinished AGs routed to `flywheel-255f`:
- AG3: `flywheel-loop doctor --json` field `pane_capture_unavailable_count`
- AG4: dispatch-template capture provenance assertion
- AG8: AGENTS.md L-rule `CAPTURE-PROVENANCE-CANONICAL`
- AG9: fleet-wide ft04 propagation after AGENTS.md update

Coordination sent:
- Agent Mail message id 82 to `RoseIsland`, subject `Reservation conflict: flywheel-ef8m capture provenance`.
- No reply was received before this evidence file was written.

## GAPS

None beyond `flywheel-255f`; the unfinished work is a direct continuation of assigned acceptance gates, not newly discovered scope.

## Tests

PASS:
- `bash -n tests/pane-capture-provenance.sh`
- `tests/pane-capture-provenance.sh`
- `bash -n /tmp/idle-pane-auto-dispatch.sh`
- `br dep cycles`

## Three-Q

- VALIDATED: ntm version/robot-activity fields probed; watcher syntax checked; fixture test passed.
- DOCUMENTED: `/flywheel:dispatch` and Jeff substrate inventory updated for live capture provenance.
- SURFACED: unfinished canonical doctor/template/doctrine/propagation work filed as `flywheel-255f` and blocked on `flywheel-et7t`.

## Continuation audit — flywheel-0jsh, 2026-05-08

Close envelope under review: `did=5/9 didnt=flywheel-255f gaps=flywheel-255f`.

Source beads checked:
- Parent: `flywheel-ef8m`.
- Continuation: `flywheel-255f`.
- Blocking dependency: `flywheel-et7t` is still `IN_PROGRESS`, and `flywheel-255f` depends on it.

Missing parent gates remain AG3, AG4, AG8, and AG9:
- AG3 requires `flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json` to expose `pane_capture_unavailable_count` and `pane_capture_state`. Current probe returned both fields absent: `has_pane_capture_unavailable_count=false`, `has_pane_capture_state=false`.
- AG4 requires `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md` to require a `capture_provenance` assertion and dispatch-time `capture_provenance` logging. Current targeted search found no `capture_provenance` contract in that template.
- AG8 requires `AGENTS.md` to add a specific `CAPTURE-PROVENANCE-CANONICAL` L-rule with ntm #117 evidence. Current `AGENTS.md` contains related live-capture doctrine, but not the requested named rule.
- AG9 requires `.flywheel/scripts/sync-canonical-doctrine.sh --apply` propagation after the L-rule lands. Current dry-run reports `status=drift_detected`, `drifted_count=163`, `root_drifted_count=49`, `errors_count=0`; this is not a clean propagation receipt.

Executable probes run for this continuation:

```bash
bash tests/pane-capture-provenance.sh
TMPDIR=/var/folders/d0/09qgt_0n1m1ff8nyzbxppx9c0000gn/T/0jsh.XXXXXX.Cedx18Cm75 \
  ~/.claude/skills/.flywheel/bin/flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json \
  | jq '{has_pane_capture_unavailable_count:has("pane_capture_unavailable_count"), has_pane_capture_state:has("pane_capture_state"), keys:(keys|map(select(test("pane|capture|ntm|worker_identity"))))}'
TMPDIR=/var/folders/d0/09qgt_0n1m1ff8nyzbxppx9c0000gn/T/0jsh.XXXXXX.Cedx18Cm75 \
  .flywheel/scripts/sync-canonical-doctrine.sh --dry-run --json \
  | jq '{status, mode, drifted_count, errors_count, targets_count, root_drifted_count}'
```

Results:
- PASS: `tests/pane-capture-provenance.sh` still covers the four PR #117 fixtures.
- BLOCK: AG3 field contract is absent from current doctor JSON.
- BLOCK: AG4 dispatch-template contract is absent.
- BLOCK: AG8 named L-rule is absent.
- BLOCK: AG9 propagation cannot honestly pass before AG8 lands; dry-run shows drift.

Gate-respecting verdict: `BLOCK_CLOSE_open_dependency_et7t_and_remaining_AG3_AG4_AG8_AG9`. This is intentionally not an `APPROVE_CLOSE`; `flywheel-ef8m` remains `did=5/9` until `flywheel-255f` can close against its dependency chain.

## Four-Lens Self-Grade

Brand lens: PASS. The evidence is receipt-first, specific, and grounded in paths, commands, bead IDs, and validator outcomes. It avoids public-voice slop and does not turn the blocked continuation into a sales claim.

Sniff lens: PASS. Joshua should not have to reconstruct the partial-work state from scrollback: the receipt names `did=5/9`, the continuation bead, the open dependency, the exact missing AGs, and the probes that failed. This gives the operator the next decision without hiding debt.

Jeffrey lens: PASS for evidence quality, BLOCK for implementation close. The receipt follows Jeffrey Emanuel's craft standard by using observable command probes, explicit JSON field checks, fail-closed closeout, and reproducible test commands. It does not claim doctor/dispatch/doctrine gates are done when the doctor field and template contract are absent.

Public lens: PASS for bar clarity, BLOCK for parent publishability until continuation lands. Seven-facet bar:
- F1 README front-door: not changed by this continuation audit.
- F2 Doctrine clarity: BLOCK because the requested named `CAPTURE-PROVENANCE-CANONICAL` rule is absent.
- F3 Doctor/health/repair triad: BLOCK because `pane_capture_unavailable_count` and `pane_capture_state` are absent from doctor JSON.
- F4 Executable tests: PASS for `tests/pane-capture-provenance.sh`; incomplete for the missing doctor fixture check.
- F5 Idempotent install + uninstall: not directly changed; propagation must wait for AG8.
- F6 Code aesthetic: PASS for the existing fixture test surface; no new source code was added here.
- F7 Demo-ability: BLOCK until one doctor command demonstrates the capture-unavailable signal.

Joshua 25-year ops lens: PASS for judgment, BLOCK for close. Finishing partial work is a 25-year operations-management discipline: half-shipped beads accumulate ghost debt, teach teams that `did<total` can be hand-waved, and make turnover brittle because the next operator has to rediscover what was not finished. The company-building leverage is the honest envelope: close at `did=N/N`, or carry an explicit `BLOCK_CLOSE` with the missing gates and dependency named.
