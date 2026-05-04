# runtime_handoff Intentionality Check

Task: verify whether `/tmp/jeff-issue-runtime-handoff-singleton.md` should be
filed against `Dicklesworthstone/ntm` after applying the
`file-without-checking-intentional-API-drift` rule.

Timestamp: 2026-05-03T21:40:00Z

Remote checked: `Dicklesworthstone/ntm` via read-only `gh` API/search calls.

## Recommendation

`FILE_AS_DRAFTED`

The underlying issue is file-worthy: live upstream still has the singleton
`runtime_handoff` shape, no open PR or issue appears to cover scoped handoff
rows, and the current upstream tree has no `working_dir` column or
`idx_runtime_handoff_session_workdir` index on `runtime_handoff`.

Important draft hygiene before Joshua posts: remove or rephrase the local
history reference to `98ec9aa4`. GitHub returned `No commit found for SHA:
98ec9aa4`, so that commit is not visible in `Dicklesworthstone/ntm` and should
not be presented as upstream prior art. The draft can still cite the proposed
SQL packet and current upstream file:line evidence.

Decision fields:

- `jeff_partial_migration`: `false`
- `open_pr_found`: `false`
- Evidence pieces counted: `8`
- GitHub writes: `0`
- ntm source modifications: `0`

## Step 1: git log scan

Command run for migrations path:

```bash
gh api repos/Dicklesworthstone/ntm/commits --paginate -X GET \
  -F per_page=100 \
  -F path=internal/state/migrations \
  --jq '.[] | {sha:.sha[0:8], date:.commit.author.date, msg:(.commit.message | split("\n")[0])}' \
  | head -30
```

Output:

```text
d0727976 2026-03-23T05:56:43Z feat(runtime): durable attention item state, actuation tracing, and runtime GC guardrails
7580341d 2026-03-23T02:21:36Z feat(disclosure): propagate sanitized disclosure metadata through mail, state, and robot layers
77a0a121 2026-03-22T19:35:41Z feat: durable attention persistence, normalized projections, safety/scanner hardening, and web dashboard resilience
ec9451f3 2026-03-22T16:19:12Z feat(robot,serve,web): robot-redesign runtime layer, adapter stack, hardened server, and dashboard type safety
d01283b6 2026-01-27T19:56:19Z feat(state): add WebSocket events migration and agent detection tests
```

Command run for runtime store path:

```bash
gh api repos/Dicklesworthstone/ntm/commits --paginate -X GET \
  -F per_page=100 \
  -F path=internal/state/runtime_store.go \
  --jq '.[] | {sha:.sha[0:8], date:.commit.author.date, msg:(.commit.message | split("\n")[0])}' \
  | head -30
```

Output:

```text
07682f2b 2026-03-24T16:04:14Z fix(multi): rune-safe string ops, validate hardening, tmux alias cleanup
e0a4b995 2026-03-24T06:06:29Z fix(infra): ensemble state store cleanup, SQL table name validation, monitor lifecycle
08038bc4 2026-03-23T19:03:39Z feat(inspect,checkpoint,robot,state): add projection-backed inspect-session/inspect-agent, harden checkpoint session resolution, refactor GC helpers
9bb1b993 2026-03-23T07:30:46Z feat(attention,state,cli): incident-scoped replay, time-range queries, and session-aware project dir resolution
a00fb1af 2026-03-23T06:38:02Z feat(attention,reservations,mail): adaptive heartbeats, robust reservation tracking, and conditional mail events
d0727976 2026-03-23T05:56:43Z feat(runtime): durable attention item state, actuation tracing, and runtime GC guardrails
```

Interpretation:

- There are scope/session-aware commits in adjacent areas.
- There is no recent runtime_handoff-specific `working_dir` migration in current
  upstream history.
- The only runtime_handoff-origin commit visible here is `d0727976`, which added
  the singleton projection table.

## Step 2: full relevant commit message

Command run to find runtime_handoff/working_dir commits:

