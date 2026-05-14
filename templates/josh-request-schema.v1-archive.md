---
schema_version: 1
doc_type: josh-request-schema
canonical_at: ~/Developer/flywheel/templates/josh-request-schema.md
status: shipped
shipped_at: 2026-05-03
---

# {operator} Request Schema

## 1. Frontmatter Contract

Every canonical copy of this schema must preserve this frontmatter contract:

```yaml
schema_version: 1
doc_type: josh-request-schema
canonical_at: ~/Developer/flywheel/templates/josh-request-schema.md
status: shipped
shipped_at: 2026-05-03
```

Consumers must reject or warn on a missing `schema_version` or any value other
than `1`.

## 2. MISSION.md Section Header Contract

Each flywheel-managed repo that receives {operator} request capture must include
this exact section in repo-local `.flywheel/MISSION.md`:

```markdown
## {operator} Requests

<!-- AUTO-MAINTAINED by ~/.claude/hooks/josh-request-capture.sh + ~/.local/bin/josh-requests
     APPEND-ONLY for entries; status field is mutable.
     Schema canonical at ~/Developer/flywheel/templates/josh-request-schema.md -->
```

The section is append-only for entries. Tools may mutate only the status and
closure fields defined below.

## 3. Entry Shape

Each captured request is one Markdown subsection:

```markdown
### jr-<iso-ts>-<3digit>
- **status:** open|acknowledged|in_progress|done|deferred|wont_do
- **captured_via:** orch_turn|hook|backfill|agent_mail|ntm_send
- **session:** <repo-basename>
- **pane:** <int|null>
- **excerpt:** "<scrubbed {operator} message text, ≤500 chars>"
- **inferred_action:** <orch interpretation, set after capture>
- **bead:** flywheel-<id>|null
- **closed_at:** <iso>|null
- **closure_evidence:** <commit sha|bead-close-receipt path|joshua-confirmation excerpt>|null
```

Field rules:

- `status` starts as `open`.
- `captured_via` records the first substrate that captured the request.
- `session` is the repo/session basename, for example `flywheel` or `{proof-product}`.
- `pane` is an integer when known, otherwise literal `null`.
- `excerpt` must be scrubbed before persistence and truncated to 500 characters.
- `inferred_action` remains unset or `null` until an orchestrator acknowledges the request.
- `bead` is required before `in_progress` unless a commit or direct confirmation is the closure path.
- `closed_at` is ISO-8601 UTC or `null`.
- `closure_evidence` is required for terminal statuses as defined in Section 6.

## 4. Lifecycle State Machine

Allowed transitions:

- `open` -> `acknowledged`: orchestrator has read the request and set `inferred_action`.
- `acknowledged` -> `in_progress`: a bead is linked or a dispatch is underway.
- `in_progress` -> `done`: linked bead is closed and `closure_evidence` is populated.
- `any` -> `deferred`: orchestrator records a reason note; {operator} is not blocked.
- `any` -> `wont_do`: {operator}-confirmation excerpt is present as evidence.

Rules:

- `done`, `deferred`, and `wont_do` are terminal unless {operator} explicitly reopens the request.
- `wont_do` is never an autonomous orchestrator decision.
- A request may stay `acknowledged` when the correct action is plan-space work before bead creation.
- A request must not be silently deleted; supersession is represented by a new request and a deferred note.

## 5. Secret-Scrub Patterns

Capture hooks and backfill tools must scrub secrets before writing `excerpt` to
MISSION.md or JSONL. Replacement format is `[SCRUBBED:<class>]`, and the stored
excerpt should preserve enough surrounding text to prove scrub happened without
preserving the token.

Required patterns:

