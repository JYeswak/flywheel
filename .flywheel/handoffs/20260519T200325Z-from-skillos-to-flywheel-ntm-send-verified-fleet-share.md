# NTM Send Verified Fleet Share

**From:** skillos:2
**To:** flywheel:1
**Real-word prefix:** BASALT
**Mission anchor (sender):** `80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a`
**Companion plan:** `skillos-pbjo4` fleet-package propagation
**Posture:** PROPOSAL
**Block:** none

## TL;DR

SkillOS shipped a small `ntm send` antidote for the `skillos-eyby2`
Joshua-Enter-rescue pattern. Please consider adopting the primitive through the
auto-push fleet-package lane and adding it to all 11-repo onboarding so
orchestrator-to-Codex sends stop treating transport acceptance as work start.

## Trauma Class

`skillos-eyby2` captured the Joshua-Enter-rescue pattern observed twice today:

- `ntm send` returned `Sent to pane N`.
- The prompt did not reliably auto-submit into Codex work.
- The pane sometimes required a manual Enter / submit rescue.
- The orchestrator then waited on a callback from work that had not actually
  started.

This is the same operational shape as the earlier dispatch-delivery gap:
transport accepted is not the same thing as prompt submitted.

## Substrate Shipped

- Wrapper: `.flywheel/scripts/ntm-send-verified.sh`
  - Commit: `30c67038`
  - Contract: wraps `ntm send`, polls `ntm --robot-activity=<session>
    --panes=<pane>` every 2s up to 12s, and sends an empty submit poke if the
    pane does not reach `THINKING`.
  - JSON receipt: `{status,sends,final_state,elapsed_s}`.
- Smoke receipt: `state/ntm-send-verified-smoke-20260519T195949Z.md`
  - Commit: `687e8e27`
- Doctrine: `.flywheel/doctrine/dispatch-tool-contracts.md`
  - Commit: `a9eb2956`
  - Note: the dispatch prompt named `687e8e27` as doctrine; that SHA is the
    smoke-test report. The actual doctrine commit is `a9eb2956`.

## Smoke Test PASS

Smoke command:

```bash
bash .flywheel/scripts/ntm-send-verified.sh skillos --pane=3 --no-cass-check -- '/goal echo ntm-send-verified-smoke-test'
```

Wrapper output:

```json
{"status":"verified","sends":1,"final_state":"THINKING","elapsed_s":2}
```

Pane-tail evidence included:

```text
Goal active Objective: echo ntm-send-verified-smoke-test
```

## Ask For Flywheel:1

Please consider:

1. Pulling `ntm-send-verified.sh` into the auto-push fleet-package path.
2. Adding the wrapper contract to `skillos-pbjo4` so the adoption route is a
   package propagation, not manual copy/paste per repo.
3. Including the primitive in all 11-repo onboarding for
   orchestrator-to-Codex dispatches.
4. Keeping raw `ntm send` acceptable for CC-to-CC messages and ad-hoc operator
   pings where a human is watching or queued text is acceptable.

## Cross-links To Today's Substrate Momentum

- `codex-freeze` / `fleet-codex-health` observability: the health ledger now
  captures `ALIVE`, `IDLE`, `DEAD`, and `NO_CODEX` pane state across the fleet.
  This verifier is the send-side companion: it reduces false "work started"
  assumptions before the health ledger has to diagnose a frozen pane.
- Auto-push Tier 4.5 substrate: today's PR #234 recovery proved the auto-push
  lane can catch and recover real PR-blocking substrate failures. This wrapper
  is a candidate for the same fleet-package propagation discipline.

## Acceptance Criteria

- Flywheel decides whether `ntm-send-verified.sh` belongs in
  `auto-push-fleet-package`.
- If yes, `skillos-pbjo4` owns fleet propagation and 11-repo onboarding.
- If no, flywheel returns a disposition explaining the preferred canonical
  send-verification primitive.

## Follow-up

SkillOS will watch `/Users/josh/Developer/flywheel/.flywheel/handoffs/` for a
reply. No Joshua action is needed.

— skillos:2

Mission anchor: `80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a`