```bash
gh api repos/Dicklesworthstone/ntm/commits --paginate -X GET \
  -F per_page=100 \
  --jq '.[] | select(.commit.message | test("working_dir|runtime_handoff|runtime handoff"; "i")) | {sha:.sha[0:8], full_sha:.sha, date:.commit.author.date, msg:.commit.message}'
```

Relevant output:

```text
d0727976 2026-03-23T05:56:43Z feat(runtime): durable attention item state, actuation tracing, and runtime GC guardrails
97aa08ba 2026-01-06T18:14:59Z fix(checkpoint): add path traversal protection and ${WORKING_DIR} expansion for imports
bd24bcaa 2025-12-12T18:32:39Z feat(config): add NTM_CONFIG env var and JSON output for quick command
```

Command run for the full `d0727976` body:

```bash
gh api repos/Dicklesworthstone/ntm/commits/d072797654dc0fdb599bebfe35a335f1406713e2 --jq '.commit.message'
```

Relevant output:

```text
feat(runtime): durable attention item state, actuation tracing, and runtime GC guardrails

Add four new migrations (011-014) and expand the runtime store to support
a fully durable operator lifecycle for attention items ...

Runtime GC gains explicit grace-period / retention knobs (RuntimeGCConfig)
and a RuntimeGCResult struct. HandoffSummary now carries disclosure metadata,
active beads, agent-mail threads, blocker lists, and files, all backed by the
new runtime_handoff projection table (migration 011).
```

Patch evidence from the same commit:

```text
internal/state/migrations/011_runtime_handoff.sql:
CREATE TABLE IF NOT EXISTS runtime_handoff (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    session_name TEXT NOT NULL,
    ...
);

internal/state/runtime_schema.go:
type RuntimeHandoff struct {
    SessionName string `json:"session_name"`
    ...
}

internal/state/runtime_store.go:
INSERT INTO runtime_handoff (id, session_name, ...)
VALUES (1, ...)
ON CONFLICT(id) DO UPDATE ...
```

The draft mentions `98ec9aa4 state: scope runtime_handoff by working_dir`.
Verification command:

```bash
gh api repos/Dicklesworthstone/ntm/commits/98ec9aa4 --jq '.commit.message'
```

Output:

```text
No commit found for SHA: 98ec9aa4
```

Interpretation:

- Jeff's visible upstream rationale for `runtime_handoff` is "latest normalized
  handoff summary" backed by migration 011.
- There is no visible upstream commit adding `working_dir` to
  `runtime_handoff`.
- The local `98ec9aa4` evidence in the draft is not valid upstream evidence.

## Step 3: CHANGELOG / RELEASE_NOTES / README / code search

Command run:

```bash
for path in CHANGELOG.md RELEASE_NOTES.md README.md; do
  gh api repos/Dicklesworthstone/ntm/contents/$path 2>/dev/null \
    | jq -r .content | base64 -d \
    | grep -i -B2 -A2 "runtime_handoff\|runtime handoff\|working_dir\|BREAKING\|scoped" \
    | head -30
done
```

Output summary:

```text
CHANGELOG.md: no match
RELEASE_NOTES.md: missing or no match
README.md: one generic project-dir note:
  "Make sure the relevant session/project is using the intended project directory.
   Project-scoped state lives under that directory's .ntm/ tree."
```

Command run:

```bash
gh search code "runtime_handoff working_dir" --repo Dicklesworthstone/ntm --json path,textMatches --limit 20
```

Output:

```json
[]
```

Command run:

```bash
gh search code "runtime_handoff" --repo Dicklesworthstone/ntm --json path --limit 50
```

Output:

```text
internal/state/migrations/011_runtime_handoff.sql
docs/runtime-schema-design.md
internal/state/runtime_store.go
```

Command run:

```bash
gh search code "idx_runtime_handoff_session_workdir" --repo Dicklesworthstone/ntm --json path,textMatches --limit 20
```

Output:

```json
[]
```

Interpretation:

- No changelog/release-note/docs evidence says the singleton handoff table is a
  staged or intentionally unscoped migration.
- Current upstream code search has no `runtime_handoff working_dir` pairing and
  no `idx_runtime_handoff_session_workdir`.