| Class | Pattern | Notes |
|---|---|---|
| `anthropic_key` | `sk-ant-[A-Za-z0-9]+` | Anthropic API keys. |
| `openai_key` | `sk-[A-Za-z0-9]{20,}` | OpenAI-style API keys. |
| `xai_key` | `xai-[A-Za-z0-9]+` | xAI API keys. |
| `github_pat` | `ghp_[A-Za-z0-9]+` | Classic GitHub PAT. |
| `github_fine_grained_pat` | `gh_pat_[A-Za-z0-9]+` | Fine-grained GitHub PAT. |
| `aws_access_key` | `AKIA[A-Z0-9]{16}` | AWS access key id. |
| `google_api_key` | `AIza[A-Za-z0-9_-]{35}` | Google API key. |
| `bearer_token` | `Bearer [A-Za-z0-9._-]+` | Generic bearer token. |
| `base64_blob` | `[A-Za-z0-9+/]{40,}={0,2}` | Base64-ish strings 40+ chars. |
| `near_secret_keyword` | `[A-Za-z0-9]{32,}` near literal `token`, `key`, `secret`, `password`, or `pat` | Heuristic; scrub only when nearby context names a secret. |

Examples:

- `sk-ant-abc123` -> `[SCRUBBED:anthropic_key]`
- `Bearer abc.def-ghi` -> `[SCRUBBED:bearer_token]`
- `password: 01234567890123456789012345678901` -> `[SCRUBBED:near_secret_keyword]`

The hook must record scrub evidence by leaving the replacement marker in the
excerpt. Tests must use synthetic tokens only.

## 6. Closure Evidence Requirements

Terminal statuses require evidence:

- `done`: at least one of:
  - linked bead status is `closed` and the bead has non-empty close-reason text;
  - commit sha references the request id or request excerpt;
  - {operator}-confirmation quote says the request is satisfied.
- `deferred`: orchestrator reason note is at least 20 characters and explains why {operator} is not blocked.
- `wont_do`: {operator}-confirmation excerpt must be present.

Invalid closures:

- `done` with `closure_evidence: null`.
- `done` with only "implemented" or another evidence-free phrase.
- `deferred` with no reason or a reason shorter than 20 characters.
- `wont_do` without a {operator} quote or explicit confirmation excerpt.

## 7. Cross-Session Propagation Note

This schema is canonical at:

```text
~/Developer/flywheel/templates/josh-request-schema.md
```

The doctrine-sync hook extended by `{bead-id}` propagates the schema to peer
repos. Each peer repo's `.flywheel/MISSION.md` receives the `## {operator} Requests`
section via `flywheel-iyex`. Propagation must not overwrite existing request
entries; it may add the header section when missing and update schema references.

## 8. ID Generation

Request ids use:

```text
jr-<iso-utc>-<3digit-counter>
```

Where:

- `<iso-utc>` is UTC ISO timestamp normalized for id use.
- `<3digit-counter>` is `epoch_seconds % 1000`, zero-padded to three digits.

Example:

```text
jr-2026-05-03T20-52-19Z-339
```

Collision risk is negligible below one capture per second. If a collision occurs,
the writer increments the counter modulo 1000 until the id is unused.

## 9. Cross-References

Plan and consumers:

- Plan: `.flywheel/PLANS/joshua-request-capture-system-2026-05-03/`
- MISSION canon: `.flywheel/MISSION.md` `## {operator} Requests`
- JSONL mirror: `~/.local/state/flywheel/josh-requests.jsonl`
- Hook: `~/.claude/hooks/josh-request-capture.sh` (`{bead-id}`)
- CLI: `~/.local/bin/josh-requests` (`flywheel-iaak`)
- Tick consumer: `~/Developer/flywheel/.flywheel/scripts/josh-request-tick-promote.sh` (`{bead-id}`)
- Doctrine-sync propagation: `{bead-id}`
- Peer MISSION bootstrap: `flywheel-iyex`
- Flywheel MISSION bootstrap: `{bead-id}`
- JSONL substrate initialization: `{bead-id}`
- Dispatch-template gate: `{bead-id}`
- Status dashboard surface: `{bead-id}`

Doctrine references:

- `doctor-signal-fail-without-bead-promotion` INCIDENTS entry.
- L58 `AGENT-MAIL-TOKENS-NEVER-IN-PANE-TEXT`.
- `feedback_orch_paralysis_recurring.md`.
- `feedback_data_guides_decisions_not_human_judgment.md`.
