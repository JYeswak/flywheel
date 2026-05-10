---
title: "Lane B: Ecosystem audit — runtime_handoff-class state isolation"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Lane B: Ecosystem audit — runtime_handoff-class state isolation

## Jeff-stack intent inventory

### ntm runtime_handoff: actual upstream WIP state

- Latest upstream main: `cc30c662` `2026-05-03T21:13:51Z`
  `fix(robot/source-health): conform SourceHealthEntry to documented contract (#117)`.
- Default branch: `main`.
- `gh repo view Dicklesworthstone/ntm --json defaultBranchRef,pushedAt`
  returned `pushedAt=2026-05-03T21:13:53Z`.
- Current GitHub source has singleton `runtime_handoff`.
- Current GitHub source does **not** have `runtime_handoff working_dir`.
- Current GitHub source does **not** have `idx_runtime_handoff_session_workdir`.
- Current GitHub API does **not** resolve local-history commit `98ec9aa4`.
- Open PRs touching `runtime_store.go` or `runtime_handoff`: none found.
- Open issues mentioning `runtime_handoff`: none found.
- Issues mentioning `working_dir`: only closed issue `#49`, unrelated label/multi-session support.

#### Migration history for runtime_handoff and runtime store

Commands run:

```bash
gh api repos/Dicklesworthstone/ntm/commits --paginate -X GET \
  -F per_page=100 -F path=internal/state/runtime_store.go \
  --jq '.[] | {sha:.sha[0:8], date:.commit.author.date, msg:(.commit.message | split("\n")[0])}' \
  | head -12

gh api repos/Dicklesworthstone/ntm/commits --paginate -X GET \
  -F per_page=100 -F path=internal/state/runtime_schema.go \
  --jq '.[] | {sha:.sha[0:8], date:.commit.author.date, msg:(.commit.message | split("\n")[0])}' \
  | head -12

gh api repos/Dicklesworthstone/ntm/commits --paginate -X GET \
  -F per_page=100 -F path=internal/state/migrations \
  --jq '.[] | {sha:.sha[0:8], date:.commit.author.date, msg:(.commit.message | split("\n")[0])}' \
  | head -30
```

Runtime-store commits returned by GitHub:

| SHA | Date | Message |
|---|---|---|
| `07682f2b` | 2026-03-24T16:04:14Z | `fix(multi): rune-safe string ops, validate hardening, tmux alias cleanup` |
| `e0a4b995` | 2026-03-24T06:06:29Z | `fix(infra): ensemble state store cleanup, SQL table name validation, monitor lifecycle` |
| `08038bc4` | 2026-03-23T19:03:39Z | `feat(inspect,checkpoint,robot,state): add projection-backed inspect-session/inspect-agent, harden checkpoint session resolution, refactor GC helpers` |
| `9bb1b993` | 2026-03-23T07:30:46Z | `feat(attention,state,cli): incident-scoped replay, time-range queries, and session-aware project dir resolution` |
| `a00fb1af` | 2026-03-23T06:38:02Z | `feat(attention,reservations,mail): adaptive heartbeats, robust reservation tracking, and conditional mail events` |
| `d0727976` | 2026-03-23T05:56:43Z | `feat(runtime): durable attention item state, actuation tracing, and runtime GC guardrails` |
| `7580341d` | 2026-03-23T02:21:36Z | `feat(disclosure): propagate sanitized disclosure metadata through mail, state, and robot layers` |
| `77a0a121` | 2026-03-22T19:35:41Z | `feat: durable attention persistence, normalized projections, safety/scanner hardening, and web dashboard resilience` |
| `ec9451f3` | 2026-03-22T16:19:12Z | `feat(robot,serve,web): robot-redesign runtime layer, adapter stack, hardened server, and dashboard type safety` |

Runtime-schema commits returned by GitHub:

| SHA | Date | Message |
|---|---|---|
| `a00fb1af` | 2026-03-23T06:38:02Z | `feat(attention,reservations,mail): adaptive heartbeats, robust reservation tracking, and conditional mail events` |
| `d0727976` | 2026-03-23T05:56:43Z | `feat(runtime): durable attention item state, actuation tracing, and runtime GC guardrails` |
| `7580341d` | 2026-03-23T02:21:36Z | `feat(disclosure): propagate sanitized disclosure metadata through mail, state, and robot layers` |
| `77a0a121` | 2026-03-22T19:35:41Z | `feat: durable attention persistence, normalized projections, safety/scanner hardening, and web dashboard resilience` |
| `ec9451f3` | 2026-03-22T16:19:12Z | `feat(robot,serve,web): robot-redesign runtime layer, adapter stack, hardened server, and dashboard type safety` |

