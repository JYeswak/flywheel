---
schema_version: 2
previous_version: 1
revision_reason: "polish_review_2026_05_03"
doc_type: josh-request-schema
canonical_at: ~/Developer/flywheel/templates/josh-request-schema.md
status: shipped
shipped_at: 2026-05-03
---

# {operator} Request Schema

Schema v2 is the audit-grade contract for capturing, triaging, tracking, and
closing {operator}-originated requests across flywheel sessions. It replaces v1's
single free-text status/closure shape with stable provenance, lifecycle,
ownership, duplicate handling, and typed closure evidence.

The v1 document is archived at:

```text
~/Developer/flywheel/templates/josh-request-schema.v1-archive.md
```

## 1. Frontmatter Contract

Every canonical copy of this schema must preserve this frontmatter contract:

```yaml
schema_version: 2
previous_version: 1
revision_reason: "polish_review_2026_05_03"
doc_type: josh-request-schema
canonical_at: ~/Developer/flywheel/templates/josh-request-schema.md
status: shipped
shipped_at: 2026-05-03
```

Consumers must reject or warn on a missing `schema_version` or any value other
than `2`. Consumers that still read v1 must treat v1 as legacy input and migrate
before mutation.

## 2. MISSION.md Section Header Contract

Each flywheel-managed repo that receives {operator} request capture must include
this exact section in repo-local `.flywheel/MISSION.md`:

```markdown
## {operator} Requests

<!-- AUTO-MAINTAINED by ~/.claude/hooks/josh-request-capture.sh + ~/.local/bin/josh-requests
     APPEND-ONLY for entries; lifecycle fields are mutable by schema-aware tools.
     Schema canonical at ~/Developer/flywheel/templates/josh-request-schema.md -->
```

The section is append-only for request entries. Tools may mutate lifecycle,
ownership, duplicate, supersession, and closure fields defined below.

## 3. Entry Shape

Each captured request is one Markdown subsection and one matching JSONL row.
The Markdown form is human-readable; the JSONL row is the machine source for
automation.

```markdown
### jr-<iso-utc-without-colons>-<3digit-counter>
- **id:** jr-<timestamp>-001
- **captured_at:** <timestamp>
- **source_session:** flywheel
- **source_pane:** 1
- **transcript_path:** $HOME/.claude/projects/<project>/...jsonl|null
- **source_message_id:** <message-id|null>
- **prompt_hash:** sha256:<hex>|null
- **request_text_hash:** sha256:<hex>
- **sanitized_excerpt:** "<scrubbed {operator} message text, <=500 chars>"
- **inferred_action:** <orch interpretation|null>
- **state:** needs_triage|acknowledged|in_progress|blocked|waiting_on_external|done|deferred|wont_do
- **owner:** RubyCreek
- **priority:** P0|P1|P2|P3
- **scope:** single-repo|cross-session|fleet-wide
- **last_updated_at:** <timestamp>
- **closure_actor:** <agent-or-human|null>
- **linked_bead_ids:** [{bead-id}, {bead-id}]
- **duplicate_of:** <jr-id|null>
- **supersedes:** <jr-id|null>
- **stale_after:** 24
- **closure_evidence:** {type: bead_closed|commit|dispatch_log|transcript|joshua_confirmed, ref: <ref>}|null
```

## 4. Field Contract

| Field | Type | Required | Rules |
|---|---|---:|---|
| `id` | string | yes | `jr-<iso-utc-without-colons>-<3digit-counter>`. Immutable. |
| `captured_at` | ISO UTC string | yes | Time the request was first captured. Immutable. |
| `source_session` | string | yes | Repo/session basename, e.g. `flywheel`, `{proof-product}`, `{capability-control-plane}`. |
| `source_pane` | int or null | yes | Pane number when known; `null` if unavailable. |
| `transcript_path` | string or null | yes | Claude project JSONL transcript path when available; `null` for substrates without transcript access. |
| `source_message_id` | string or null | conditional | Required when the source substrate provides a stable message id. Mutually allowed with `prompt_hash`; at least one must be non-null. |
| `prompt_hash` | string or null | conditional | `sha256:` hash of raw normalized prompt, used for dedup when no message id exists. At least one of `source_message_id` or `prompt_hash` must be non-null. |
| `request_text_hash` | string | yes | `sha256:` hash of the scrubbed excerpt text for duplicate detection after secret removal. |
| `sanitized_excerpt` | string | yes | Scrubbed text, maximum 500 characters. Never store raw secrets. |
| `inferred_action` | string or null | yes | Orchestrator interpretation. `null` while `state=needs_triage`; set before `acknowledged`. |
| `state` | enum | yes | One of the eight lifecycle states in Section 5. Initial value is `needs_triage`. |
| `owner` | string | yes | Orchestrator identity that owns triage and closure, e.g. `RubyCreek`. |
| `priority` | enum | yes | `P0`, `P1`, `P2`, or `P3`, derived from inferred urgency. |
| `scope` | enum | yes | `single-repo`, `cross-session`, or `fleet-wide`. |
| `last_updated_at` | ISO UTC string | yes | Mutates on every state or evidence change. |
| `closure_actor` | string or null | yes | Who marked a terminal state. Required for `done`, `deferred`, and `wont_do`. |
| `linked_bead_ids` | array[string] | yes | Zero or more bead ids. Multiple beads may serve one request. Required non-empty before `in_progress` unless the request is closed by direct transcript/{operator} evidence. |
| `duplicate_of` | string or null | yes | `jr-id` of canonical request if this row is a duplicate. |
| `supersedes` | string or null | yes | `jr-id` of prior request replaced by this request. |
| `stale_after` | number | yes | Hours before resurfacing. Default `24`; may be adjusted by scope. |
| `closure_evidence` | object or null | yes | Typed evidence object. Required for `done` and `wont_do`; see Section 6. |

