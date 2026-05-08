# flywheel-y8iky Agent-Mail Orphan Sweep Receipt

schema_version: flywheel-y8iky-agent-mail-orphan-sweep/v1
source: alps_loop_20260508T012545Z
bead: flywheel-y8iky
executed_at: 2026-05-08T01:40:37Z

## Probe

- Agent Mail liveness: `{"status":"alive"}` from `/health/liveness`.
- Identity doctor pre-sweep: 20 registered rows, 16 topology-derived orphan session rows, 1 orphan token, 1 unswept token.
- Token-safety: token bodies were never read, printed, copied, or written to this receipt. Only file metadata and token filenames were inspected.

## Session Classification

The 16 ALPS-reported session rows were present in the identity doctor output, but live NTM robot-activity proved they are reachable. They were not archived.

| session | panes flagged | live probe | classification | action |
|---|---:|---|---|---|
| alpsinsurance | 1,2,3,4 | reachable via `ntm --robot-activity=alpsinsurance` | false-positive topology drift | retained |
| flywheel | 1,2,3,4 | reachable via `ntm --robot-activity=flywheel` | false-positive topology drift | retained |
| mobile-eats | 1,2 | reachable via `ntm --robot-activity=mobile-eats` | false-positive topology drift | retained |
| skillos | 1,2 | reachable via `ntm --robot-activity=skillos` | false-positive topology drift | retained |
| vrtx | 1,2,3,4 | reachable via `ntm --robot-activity=vrtx` | false-positive topology drift | retained |

Root cause of the session-row signal: latest `session-topology.jsonl` rows for these sessions have null `orchestrator_pane` and `worker_panes`, while live NTM still sees the panes. Treating the registry rows as orphaned would delete active identity state.

## Token Sweep

Decision: archive, not hard-delete. Joshua-lens read: orphan accumulation is operator hygiene debt, but the safe ops default is reversible archive with hard-delete only after a retention window.

- Pre-sweep orphan token count: 1.
- Sweep command: `flywheel-loop identity --sweep-orphan-tokens --json`.
- Archived token file: `FoggyForest.token` moved under `agent-mail/tokens/.swept/`.
- Post-sweep orphan token count: 0.
- Post-sweep unswept token count: 0.

Hard-delete policy: defer permanent deletion for at least 30 days after archive unless Joshua explicitly approves earlier purge.

## Post-Sweep Counts

| metric | pre | post |
|---|---:|---:|
| raw identity-doctor orphan session rows | 16 | 16 |
| confirmed unreachable session rows after live validation | 0 | 0 |
| orphan tokens | 1 | 0 |
| unswept tokens | 1 | 0 |

## ALPS Cross-Ref

ALPS source tick `alps_loop_20260508T012545Z` correctly surfaced the registry hygiene signal. The action taken was token archive plus session-row non-mutation because live data contradicted topology-derived orphan status.