## Step 4: idiomatic-migration / WIP check

Open PR command:

```bash
gh pr list --repo Dicklesworthstone/ntm --state open \
  --search "runtime_handoff working_dir runtime_store" \
  --limit 20 --json number,title,url,updatedAt,headRefName
```

Output:

```json
[]
```

Open issue / duplicate commands:

```bash
gh issue list --repo Dicklesworthstone/ntm --state all --search "runtime handoff" --limit 30 --json number,title,state,url,updatedAt
gh issue list --repo Dicklesworthstone/ntm --state all --search "working_dir" --limit 30 --json number,title,state,url,updatedAt
gh issue list --repo Dicklesworthstone/ntm --state open --search "runtime_handoff working_dir" --limit 20 --json number,title,url,updatedAt
```

Output:

```text
runtime handoff: []
runtime_handoff working_dir open issues: []
working_dir: issue #49 only, closed, about goal-labeled multi-session support via --label
```

Current source excerpt command:

```bash
for path in internal/state/runtime_store.go internal/state/runtime_schema.go internal/state/migrations/011_runtime_handoff.sql internal/robot/robot.go docs/runtime-schema-design.md; do
  gh api repos/Dicklesworthstone/ntm/contents/$path \
    | jq -r .content | base64 -d \
    | rg -n -C 3 "runtime_handoff|working_dir|id = 1|TODO|FIXME|RuntimeHandoff|WHERE id"
done
```

Relevant output:

```text
internal/state/migrations/011_runtime_handoff.sql:
6:CREATE TABLE IF NOT EXISTS runtime_handoff (
7:    id INTEGER PRIMARY KEY CHECK (id = 1),

internal/state/runtime_schema.go:
261:type RuntimeHandoff struct {
263-    SessionName string `json:"session_name"`
    ... no WorkingDir / ProjectPath field ...

internal/state/runtime_store.go:
965:// UpsertRuntimeHandoff inserts or updates the latest runtime handoff projection.
970: INSERT INTO runtime_handoff (
972-     id, session_name, ...
...
1015: FROM runtime_handoff
1016: WHERE id = 1 AND stale_after > datetime('now')
...
1037: DELETE FROM runtime_handoff WHERE id = 1
...
1045:// UpsertRuntimeHandoff inserts or updates the latest runtime handoff projection in an existing transaction.
1047: INSERT INTO runtime_handoff (
...
1082: DELETE FROM runtime_handoff WHERE id = 1

internal/robot/robot.go:
7054: handoffRow := buildRuntimeHandoffRow(...)
7182: tx.UpsertRuntimeHandoff(handoffRow)
7533: return &state.RuntimeHandoff{
7534:     SessionName: strings.TrimSpace(handoff.Session),
```

Interpretation:

- No open PR points to a staged migration.
- No current TODO/FIXME says the next commit will wire scoped handoff writes.
- Recent commits add `working_dir` in checkpoint/spawn/CLI contexts, not in
  `runtime_handoff`.
- Current Go paths still write/read/delete singleton handoff state.

## Decision Matrix Application

`DO_NOT_FILE` threshold: not met. We did not find an open PR, planned commit,
comment, release note, or current upstream partial migration indicating Jeff is
already intentionally staging this change.

`FILE_AS_DELTA` threshold: not met. Current upstream does not have the
`working_dir` column or index on `runtime_handoff`; therefore there is no visible
Jeff migration to acknowledge as "column added, Go write path missing."

`FILE_AS_DRAFTED` threshold: met. The defect remains visible in current upstream:
the table and store are singleton-shaped and there is no competing upstream
work item.

## Suggested Draft Hygiene

Before posting, revise the existing draft in two places:

1. Remove the claim that `98ec9aa4` is upstream prior art unless Joshua can
   prove it exists on a Jeff branch/ref. The public API returned no such commit.
2. Reword "live local DB has a later working_dir column" as local context only,
   not as current upstream state. Current GitHub code search does not show that
   column in `runtime_handoff`.

No `/tmp/jeff-issue-runtime-handoff-singleton.md` edits were made in this gate;
the dispatch requested a verification report only.