Minimum v2 field count: 21 top-level fields plus the two nested
`closure_evidence` fields.

## 5. Lifecycle State Machine

Allowed states:

| State | Meaning |
|---|---|
| `needs_triage` | Captured but not yet interpreted by the owning orchestrator. |
| `acknowledged` | Owner has read the request and populated `inferred_action`. |
| `in_progress` | Work has started; linked beads or dispatch evidence exists. |
| `blocked` | Work is blocked on an internal recoverable issue and has a note. |
| `waiting_on_external` | Work waits on {operator}, Jeff, vendor, client, or another external actor and has a note. |
| `done` | Request is closed with typed evidence. |
| `deferred` | Request is explicitly delayed with a note of at least 20 characters and will resurface after `stale_after`. |
| `wont_do` | {operator} explicitly confirmed that the request should not be done. |

Allowed transitions:

```text
needs_triage -> acknowledged
  orch reads + sets inferred_action + owner

acknowledged -> in_progress
  linked_bead_ids populated, dispatch sent, or direct work started with evidence

in_progress -> blocked
  requires note >=20 chars explaining internal blocker

in_progress -> waiting_on_external
  requires note >=20 chars naming external dependency

blocked -> in_progress
  blocker resolved; append/update note and last_updated_at

waiting_on_external -> in_progress
  external dependency resolved; append/update note and last_updated_at

in_progress -> done
  requires typed closure_evidence

any -> deferred
  requires note >=20 chars; auto-resurface after stale_after

any -> wont_do
  requires closure_evidence.type=joshua_confirmed
```

Rules:

- `done`, `deferred`, and `wont_do` are terminal unless {operator} explicitly reopens
  or supersedes the request.
- `needs_triage` is the only valid initial captured state.
- `wont_do` is never an autonomous orchestrator decision.
- Requests are never silently deleted. Use `duplicate_of`, `supersedes`,
  `deferred`, or `wont_do`.
- `last_updated_at` mutates on every transition.
- `closure_actor` is required for terminal states.

## 6. Typed Closure Evidence

`closure_evidence` is an object, never free text:

```yaml
closure_evidence:
  type: bead_closed | commit | dispatch_log | transcript | joshua_confirmed
  ref: <bead_id|commit_sha|task_id|transcript_path#message_id|quote_hash>
```

Allowed evidence types:

| `type` | `ref` shape | Valid for | Notes |
|---|---|---|---|
| `bead_closed` | `flywheel-<id>` | `done` | Referenced bead must be closed with non-empty close reason. |
| `commit` | git commit sha | `done` | Commit must reference request id or linked bead. |
| `dispatch_log` | task id or dispatch-log line ref | `done` | Dispatch callback must prove completion. |
| `transcript` | `<transcript_path>#<message_id>` | `done`, `deferred` | Use when transcript contains the closure proof. |
| `joshua_confirmed` | `sha256:<quote_hash>` | `done`, `deferred`, `wont_do` | Required for `wont_do`; quote text may stay in transcript, not schema row. |

Invalid closures:

- `done` with `closure_evidence: null`.
- `done` with only "implemented" or another evidence-free phrase.
- `wont_do` without `closure_evidence.type=joshua_confirmed`.
- `deferred` with no note or a note shorter than 20 characters.

## 7. Secret-Scrub Contract

Capture hooks and backfill tools must scrub secrets before writing
`sanitized_excerpt` to MISSION.md or JSONL. Replacement format is
`[SCRUBBED:<class>]`, and the stored excerpt should preserve enough surrounding
text to prove scrub happened without preserving the token.