Runtime migration commits returned by GitHub:

| SHA | Date | Message |
|---|---|---|
| `d0727976` | 2026-03-23T05:56:43Z | `feat(runtime): durable attention item state, actuation tracing, and runtime GC guardrails` |
| `7580341d` | 2026-03-23T02:21:36Z | `feat(disclosure): propagate sanitized disclosure metadata through mail, state, and robot layers` |
| `77a0a121` | 2026-03-22T19:35:41Z | `feat: durable attention persistence, normalized projections, safety/scanner hardening, and web dashboard resilience` |
| `ec9451f3` | 2026-03-22T16:19:12Z | `feat(robot,serve,web): robot-redesign runtime layer, adapter stack, hardened server, and dashboard type safety` |
| `d01283b6` | 2026-01-27T19:56:19Z | `feat(state): add WebSocket events migration and agent detection tests` |
| `c1c89c18` | 2026-01-24T23:32:23Z | `feat(ensemble): Major ensemble management and server improvements` |
| `2c362864` | 2026-01-20T18:27:20Z | `Fix redundant plugin loading in spawn.go, resolve imports, and remove backup file` |
| `91d28ca5` | 2026-01-05T23:14:20Z | `feat(metrics): add Success Metrics Tracking system (ntm-crjq)` |
| `0ff3b3fe` | 2026-01-04T03:25:34Z | `feat(foundations): implement State Store and Daemon Supervisor` |

Note: GitHub returned 9 commits for `runtime_store.go`, so this report captures
all path-specific runtime-store history available through the API, plus adjacent
schema and migration commits to provide more than ten runtime-layer context
points.

#### Commit that introduced runtime_handoff

Command:

```bash
gh api repos/Dicklesworthstone/ntm/commits/d072797654dc0fdb599bebfe35a335f1406713e2 --jq '.commit.message'
```

Relevant full-body excerpt:

```text
feat(runtime): durable attention item state, actuation tracing, and runtime GC guardrails

Runtime GC gains explicit grace-period / retention knobs (RuntimeGCConfig)
and a RuntimeGCResult struct. HandoffSummary now carries disclosure metadata,
active beads, agent-mail threads, blocker lists, and files, all backed by the
new runtime_handoff projection table (migration 011).
```

Patch evidence:

```text
internal/state/migrations/011_runtime_handoff.sql:
CREATE TABLE IF NOT EXISTS runtime_handoff (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    session_name TEXT NOT NULL,
    ...
);

internal/state/runtime_store.go:
INSERT INTO runtime_handoff (id, session_name, ...)
VALUES (1, ...)
ON CONFLICT(id) DO UPDATE ...
```

#### Open PRs touching runtime_store.go or runtime_handoff

Command:

```bash
gh pr list --repo Dicklesworthstone/ntm --state open \
  --search "runtime_handoff working_dir runtime_store" \
  --limit 20 --json number,title,url,updatedAt,headRefName
```

Output:

```json
[]
```

#### Open issues mentioning runtime_handoff or working_dir

Commands:

```bash
gh issue list --repo Dicklesworthstone/ntm --state all --search "runtime handoff" --limit 30 --json number,title,state,url,updatedAt
gh issue list --repo Dicklesworthstone/ntm --state all --search "working_dir" --limit 30 --json number,title,state,url,updatedAt
gh issue list --repo Dicklesworthstone/ntm --state open --search "runtime_handoff working_dir" --limit 20 --json number,title,url,updatedAt
```

Outputs:

```text
runtime handoff: []
runtime_handoff working_dir open issues: []
working_dir: #49 CLOSED "Feature Request: Goal-Labeled Multi-Session Support via `--label`"
```

#### Inferred Jeff intent

Inferred Jeff intent: `no signal`.

Current upstream evidence says Jeff intended `runtime_handoff` to be a "latest
normalized handoff summary" projection, but there is no visible staged migration
to `working_dir` or `project_path`. The local draft's `98ec9aa4` history is not
visible in `Dicklesworthstone/ntm` via GitHub API and should not be treated as
Jeff's current upstream intent.

