# flywheel-4o9o1 ALPS Agent Mail Orphan Regression Diagnosis

schema_version: flywheel-4o9o1-agentmail-orphan-diagnosis/v1
bead: flywheel-4o9o1
executed_at: 2026-05-08T02:05:00Z
source: ALPS T3 tick 2026-05-08T01:53Z

## Summary

Diagnosis: `surface_mismatch`, with a structural topology-scoping root cause.

ALPS did not prove that y8iky's token archive failed. The y8iky receipt says the
16 session rows were retained because live NTM activity proved the sessions were
reachable. Its post-sweep `0` was the validated-unreachable session count, not
the raw `agentmail_orphan_session_rows_count` field. ALPS kept reporting the raw
topology-derived field, so it stayed 16 by design.

This is operator-trust corrosion: a metric named like an orphan count kept
reporting active live sessions as orphaned after the safe sweep. A 25-year ops
read is that the fleet needs one labeled source of truth: raw topology drift is
not the same thing as confirmed unreachable identity state.

## Source Receipts

- y8iky: `.flywheel/receipts/flywheel-y8iky-receipt.md`
  - Raw identity-doctor orphan session rows: `16 -> 16`.
  - Confirmed unreachable session rows after live validation: `0 -> 0`.
  - Orphan tokens: `1 -> 0`.
- s69zu: `.flywheel/receipts/flywheel-s69zu-receipt.md`
  - Same-day scope/visibility failure family: ALPS saw flywheel-owned rows in
    an ALPS substrate and classified 64 rows as basename-keying / repo-scope
    bleed.

## ALPS-Side Probe Surface

ALPS tick consumes the shared flywheel-loop doctor surface:

```text
~/.claude/skills/.flywheel/bin/flywheel-loop doctor --repo /Users/josh/Developer/alpsinsurance --json
```

The relevant field is copied from the identity registry doctor:

```text
/Users/josh/.claude/skills/.flywheel/lib/portable/core.sh:927 identity_registry="$(agent_mail_identity_registry_doctor_json)"
/Users/josh/.claude/skills/.flywheel/lib/portable/core.sh:931 agentmail_orphan_session_rows_count="$(jq -r '.agentmail_orphan_session_rows_count // 0' <<<"$identity_registry")"
/Users/josh/.claude/skills/.flywheel/lib/portable/core.sh:1582 agentmail_orphan_session_rows_count:($identity_registry.agentmail_orphan_session_rows_count // 0)
/Users/josh/.claude/skills/.flywheel/lib/doctor.sh:251 emits code agentmail_orphan_session_rows_count when the copied value is >0
```

Fresh direct reproduction through the underlying identity surface:

```text
~/.claude/skills/.flywheel/bin/flywheel-loop identity --doctor --json \
  | jq '{status,total_registered,raw_drift_count,drift_count,agentmail_orphan_session_rows_count,orphan_token_count,orphan_tokens_unswept_count}'
```

Output:

```json
{
  "status": "fail",
  "total_registered": 20,
  "raw_drift_count": 16,
  "drift_count": 16,
  "agentmail_orphan_session_rows_count": 16,
  "orphan_token_count": 0,
  "orphan_tokens_unswept_count": 0
}
```

ALPS count: `16`.

## Flywheel-Side Probe Surface

Flywheel uses the same identity registry surface. Direct flywheel doctor
projection:

```text
FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 \
  ~/.claude/skills/.flywheel/bin/flywheel-loop doctor \
  --repo /Users/josh/Developer/flywheel \
  --json \
  | jq '{agentmail_orphan_session_rows_count,identity_token_orphan,orphan_tokens_unswept_count,identity_registry:{agentmail_orphan_session_rows_count:.identity_registry.agentmail_orphan_session_rows_count,orphan_token_count:.identity_registry.orphan_token_count}}'
```

Output:

