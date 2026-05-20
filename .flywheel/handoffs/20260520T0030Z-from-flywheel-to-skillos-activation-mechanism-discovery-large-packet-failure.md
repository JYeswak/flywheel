# Cross-orch row: flywheel:1 -> skillos:1

**ts:** 2026-05-20T00:30Z
**from:** flywheel:1
**to:** skillos:1
**re:** T1+0..24h flywheel work in flight
**subject:** ACTIVATION MECHANISM DISCOVERED + large-packet failure mode — need joint debug
**posture:** REQUEST
**block:** YES (T1+0..24h work blocked until activation reliable for large packets)
**schema_version:** cross_orch_handoff.v1

## TL;DR

Joshua-direct showed the actual /goal activation mechanism. Built a reliable primitive that works for **small** task packets (109-byte canary verified end-to-end: Pursuing goal → Goal achieved). **Fails for large** task packets (7672-byte T1 dispatch: codex cancels the goal). Need skillos:1 input on the canonical packet-size limit + alternative submission patterns for large /goal arguments.

## Mechanism (verified via canary 2026-05-20T00:16Z)

Joshua-quote: *"see how /goal is typed into their pane and is blue - if i type literally anythign after that it will work properly"*

The cause of every prior dispatch failure:
- `ntm send --file packet.txt` ships the WHOLE packet as a single tmux paste block.
- Codex's slash-command palette (`/goal` highlighted in blue) only engages when `/goal` is typed **keystroke-by-keystroke**, not when it arrives in a paste.
- Paste-mode → codex sees `/goal …` as literal chat text, not a slash command.

**Reliable activation sequence** (canary-verified):

| Step | Action | Source |
|---|---|---|
| 1 | `tmux send-keys` keystrokes `/`, `g`, `o`, `a`, `l` (engages codex palette → blue) | NEW primitive |
| 2 | Probe pane via `tmux capture-pane` for `›[[:space:]]+/goal` token to confirm primed | NEW primitive |
| 3 | `tmux load-buffer` task text + `tmux paste-buffer` (now codex treats as /goal argument, not chat) | tmux canonical |
| 4 | `tmux send-keys` Enter | submit |
| 5 | If "Replace current goal" dialog appears (paused/active goal exists) → send Enter to confirm | NEW dialog handler |
| 6 | Probe for `Pursuing goal (Ns)` text within 30s = success | NEW classifier |

## Canonical detection regex updates (informs skillos pane-work-signal v0.2)

| State | OLD (wrong) regex | NEW (canary-verified) regex |
|---|---|---|
| `goal-in-progress` | `Worked for ([0-9]+m [0-9]+s)` | `Pursuing goal \(([0-9]+[ms]\|[0-9]+m [0-9]+s)\)` |
| `goal-completed` | `Goal completed` | `Goal achieved \([0-9]+[ms]?\)` OR `Goal complete\.` |
| `goal-completing` | (was conflated with goal-in-progress) | `Worked for [0-9]+m [0-9]+s` (this is POST-completion, not active) |
| `replace-goal-dialog` | (didn't exist) | `Replace current goal` literal |

**Skillos taxonomy v0.2 spec should adopt these regexes verbatim.** The original guesses in the joint codesign packet were wrong on at least 3 of the 8 states.

## Primitive shipped

`.flywheel/scripts/codex-goal-activate.sh` — flywheel-side, shellcheck PASS, end-to-end canary verified at 14s Goal achieved. Source for skillos canonicalization. Joshua-direct quote and mechanism documented inline.

## Failure mode — large packets

Canary task (109 bytes): SUCCESS → `Goal achieved (14s)`
T1 dispatch (7672 bytes): FAIL → codex shows "■ Conversation interrupted - tell the model what to do differently" then cancels goal.

**Hypotheses:**
1. Codex slash-command argument has a max byte length; T1 exceeds it → silent truncation triggers cancel
2. tmux paste-buffer >N bytes triggers codex's anti-paste-flood guard
3. Multi-line tab/newline content in T1 dispatch interpreted as command-cancel
4. Codex 0.130.0 specific behavior — packet size limit not documented anywhere

## Ask — joint debug

1. **Skillos canary** — run the activation primitive on a skillos codex pane with a packet of size 1KB / 2KB / 4KB / 8KB to find the failure threshold
2. **Probe codex docs** — is there an officially documented `/goal` argument size limit?
3. **Alternative submission pattern** — if /goal argument is size-limited, the canonical pattern becomes:
   - `/goal <short directive: read context file>` (small, fits the limit)
   - Codex first action: read the long packet from a path passed in the short directive
   - This becomes "the directive is the index, the file is the payload" — a substrate-aware pattern
4. **Joint canonicalization** — once threshold is known, both /flywheel:dispatch and skillos canonical-detector lane bake this into the dispatch contract

## What flywheel:1 is NOT doing right now

- Not retrying the large-packet T1 dispatch (will silent-fail again)
- Not modifying activation primitive until skillos:1 inputs on canonical packet-size strategy
- Not propagating activation primitive to other orchs yet (premature without canonical contract)

## What flywheel:1 IS doing

- Drafting a short-directive-plus-payload-file pattern proposal
- Standing by for skillos:1 canary results

## Joshua-direct urgency

"we cannot afford not using /goal - you AHVE to figure out how to get this workihng reliably" + "no goal persuit, no codex".

Both fleets remain effectively codex-stalled until the activation primitive is reliable for production-sized dispatches.

— flywheel:1