## Sister tables in ntm with singleton shape

### Search result: singleton enforcement

Command:

```bash
gh search code "CHECK (id = 1)" --repo Dicklesworthstone/ntm --json path,textMatches --limit 50
gh search code "PRIMARY KEY CHECK" --repo Dicklesworthstone/ntm --json path,textMatches --limit 50
```

Result:

```text
docs/sqlite-runtime-tables.md
internal/state/migrations/011_runtime_handoff.sql
```

Interpretation: current source has only one live migration with
`CHECK (id = 1)`: `runtime_handoff`. The docs file has older design examples
for singleton `runtime_work` and `runtime_coordination`, but current migration
007 does not use singleton rows for those tables.

### Table checked: runtime_sessions

- Schema: `internal/state/migrations/007_runtime.sql:10-28`
- Key: `name TEXT PRIMARY KEY`
- Project context: `project_path TEXT`
- Writer: `internal/state/runtime_store.go:385-420`
- Upsert: `ON CONFLICT(name) DO UPDATE`
- Intent: scoped by session name, with project path stored as context.

Schema snippet:

```sql
CREATE TABLE IF NOT EXISTS runtime_sessions (
    name TEXT PRIMARY KEY,
    label TEXT,
    project_path TEXT,
    ...
);
```

Writer snippet:

```text
runtime_store.go:388 INSERT INTO runtime_sessions (
runtime_store.go:389     name, label, project_path, ...
runtime_store.go:394 ON CONFLICT(name) DO UPDATE SET
runtime_store.go:396     project_path = excluded.project_path
```

Verdict: intentionally scoped, not singleton.

### Table checked: runtime_agents

- Schema: `internal/state/migrations/007_runtime.sql:37-60`
- Key: `id TEXT PRIMARY KEY`
- Session context: `session_name TEXT NOT NULL`
- Writer: `internal/state/runtime_store.go:436-480` and transaction variant
  `565-607`
- Upsert: `ON CONFLICT(id) DO UPDATE`
- Intent: per-agent projection keyed by stable agent/pane id, with session
  context.

Schema snippet:

```sql
CREATE TABLE IF NOT EXISTS runtime_agents (
    id TEXT PRIMARY KEY,
    session_name TEXT NOT NULL,
    pane TEXT NOT NULL,
    ...
);
CREATE INDEX IF NOT EXISTS idx_runtime_agents_session ON runtime_agents(session_name);
```

Verdict: intentionally scoped, not singleton.

### Table checked: runtime_work

- Schema: `internal/state/migrations/007_runtime.sql:72-87`
- Key: `bead_id TEXT PRIMARY KEY`
- Writer: `internal/state/runtime_store.go:622-657` and transaction variant
  `741-760+`
- Upsert: `ON CONFLICT(bead_id) DO UPDATE`
- Intent: per-bead projection, not global singleton.

Schema snippet:

```sql
CREATE TABLE IF NOT EXISTS runtime_work (
    bead_id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    status TEXT NOT NULL,
    ...
);
```

Writer snippet:

```text
runtime_store.go:628 INSERT INTO runtime_work (
runtime_store.go:629     bead_id, title, ...
runtime_store.go:633 ON CONFLICT(bead_id) DO UPDATE SET
```

Verdict: intentionally scoped by bead id, not singleton. Older
`docs/sqlite-runtime-tables.md` described this as singleton, but migration 007
supersedes that design.

### Table checked: runtime_coordination

- Schema: `internal/state/migrations/007_runtime.sql:98-110`
- Key: `agent_name TEXT PRIMARY KEY`
- Session/pane context: `session_name`, `pane`
- Writer: `internal/state/runtime_store.go:800-825` and transaction variant
  `915-950`
- Upsert: `ON CONFLICT(agent_name) DO UPDATE`
- Intent: per-agent coordination projection.

Schema snippet:

```sql
CREATE TABLE IF NOT EXISTS runtime_coordination (
    agent_name TEXT PRIMARY KEY,
    session_name TEXT,
    pane TEXT,
    ...
);
```

Writer snippet:

```text
runtime_store.go:800 ON CONFLICT(agent_name) DO UPDATE SET
runtime_store.go:801     session_name = excluded.session_name
runtime_store.go:824 return nil
```

Verdict: intentionally scoped, not singleton. Older design docs had a singleton
row here too, but current source has moved away from that.

### Table checked: runtime_quota