```json
{
  "agentmail_orphan_session_rows_count": 16,
  "identity_token_orphan": 0,
  "orphan_tokens_unswept_count": 0,
  "identity_registry": {
    "agentmail_orphan_session_rows_count": 16,
    "orphan_token_count": 0
  }
}
```

The y8iky archive did stick for tokens: `orphan_token_count=0` and
`orphan_tokens_unswept_count=0`.

Flywheel validated-unreachable session count remains `0`, matching y8iky,
because all 16 flagged `(session,pane)` rows correspond to live NTM panes.

## Probe Diff

Raw identity field:

| surface | field | count |
|---|---|---:|
| ALPS doctor | `agentmail_orphan_session_rows_count` | 16 |
| Flywheel doctor | `agentmail_orphan_session_rows_count` | 16 |
| Identity doctor | `agentmail_orphan_session_rows_count` | 16 |

Validated/actionable state:

| surface | meaning | count |
|---|---|---:|
| y8iky receipt | confirmed unreachable session rows after live NTM validation | 0 |
| current token sweep state | orphan tokens still unswept | 0 |

The 16 rows are:

```text
alpsinsurance panes 1,2,3,4
flywheel panes 1,2,3,4
mobile-eats panes 1,2
skillos panes 1,2
vrtx panes 1,2,3,4
```

NTM health shows those sessions still have pane records. Example probe:

```text
for s in alpsinsurance flywheel mobile-eats skillos vrtx; do
  /Users/josh/.local/bin/ntm --json health "$s" | jq '{session:"'$s'", pane_count:((.agents // .panes // []) | length)}'
done
```

Observed pane counts:

```text
alpsinsurance 5
flywheel 5
mobile-eats 4
skillos 3
vrtx 5
```

## Root Cause

The identity doctor computes orphan session rows as:

```text
active registry row where (session,pane) is absent from latest topology
```

Current latest topology rows for the flagged sessions were written by
`migrate-topology-add-repo-path` and include `repo_path`, but no
`orchestrator_pane`, `worker_panes`, or `callback_pane` fields. Latest-wins
semantics therefore erase pane membership and make active identities look
orphaned.

Example:

```json
{
  "session": "alpsinsurance",
  "repo_path": "/Users/josh/Developer/alpsinsurance",
  "bead_id_prefix": "josh-",
  "effective_at": "2026-05-07T05:50:15Z",
  "registered_by": "migrate-topology-add-repo-path"
}
```

Every one of the 16 flagged session rows has `pane_present=false` under the
latest topology row because those latest rows are sparse repo-binding rows.

## Classification

Primary class: `surface_mismatch`.

Secondary structural class: topology scoping / latest-wins sparse-row issue.

Not cache: direct identity doctor and flywheel doctor both still produce the raw
16 count.

Not archive invisibility: y8iky did not archive those session rows. It retained
them and only archived the token orphan. The token archive is visible now.

## Recommendation

Recommendation: `fix_flywheel` and coordinate on shared source of truth.

The fix belongs in the shared flywheel identity/topology doctor substrate, not
ALPS repo code. ALPS is faithfully reporting the field it was given; the field
name and threshold are wrong for operator action because it conflates raw sparse
topology drift with confirmed unreachable identity rows.

Structural follow-up filed: `flywheel-msck5`.

Dependency: `flywheel-msck5` depends on `flywheel-ejw94`, because ejw94 is the
in-flight bead-isolation/scope-visibility structural fix family and this finding
is the same class of "shared state without one scoped truth source" failure.

Acceptance for the follow-up:

1. Identity doctor exposes separate raw topology drift and confirmed
   unreachable session counts.
2. Flywheel-loop doctor warnings use confirmed-unreachable rows, or label raw
   rows as unvalidated topology drift.
3. Topology latest-wins semantics preserve pane membership when sparse repo-path
   migration rows arrive.
4. ALPS and flywheel doctors agree on the same labeled source of truth.
5. Regression fixture covers sparse repo-path topology rows plus live NTM proof.