The canonical scrub list is owned by the hook implementation bead
`{bead-id}`; this schema names the classes and requires consumers to follow
that spec. The current required classes are:

| Class | Examples / pattern family |
|---|---|
| `aws_access_key` | `AKIA...`, `ASIA...` |
| `github_token` | `ghp_`, `gho_`, `ghu_`, `ghs_`, `ghr_`, `github_pat_` |
| `anthropic_key` | `sk-ant-...` |
| `openai_key` | `sk-...`, `sk-proj-...` |
| `jwt` | `eyJ...`.`...`.`...` |
| `bearer_token` | `Authorization: Bearer ...`, `Bearer ...` |
| `google_api_key` | `AIza...` |
| `slack_token` | `xoxb-`, `xoxa-`, `xoxp-`, `xoxr-`, `xoxs-` |
| `private_key_block` | `-----BEGIN ... PRIVATE KEY-----` |
| `agent_mail_token_field` | `registration_token=...`, `sender_token=...` |
| `contextual_base64_secret` | Long base64/base64url near `token`, `secret`, `key`, `password`, or `authorization` |
| `contextual_hex_secret` | Long hex near `token`, `secret`, `key`, `password`, or `authorization` |

Tests must use synthetic tokens only. The hook implements exact regexes and
negative tests so non-secret {operator} requests remain usable.

## 8. ID Generation

Request ids use:

```text
jr-<iso-utc-without-colons>-<3digit-counter>
```

Example:

```text
jr-<timestamp>-001
```

Where:

- `<iso-utc-without-colons>` is UTC ISO timestamp with colon characters removed.
- `<3digit-counter>` starts at `001` for the timestamp bucket and increments
  until the id is unused.

If a collision occurs, the writer increments the counter modulo 1000 until the
id is unused.

## 9. JSONL Mirror Rules

The JSONL mirror at `~/.local/state/flywheel/josh-requests.jsonl` is pure JSONL:
one JSON object per line, no comments or header rows. Schema commentary belongs
in this document or a sidecar, never in the data file.

Each JSONL row must contain the same top-level fields named in Section 4. Field
order is not semantically meaningful, but writers should emit deterministic
order for audit diffs.

## 10. Cross-References

Plan and review:

- Plan: `.flywheel/plans/joshua-request-capture-system-2026-05-03/`
- Polish review: `.flywheel/plans/joshua-request-capture-system-2026-05-03/05-POLISH-r1.md`
- Finding: `05-POLISH-r1.md` Finding 1, Schema completeness

Downstream consumers:

- Hook: `~/.claude/hooks/josh-request-capture.sh` (`{bead-id}`)
- CLI: `~/.local/bin/josh-requests` (`flywheel-iaak`)
- JSONL mirror: `~/.local/state/flywheel/josh-requests.jsonl` (`{bead-id}`)
- Tick consumer: `~/Developer/flywheel/.flywheel/scripts/josh-request-tick-promote.sh` (`{bead-id}`)
- MISSION canon: `.flywheel/MISSION.md` `## {operator} Requests`
- Doctrine-sync propagation: `{bead-id}`
- Peer MISSION bootstrap: `flywheel-iyex`
- Flywheel MISSION bootstrap: `{bead-id}`
- Dispatch-template gate: `{bead-id}`
- Status dashboard surface: `{bead-id}`

Doctrine references:

- L58 `AGENT-MAIL-TOKENS-NEVER-IN-PANE-TEXT`.
- `doctor-signal-fail-without-bead-promotion` INCIDENTS entry.
- `feedback_orch_paralysis_recurring.md`.
- `feedback_data_guides_decisions_not_human_judgment.md`.

## 11. v1 to v2 Mapping

Current live mirror status: **v1-compatible JSONL is canonical for the live
doctor/tick path until the writer migration lands**. Consumers must normalize
both live v1 rows and target v2 rows instead of treating all `status: open`
rows as unread. The tick consumer `josh-request-tick-promote.sh` now reports
`queued_count`, `unread`, and `consumed_with_evidence_count`; evidence-backed
rows stay in the append-only mirror but do not inflate the unread gauge.

| v1 field | v2 field |
|---|---|
| `status: open` | `state: needs_triage` |
| `session` | `source_session` |
| `pane` | `source_pane` |
| `excerpt` | `sanitized_excerpt` |
| `bead` | `linked_bead_ids[]` |
| `closed_at` | terminal transition timestamp in `last_updated_at` |
| free-text `closure_evidence` | typed `closure_evidence.type/ref` |

Consumers must not down-migrate v2 rows to v1 because v1 loses provenance and
typed closure data. Until every writer emits v2, consumers must treat this table
as the live normalization contract.