- Schema: `internal/state/migrations/007_runtime.sql:120-132`
- Key: composite `PRIMARY KEY (provider, account)`
- Writer: `internal/state/runtime_store.go:1093-1122` and transaction variant
  `1207-1225+`
- Upsert: `ON CONFLICT(provider, account) DO UPDATE`
- Intent: composite-key projection by provider/account.

Schema snippet:

```sql
CREATE TABLE IF NOT EXISTS runtime_quota (
    provider TEXT NOT NULL,
    account TEXT NOT NULL,
    ...
    PRIMARY KEY (provider, account)
);
```

Writer snippet:

```text
runtime_store.go:1099 INSERT INTO runtime_quota (
runtime_store.go:1103 ON CONFLICT(provider, account) DO UPDATE SET
runtime_store.go:1135 WHERE provider = ? AND account = ?
```

Verdict: intentionally scoped by natural composite key.

### Table checked: source_health

- Schema: `internal/state/migrations/007_runtime.sql:142-156`
- Key: `source_name TEXT PRIMARY KEY`
- Indexes: available/healthy/last_check.
- Intent: per-source diagnostic projection/history.

Verdict: intentionally scoped by source, not singleton.

### Sister-table conclusion

The ecosystem pattern inside current `ntm` is not "runtime projections are
singletons." Current runtime tables are keyed by their natural owner:

- sessions by `name`
- agents by `id`
- work by `bead_id`
- coordination by `agent_name`
- quota by `(provider, account)`
- source health by `source_name`

`runtime_handoff` is the outlier. It still uses singleton `id = 1` while carrying
`session_name`, so it cannot represent more than one handoff at a time. The
outlier status strengthens the case for a scoped fix.

## beads_rust analogous patterns

### Search result: singleton-vs-scoped tension

Command:

```bash
gh search code "CHECK (id = 1) OR singleton" --repo Dicklesworthstone/beads_rust --json path,textMatches --limit 50
```

Output:

```json
[]
```

No beads_rust singleton-table pattern surfaced in code search.

### Multi-repo scoping pattern

Command:

```bash
gh search code "source_repo" --repo Dicklesworthstone/beads_rust --json path,textMatches --limit 50
```

Selected output:

```text
CHANGELOG.md:
- source_repo field for multi-repo support (30b668c)

src/storage/schema.rs:
source_repo TEXT NOT NULL DEFAULT '.'

src/cli/commands/create.rs:
canonical_source_repo(beads_dir: &Path) -> Option<String>

docs/porting/EXISTING_BEADS_STRUCTURE_AND_ARCHITECTURE.md:
source_repo_column - multi-repo support (classic)
repo_mtimes_table - multi-repo hydration cache
```

Memory cross-reference:
`~/.claude/projects/-Users-josh-Developer-flywheel/memory/reference_upstream_issues.md`
records:

- `beads_rust#269`: schema null-default bug fixed; `source_repo` covered by
  backfill/default repair.
- `beads_rust#270`: WAL wedging fixed via cooperative shutdown and checkpoint.
- `beads_rust#273`: `br create stores source_repo='.' for new issues`; filed
  2026-05-03 and listed in the 2026-05-03 batch.

Conclusion: beads_rust has analogous repo-scoping tension through
`source_repo`, but its primitive is not singleton table shape. The analogous
lesson is "scope by repo/project at write time, not by a global fallback," and
the current ntm runtime_handoff bug is the same class.

## ADOPT / EXTEND / AVOID per primitive

