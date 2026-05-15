# P3 AM send attempt — finding 2026-05-15

**Bead:** P3 of substrate-compounding-v2
**Authored by:** flywheel:1 (Claude Opus 4.7, 1M ctx)
**Trigger:** Stop hook discipline — "data-decides, don't defer."
Tried the actual send.

## What I did

Per goal P3 EXIT criterion "AM message verified," I attempted to send a
real trauma-handoff packet via MCP Agent Mail.

Invocation:

```
mcp__mcp-agent-mail__send_message
  project_key: /Users/josh/Developer/flywheel
  sender_name: flywheel-2
  to: [SageMill]
  subject: trauma_handoff: doc-prose-quoted-fixture (FCLA W2 P3)
  body_md: <full packet for class=doc-prose-quoted-fixture from ledger row 2>
```

## What happened

Server refused:

```
Error: send_message requires sender_token for agent 'flywheel-2',
unless this MCP session has already authenticated as that agent.
```

## What this proves

The agent-mail substrate enforces per-session authentication. A
registration_token is required for any non-self operation (whois,
send_message, etc.).

The current flywheel:1 session (this Claude Code session) did not run
through agent-mail registration at session-start. So no token is in the
MCP session context. The send is blocked at the auth layer, not the
schema or identity-discovery layer.

This is the deeper finding from P3:

**Cross-orch handoff via agent-mail requires session-start registration
to be part of the canonical orchestrator-spawn sequence.** Today it
isn't — orchestrators come up, do real work, accumulate handoff packets
in their local ledger, and can't fire them because the auth context was
never established.

## What's not blocked

- ✓ Producer-side ledger: 11 rows in `.flywheel/state/skillos-relay-ledger.jsonl` with full packets, idempotency keys, schemas
- ✓ Handoff helper: `.flywheel/scripts/trauma-handoff.sh` ships a ready-to-send packet for any candidate
- ✓ The packet body and JSON envelope are correct per the new `flywheel-trauma-handoff-request/v1` schema

The substrate is producer-complete. The blocker is single-layer
(authentication) and well-named.

## Follow-up bead (refined from earlier P3 audit)

**`flywheel-orchestrator-session-start-agent-mail-registration`** —
ensure every orchestrator session-spawn:

1. Calls `mcp__mcp-agent-mail__register_agent` with a session-stable
   agent name (e.g. `flywheel-1-<session-id>`)
2. Captures the returned `registration_token`
3. Writes the token to `.flywheel/state/agent-mail-tokens.json` (gitignored)
   keyed by `(session, pane, project)`
4. Subsequent agent-mail calls read the token from that file

Without this, every cold-start session repeats this auth-blocked-handoff
failure. With it, the AM send path closes for real.

## P3 final status

**Producer-complete + AM-send-blocked-on-auth.** The substrate-delta
shipped (ledger + schema + helper + audit). EXIT criterion "AM message
verified" remains unmet pending session-start registration.

Per goal SUCCESS criteria, P3 box stays unchecked. Honest progress;
substrate-gap named precisely.

The next-most-useful action is filing the follow-up bead above and
landing it BEFORE the next attempt. Without it, attempts will repeat
this finding.