| Primitive | Source | ADOPT/EXTEND/AVOID | Rationale |
|-----------|--------|---------------------|-----------|
| `CHECK (id = 1)` schema on mutable runtime data | ntm `runtime_handoff` migration 011 | AVOID | Works only for true process-wide singleton; handoff is session/project-scoped runtime state. |
| Natural primary keys for projections | ntm `runtime_sessions(name)`, `runtime_work(bead_id)`, `runtime_coordination(agent_name)` | ADOPT | Current Jeff pattern uses owner identity as key for runtime projection tables. |
| Composite primary/unique key | ntm `runtime_quota(provider, account)` | ADOPT | Composite key matches multi-dimensional runtime state and maps directly to `ON CONFLICT`. |
| `ON CONFLICT(id)` upsert | ntm current `runtime_handoff` store | EXTEND -> `ON CONFLICT(session_name, working_dir)` | Keep idempotent upsert shape, replace singleton conflict target with scoped key. |
| `working_dir TEXT NOT NULL DEFAULT ''` compatibility field | `/tmp/runtime-handoff-migration-packet.sql`; local DB observation | EXTEND | Additive default preserves old rows and provides a legacy empty-scope fallback. |
| Backup-first SQL migration packet | `/tmp/runtime-handoff-migration-packet.sql`; safe-migrations skill | ADOPT | Correct for local DB surgery and for issue repro context; includes rollback sketch. |
| Public accessor / stable API over inner representation | frankensqlite#85 lesson | ADOPT | Prevents filing intentional migration noise; here the visible API has no documented scoped accessor, so filing remains valid. |
| `source_repo` repo-scoping field | beads_rust multi-repo support | ADOPT | Same isolation class: durable records need repo/project provenance at write time. |
| Docs-only singleton examples after implementation drift | ntm `docs/sqlite-runtime-tables.md` older `runtime_work`/`runtime_coordination` singleton examples | AVOID | Current migration supersedes docs; issue should cite live source, not stale design docs. |

## Cross-cutting findings

### File-handling concerns

- Handoff payload fields include `goal`, `now_text`, blockers, files, and
  disclosure metadata.
- These can carry sensitive project context even when not literal tokens.
- If runtime_handoff becomes project-scoped, the doctor/probe should verify both
  schema scope and payload hygiene: no raw token patterns in handoff text.
- L58-style token echo risk is relevant because handoff payloads are written to
  SQLite and may be surfaced by robot/status commands.

### Concurrency concerns

- SQLite single-writer semantics plus `ON CONFLICT` are fine if the conflict
  target is the intended scope.
- Current `ON CONFLICT(id)` collapses all writers into one row.
- Proposed `UNIQUE(session_name, working_dir)` makes concurrent writes to
  different project scopes independent.
- Concurrent writes to the same `(session_name, working_dir)` should last-write
  wins because this is a latest snapshot table, not history.
- If future code wants history, it should be a separate append-only table, not a
  mutation of runtime_handoff semantics.

### Backward-compat concerns

- Existing local rows may have only singleton `id=1` and no `working_dir`.
- An expand/migrate/switch shape is safest:
  1. add/create `working_dir TEXT NOT NULL DEFAULT ''`;
  2. backfill existing row into empty working_dir;
  3. switch Go writes/reads/deletes to the composite key;
  4. only then remove singleton constraint.
- The provided SQL packet combines schema rebuild steps for a local SQLite DB,
  which is acceptable for a backup-first local repair but should be split into
  careful migration phases if upstream wants zero-risk rollout.

### Operational concerns

- Use file backup before local SQLite migration.
- Validate with two rows for one session and two working dirs.
- Add a doctor probe so future singleton reintroduction is caught.
- Add a regression test that fails if `runtime_handoff` has `CHECK(id = 1)` or
  store code still uses `ON CONFLICT(id)` / `WHERE id = 1`.
- Monitor flywheel `leakage_count` with a subcomponent for runtime_handoff once
  the doctor check lands.

### Documentation drift concern

- `docs/sqlite-runtime-tables.md` still contains older singleton examples for
  `runtime_work` and `runtime_coordination`.
- Current migration 007 uses natural keys for those tables.
- Any Jeff issue should cite current source files and explicitly avoid treating
  old docs as the authority.

## Decision: file Jeff issue or local-only?

Apply the 4-step intentionality check from
`~/.claude/skills/jeff-issue-chain/references/INCIDENTS.md`.

### Step 1: git log evidence

Evidence captured above:

- Runtime-store path has 9 returned commits.
- Runtime migration path has runtime-layer commits back to foundation.
- Recent scope/session-aware commits exist in adjacent code:
  `9bb1b993`, `d92a0178`, `72756d95`, `9424ad9d`, etc.
- None add `working_dir` or `project_path` to `runtime_handoff`.
- No `runtime_handoff`-scoping commit appears in live upstream.

Intentionality signal: absent.

### Step 2: most recent relevant commit message

Most relevant live upstream commit is `d0727976`.

It says:

```text
HandoffSummary now carries disclosure metadata,
active beads, agent-mail threads, blocker lists, and files, all backed by the
new runtime_handoff projection table (migration 011).
```

It does not say:

- handoff is intentionally global;
- handoff is intentionally singleton across projects;
- follow-up commit will scope by working_dir;
- migration is staged.

Intentionality signal: absent for singleton scope. It only confirms the table is
a latest snapshot projection.

### Step 3: CHANGELOG/BREAKING grep

Command:

```bash
for path in CHANGELOG.md RELEASE_NOTES.md README.md; do
  gh api repos/Dicklesworthstone/ntm/contents/$path 2>/dev/null \
    | jq -r .content | base64 -d \
    | grep -i -B2 -A2 "runtime_handoff\|runtime handoff\|working_dir\|BREAKING\|scoped" \
    | head -30
done
```

Output:

```text
CHANGELOG.md: no match
RELEASE_NOTES.md: missing or no match
README.md: generic project-dir note only:
"Make sure the relevant session/project is using the intended project directory.
Project-scoped state lives under that directory's .ntm/ tree."
```

Intentionality signal: absent.

### Step 4: idiomatic-migration check

Checks run:

```bash
gh pr list --repo Dicklesworthstone/ntm --state open --search "runtime_handoff working_dir runtime_store" --limit 20 --json number,title,url,updatedAt,headRefName
gh search code "runtime_handoff working_dir" --repo Dicklesworthstone/ntm --json path,textMatches --limit 20
gh search code "idx_runtime_handoff_session_workdir" --repo Dicklesworthstone/ntm --json path,textMatches --limit 20
```

Outputs:

```text
open PRs: []
runtime_handoff working_dir code search: []
idx_runtime_handoff_session_workdir code search: []
```

Idiomatic migration exists conceptually:

- Add scope column.
- Preserve legacy empty default.
- Switch write/read/delete paths to composite key.
- Validate two scoped rows survive.

But that migration is not visible as Jeff WIP in current upstream.

Intentionality signal: absent.

### Recommendation

Recommendation: `FILE_AS_DRAFTED`.

Evidence:

- Current upstream still has singleton schema and singleton Go store paths.
- Sister runtime tables are scoped by natural keys.
- No PR, issue, commit, changelog, or code-search result suggests Jeff is
  intentionally staging this migration.
- The issue draft should be edited before filing to remove the `98ec9aa4` claim
  and frame current GitHub main as the source of truth.

## Skills citations

### ADOPT: dicklesworthstone-stack

Rationale: this lane is explicitly Jeff-stack work. The skill requires treating
Jeff's repos as a decision substrate, not a passive dependency list. I used the
canonical substrate inventory and live GitHub checks instead of relying on stale
local assumptions.

### ADOPT: jeff-issue-chain

Rationale: the new INCIDENTS rule is the central guardrail. The issue should not
be filed until the 4-step intentionality check is documented. This report
applies that rule and preserves the evidence.

### ADOPT: jeff-convergence-audit

Rationale: Lane B is a pre-dispatch quality gate. The convergence-audit pattern
maps here as "audit before bead DAG / implementation," with explicit skills
baseline and live-source verification.

### EVALUATE: safe-migrations

Rationale: the migration packet has the right backup-first instinct, but for a
clean upstream-quality plan we should preserve expand/migrate/switch/contract
separation where possible. SQLite table rebuilds are acceptable locally, but
the plan should include validation and rollback as first-class steps.

### EVALUATE: state-truth-recovery

Rationale: the `98ec9aa4` mismatch is a source-of-truth lesson. GitHub main is
the source for deciding whether to file; local clone history and local DB shape
are supporting evidence only.

### REFERENCE: beads-br

Rationale: beads_rust's analogous issue is not singleton tables; it is
repo-scoping via `source_repo`. The relevant primitive to borrow is durable
project provenance, not any specific br schema.

## Ladder assessment

- Gate 1: report exists and is over 120 lines: yes.
- Gate 2: ntm migration/runtime history captured: yes; all 9 path-specific
  runtime_store commits returned by GitHub plus adjacent schema/migration
  history are documented.
- Gate 3: sister-table audit: yes; checked 6 tables.
- Gate 4: ADOPT/EXTEND/AVOID matrix: yes; 9 primitives.
- Gate 5: 4-step intentionality check: yes; 4/4 documented.
- Gate 6: file/no-file recommendation: yes, `FILE_AS_DRAFTED`.
- Gate 7: skills section cites 3 ADOPT + 2 EVALUATE: yes.
- Gate 8: zero source modifications / zero GitHub writes: yes.

`ladder_passed=yes`
